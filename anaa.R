ANAA_BASE <- "http://www.anaaweb.org/"

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

message("Accediendo a ANAA (Departamento de ", choice, "...)")
ids_anaa <- fetch_helper_anaa(choice) %>% unique()
if (choice == 'perros') {
  ids_yayos <- fetch_helper_anaa(pet = 'y-ayos') %>% unique()
}
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
  mutate(name = map_chr(content, get_field, ".ficha li"),
         age = map_chr(content, get_field, ".ficha li+li"),
         sex = map_chr(content, get_field, ".ficha li+li+li+li")) %>%
  select(name, age, sex, url, id) %>%
  mutate(born = as.Date(gsub("Edad: ", "", age), '%d-%m-%Y'),
         sex = gsub("Sexo: ", "", sex),
         article = ifelse(sex == "hembra", "La", "El"),
         age = round(as.numeric(difftime(Sys.Date(), born, units = "weeks"))/52.25, digits=1)) %>%
  filter(complete.cases(.))