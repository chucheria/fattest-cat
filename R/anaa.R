ANAA_BASE <- "http://www.anaaweb.org/"

## ANAA GET PARTIALS
fetch_helper_anaa <- function(pet) {
  modifier <- paste0(pet, "-en-adopcion")
  url <- modify_url(ANAA_BASE, path = modifier)
  ids <- url %>%
    read_html() %>%
    html_nodes(xpath='//*[@name="id"]') %>%
    html_attr('value')
  
  return(ids)
}

##### GET INFO PET
## WITH RELATIVE LINKS
calls_helper <- function(ids, shelter) {
  info <- tibble(
    id = ids,
    url = map_chr(id, ~ modify_url(ANAA_BASE, 
                                   path = c(paste0("detalle-de-adopcion-de-",
                                                   substr(choice, 1, nchar(choice)-1)),
                                            paste0("?id=", .x))))
  )
  return(info)
}

anaa <- function(choice) {
  message("Accediendo a ANAA (Departamento de ", choice, "...)")
  ids_anaa <- fetch_helper_anaa(choice) %>% unique()
  
  calls_anaa <- calls_helper(ids_anaa, 'ANAA')
  message("Leyendo información sobre ", choice, ".\n  ",
          nrow(calls_anaa), " ", choice, " únicos encontrados.\n ",
          "Calculando su edad...")
  
  fetch_calls_anaa <- calls_anaa %>%
    mutate(resp = map(url, GET),
           status = map_chr(resp, status_code)) %>%
    filter(status == "200") %>%
    mutate(content = map(resp, content))
  
  get_field <- compose(str_trim, html_text, html_node)
  pet_anaa <- fetch_calls_anaa %>%
    select(url, content, id) %>%
    mutate(name = map_chr(content, get_field, "div#entrada > h1"),
           born = map_chr(content, get_field, ".ficha li+li"),
           sex = map_chr(content, get_field, ".ficha li+li+li+li")) %>%
    select(name, born, sex, url, id) %>%
    mutate(born = as.Date(sub("F. nac.: ", "", born), '%d-%m-%Y'),
           sex = sub("Sexo: ", "", sex),
           article = ifelse(sex == "Hembra", "La", "El"),
           age = round(as.numeric(difftime(Sys.Date(), born, 
                                           units = "weeks"))/52.25, digits=1)) %>%
    filter(complete.cases(.))
  
  return(pet_anaa)
}