
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)

[![minimal R version](https://img.shields.io/badge/R%3E%3D-3.3.1-6666ff.svg)](https://cran.r-project.org/) [![packageversion](https://img.shields.io/badge/Package%20version-0.2.0-orange.svg?style=flat-square)](commits/master) [![Last-changedate](https://img.shields.io/badge/last%20change-2017--06--01-yellowgreen.svg)](/commits/master)

<!-- README.md is generated from README.Rmd. Please edit that file -->
Introducción
============

> Los perretes y gatetes se hacen mayores en las protectoras, ¡ayúdemoslos!

Encuentra el gato o perro más mayor en adopción de la [protectora ANAA](http://www.anaaweb.org/) o en la [protectora ALBA](http://www.albaonline.org/).

Un script en [\#rstats](https://twitter.com/hashtag/rstats), en honor al [script de Jenny Bryan](https://github.com/jennybc/fattest-cat) para encontrar los gatos más gordos en el [centro de adopción SF SPCA](https://www.sfspca.org/adoptions/cats)

Instalar y uso del script
-------------------------

Shell

    wget https://raw.githubusercontent.com/chucheria/oldest-pet/master/oldest-pet.R
    chmod +x oldest-pet.R
    ./oldest-pet.R

R

``` r
url <- "https://raw.githubusercontent.com/chucheria/oldest-pet/master/oldest-pet.R"
rfile <- basename(url)
download.file(url, rfile)
source(rfile)
```

Elige entre **1** o **2** para buscar *gatos* o *perros*.
