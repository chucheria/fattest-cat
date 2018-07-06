#!/usr/bin/env Rscript
suppressMessages(library(tidyverse))
suppressMessages(library(rvest))
library(stringr)
library(httr)

## URL Base
ANAA_BASE <- "http://www.anaaweb.org/"
MADRILENA_BASE <- 'http://adopcioneslamadrilena.org/'


## Console helper
choice <- readline(prompt="Elige entre: \n 1 = El gato más mayor \n 2 = El perro más mayor \n");
choice <- ifelse(choice == 1, 'gatos', 'perros')

##### SCRAPING

## ANAA GET PARTIALS
fetch_helper_anaa <- function(pet, page = 0) {
  message("Leyendo la página de ANAA de " , pet)
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

##### GET INFO PET
## WITH RELATIVE LINKS
calls_helper <- function(ids, shelter) {
  info <- tibble(
    id = ids,
    url = map_chr(id,
                  ~ modify_url(ANAA_BASE,
                               path = c("adopciones", paste0("adopciones-de-", choice), .x)))
  )
  if (choice == 'perros') {
    info_yayos <-
      tibble(
        id = ids_yayos,
        url = map_chr(id,
                      ~ modify_url(ANAA_BASE,
                                   path = c("disfruta-de-un-y-ayo-en-casa",
                                            paste0("adopciones-de-", choice), .x)))
      )
    info <- bind_rows(info, info_yayos)
  }
  return(info)
}

## WITH COMPLETE LINKS
calls_helper_madrilena <- function(page = 1) {
  message("Leyendo la página de LA MADRILEÑA de " , pet)
  page_query <- if (page < 1) NULL else list(page = page)
  modifier <- paste0("listado.php?p=", page)
  url <- modify_url(MADRILENA_BASE, path = modifier,
                    query = page_query)
  calls_madrilena <- url %>%
    read_html() %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    str_subset("ficha")
  
  if (length(calls_madrilena) < 1) {
    return(calls_madrilena)
  } else {
    ## recursive case
    c(calls_madrilena, calls_helper_madrilena(page + 1))
  }
}

#####
message("Accediendo a ANAA (Departamento de ", choice, "...)")
ids_anaa <- fetch_helper_anaa(choice) %>% unique()
if (choice == 'perros') {
  ids_yayos <- fetch_helper_anaa(pet = 'y-ayos') %>% unique()
}
calls_anaa <- calls_helper(ids_anaa, 'ANAA')
message("Leyendo información sobre ", choice, ".\n  ",
        nrow(calls_anaa), " ", choice, " únicos encontrados.\n ",
        "Calculando su edad...")

message("Accediendo a LA MADRILEÑA (Departamento de ", choice, "...)")
calls_madrilena <- calls_helper_madrilena() %>% unlist() %>% unique()
ids_fields <- sapply(strsplit(as.character(calls_madrilena), "-"), tail, 1)
calls_madrilena <- tibble (
  id = ids_fields,
  url = calls_madrilena
)
message("Leyendo información sobre ", choice, ".\n  ",
        nrow(calls_madrilena), " animales únicos encontrados.\n ",
        "Calculando su edad...")


fetch_calls_anaa <- calls_anaa %>%
    mutate(resp = map(url, GET),
           status = map_chr(resp, status_code)) %>%
    filter(status == "200") %>%
    mutate(content = map(resp, content))

get_field <- compose(str_trim, html_text, html_node)
pet_anaa <- fetch_calls_anaa %>%
  select(url, content, id) %>%
  mutate(name = map_chr(content, get_field, ".ficha li"),
         age = map_chr(content, get_field, ".ficha li+li"),
         sex = map_chr(content, get_field, ".ficha li+li+li+li")) %>%
  select(name, age, sex, url, id) %>%
  mutate(born = as.Date(gsub("Edad: ", "", age), '%d-%m-%Y'),
         sex = gsub("Sexo: ", "", sex),
         article = ifelse(sex == "hembra", "La", "El"),
         age = round(as.numeric(difftime(Sys.Date(), born, units = "weeks"))/52.25, digits=1)) %>%
  filter(complete.cases(.))


fetch_calls_madrilena <- calls_madrilena %>%
  mutate(content = map(url, read_html))

get_field <- compose(str_trim, html_text, html_node)
pet_madrilena <- fetch_calls_madrilena %>%
  select(url, content, id) %>%
  mutate(name = map_chr(content, get_field, ".ficha_caracteristicas > .ficha_nombre > span"),
         type = map_chr(content, get_field, ".ficha_caracteristicas > .ficha_tipo > span"),
         age = map_chr(content, get_field, ".ficha_caracteristicas > .ficha_edad > span"),
         sex = map_chr(content, get_field, ".ficha_caracteristicas > .ficha_sexo > span"),
         born =  map_chr(content, get_field, ".ficha_caracteristicas > .ficha_nacimiento > span")) %>%
  filter(str_detect(choice, str_to_lower(type))) %>%
  select(name, age, sex, url, id, born) %>%
  mutate(article = ifelse(sex == "Hembra", "La", "El"),
         born = as.Date(paste0('01/',born), '%d/%m/%Y'),
         age = round(as.numeric(difftime(Sys.Date(), born, units = "weeks"))/52.25, digits=1)) %>%
  filter(complete.cases(.))

pet <- bind_rows(pet_madrilena, pet_anaa)

tbl <-
  capture.output(
    pet %>%
      select(name, age, sex) %>%
      as.data.frame() %>%
      print()
  ) %>%
  str_c(collapse = "\n")
message(tbl)

oldest <- max(pet$age)
message(
  str_interp("${article} más mayor es ${name}. Tiene ${age} años.",
             pet[pet$age == oldest, ])
)
Sys.sleep(0.5)
message("Abriendo su perfil...")
Sys.sleep(0.5)
browseURL(pet$url[pet$age == oldest])
