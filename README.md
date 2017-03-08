
<!-- README.md is generated from README.Rmd. Please edit that file -->
> Los perretes y gatetes se hacen mayores en las protectoras, ¡ayúdemoslos!

Un script en [\#rstats](https://twitter.com/hashtag/rstats), en honor al [script de Jenny Bryan](https://github.com/jennybc/fattest-cat) para encontrar los gatos más gordos en el [centro de adopción SF SPCA](https://www.sfspca.org/adoptions/cats)

Instalar y uso del script
-------------------------

Shell

    wget https://raw.githubusercontent.com/chucheria/fattest-cat/master/oldest-pet.R
    chmod +x fattest-cat.R
    ./fattest-cat.R

R

``` r
url <- "https://raw.githubusercontent.com/chucheria/fattest-cat/master/oldest-pet.R"
rfile <- basename(url)
download.file(url, rfile)
source(rfile)
```

Elige entre **1** o **2** para buscar *gatos* o *perros*.
