#!/usr/bin/env Rscript
suppressMessages(library(tidyverse))
suppressMessages(library(rvest))
library(stringr)
library(httr)

ANAA_BASE <- "http://www.anaaweb.org/"

choice <- readline(prompt="Elige entre: \n 1 = El gato más mayor \n 2 = El perro más mayor \n");
choice <- if (choice == 1) 'gatos' else 'perros'

fetch_helper <- function(choice, page = 0) {
  message("Leyendo la página de " , choice)
  page_query <- if (page < 1) NULL else list(page = page)
  modifier <- paste0("adopciones-de-", choice)
  url <- modify_url(ANAA_BASE, path = c("adopciones", modifier),
                    query = page_query)
  ids <- url %>%
    read_html() %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    str_subset(paste0("/", modifier, "/"))
  ids <- sapply(strsplit(as.character(ids), "/"), tail, 1)
}

message("Accediendo a ANAA (Departamento de ", choice, "...)")
ids <- fetch_helper(choice) %>% unique()
message("Leyendo información sobre ", choice, ".\n  ",
        length(ids), " ", choice, " únicos encontrados.\n ",
        "Calculando su edad...")

calls <-
  tibble(
    id = ids,
    url = map_chr(id,
                  ~ modify_url(ANAA_BASE,
                               path = c("adopciones", paste0("adopciones-de-", choice), .x))),
    resp = map(url, GET),
    status = map_chr(resp, status_code)
  ) %>%
  filter(status == "200") %>%
  mutate(content = map(resp, content))

get_field <- compose(str_trim, html_text, html_node)
pet <- calls %>%
  select(url, content, id) %>%
  mutate(name = map_chr(content, get_field, ".ficha li"),
         age = map_chr(content, get_field, ".ficha li+li"),
         sex = map_chr(content, get_field, ".ficha li+li+li+li")) %>%
  select(name, age, sex, url, id) %>%
  mutate(born = as.Date(gsub("Edad: ", "", age), '%d-%m-%Y'),
         sex = gsub("Sexo: ", "", sex),
         pronoun = ifelse(sex == "hembra", "Ella", "Él"),
         age = round(as.numeric(difftime(Sys.Date(), born, units = "weeks"))/52.25, digits=1))

tbl <-
  capture.output(
    pet %>%
      select(name, age, sex, id) %>%
      as.data.frame() %>%
      print()
  ) %>%
  str_c(collapse = "\n")
message(tbl)

oldest <- min(pet$born)
message(
  str_interp("El más mayor es ${name}. ${pronoun} tiene ${age} años.",
             pet[pet$born == oldest, ])
)
Sys.sleep(0.5)
message("Abriendo su perfil...")
Sys.sleep(0.5)
browseURL(pet$url[pet$born == oldest])
