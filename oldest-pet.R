#!/usr/bin/env Rscript
suppressMessages(library(tidyverse))
suppressMessages(library(rvest))
library(stringr)
library(httr)

ANAA_BASE <- "http://www.anaaweb.org/"

choice <- readline(prompt="Elige entre: \n 1 = El gato más mayor \n 2 = El perro más mayor \n");
choice <- ifelse(choice == 1, 'gatos', 'perros')

fetch_helper <- function(pet, page = 0) {
  message("Leyendo la página de " , pet)
  page_query <- if (page < 1) NULL else list(page = page)
  modifier <- paste0("adopciones-de-", pet)
  url <- modify_url(ANAA_BASE, path = c("adopciones", modifier),
                    query = page_query)
  ids <- url %>%
    read_html() %>%
    html_nodes("a") %>%
    html_attr("href")
  if (pet == 'y-ayos') {
    ids <- ids %>%
      str_subset("/disfruta-de-un-y-ayo-en-casa/adopciones-de-perros/")
  } else {
    ids <- ids %>%
      str_subset(paste0("/", modifier, "/"))
  }
  ids <- sapply(strsplit(as.character(ids), "/"), tail, 1)
}

message("Accediendo a ANAA (Departamento de ", choice, "...)")
ids <- fetch_helper(choice) %>% unique()
if (choice == 'perros') {
  ids_yayos <- fetch_helper(pet = 'y-ayos') %>% unique()
}
message("Leyendo información sobre ", choice, ".\n  ",
        length(ids), " ", choice, " únicos encontrados.\n ",
        "Calculando su edad...")

calls <-
  tibble(
    id = ids,
    url = map_chr(id,
                  ~ modify_url(ANAA_BASE,
                               path = c("adopciones", paste0("adopciones-de-", choice), .x)))
  )

if (choice == 'perros') {
  calls_yayos <-
    tibble(
      id = ids_yayos,
      url = map_chr(id,
                    ~ modify_url(ANAA_BASE,
                                 path = c("disfruta-de-un-y-ayo-en-casa", paste0("adopciones-de-", choice), .x)))
    )

  calls <- bind_rows(calls, calls_yayos) %>%
    mutate(resp = map(url, GET),
           status = map_chr(resp, status_code)) %>%
    filter(status == "200") %>%
    mutate(content = map(resp, content))
} else {
  calls <- calls %>%
    mutate(resp = map(url, GET),
           status = map_chr(resp, status_code)) %>%
    filter(status == "200") %>%
    mutate(content = map(resp, content))
}

get_field <- compose(str_trim, html_text, html_node)
pet <- calls %>%
  select(url, content, id) %>%
  mutate(name = map_chr(content, get_field, ".ficha li"),
         age = map_chr(content, get_field, ".ficha li+li"),
         sex = map_chr(content, get_field, ".ficha li+li+li+li")) %>%
  select(name, age, sex, url, id) %>%
  mutate(born = as.Date(gsub("Edad: ", "", age), '%d-%m-%Y'),
         sex = gsub("Sexo: ", "", sex),
         article = ifelse(sex == "hembra", "La", "El"),
         age = round(as.numeric(difftime(Sys.Date(), born, units = "weeks"))/52.25, digits=1))

tbl <-
  capture.output(
    pet %>%
      select(name, age, sex) %>%
      as.data.frame() %>%
      print()
  ) %>%
  str_c(collapse = "\n")
message(tbl)

oldest <- min(pet$born)
message(
  str_interp("${article} más mayor es ${name}. Tiene ${age} años.",
             pet[pet$born == oldest, ])
)
Sys.sleep(0.5)
message("Abriendo su perfil...")
Sys.sleep(0.5)
browseURL(pet$url[pet$born == oldest])
