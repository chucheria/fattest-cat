MADRILENA_BASE <- 'http://adopcioneslamadrilena.org/'

## WITH COMPLETE LINKS
calls_helper_madrilena <- function(page = 1) {
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