#!/usr/bin/env Rscript
suppressMessages(library(tidyverse))
suppressMessages(library(rvest))
library(stringr)
library(httr)


## Console helper
choice <- readline(prompt="Elige entre: \n 1 = El gato más mayor \n 2 = El perro más mayor \n");
choice <- ifelse(choice == 1, 'gatos', 'perros')

## Call all shelters
devtools::source_url('https://raw.githubusercontent.com/chucheria/oldest-pet/master/R/anaa.R')
devtools::source_url('https://raw.githubusercontent.com/chucheria/oldest-pet/master/R/madrilena.R')
devtools::source_url('https://raw.githubusercontent.com/chucheria/oldest-pet/master/R/zarpas.R')
#source('R/anaa.R')
#source('R/madrilena.R')
#source('R/zarpas.R')


pet <- bind_rows(madrilena(choice), anaa(choice), zarpas(choice))

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
