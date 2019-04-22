ZARPAS_BASE <- "https://www.zarpasycolmillos.es/"

## ANAA GET PARTIALS
fetch_helper_zarpas <- function(pet) {
  modifier <- paste0(pet, "-en-adopcion")
  url <- modify_url(ZARPAS_BASE, path = modifier)
  ids <- url %>%
    read_html() %>%
    html_nodes('.entry-title > a') %>%
    html_attr('href')
  
  return(ids)
}

filter_info <- function(xml, item_text) {
  items <- xml %>% html_nodes('.project_features_item') %>% html_text()
  item <- items[grepl(item_text, items)]
  item <- sub(item_text, '', item)
  return(item[1])
}


zarpas <- function(choice) {
  message("Accediendo a ZARPAS Y COLMILLOS (Departamento de ", choice, "...)")
  calls_zarpas <- fetch_helper_zarpas(choice) %>% unlist() %>% unique()
  
  ids_zarpas <-  sapply(strsplit(as.character(calls_zarpas), "/"), tail, 1)
  calls_zarpas <- tibble (
    id = ids_zarpas,
    url = calls_zarpas
  )
  message("Leyendo información sobre ", choice, ".\n  ",
          nrow(calls_zarpas), " ", choice, " únicos encontrados.\n ",
          "Calculando su edad...")
  
  fetch_calls_zarpas <- calls_zarpas %>%
    mutate(resp = map(url, GET),
           status = map_chr(resp, status_code)) %>%
    filter(status == "200") %>%
    mutate(content = map(resp, content))
  
  pet_zarpas <- fetch_calls_zarpas %>%
    select(url, content, id) %>%
    mutate(name = map_chr(content, filter_info, 'Nombre'),
           born = map_chr(content, filter_info, "Fecha de entrada"),
           sex = map_chr(content, filter_info, "Sexo")) %>%
    select(name, born, sex, url, id) %>%
    mutate(born = as.Date(born, '%d/%m/%Y'),
           article = ifelse(sex == "Hembra", "La", "El"),
           age = round(as.numeric(difftime(Sys.Date(), born, 
                                           units = "weeks"))/52.25, digits=1)) %>%
    filter(complete.cases(.))
  
  return(pet_zarpas)
}







