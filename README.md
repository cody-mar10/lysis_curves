Plotting Lysis Curves in R
================
Cody Martin
6/18/2021

# Installation

You can install R here: <https://cran.r-project.org/mirrors.html>

-   Just choose the location closest to you

You can install R studio, a fantastic interactive coding environment for
R, here: <https://www.rstudio.com/products/rstudio/download/>

Then you can open the `README.Rmd` file from the GitHub repository, and
use the code below.

# More R help

Need more R help? Checkout my Intro to R document:
<https://github.com/cody-mar10/intro_R/blob/main/README.md>

# Load packages

First load your packages. Normally, you would need to install any
packages you don’t have loaded, but I am forcing the code to install
packages for you if they are not already.

``` r
pkgs <- c("tidyverse", "ggprism", "ggrepel") # note tidyverse includes ggplot2 and dplyr
# Check if packages are installed
for (p in pkgs) {
  if(! p %in% installed.packages()){
    install.packages(p, dependencies = TRUE)
  }
}

# Load packages
invisible(lapply(pkgs, library, character.only=T))

# Note normally you can just do:
# library(tidyverse) for example
```

# Read in data

Here, I read in my wide-formatted lysis curve data. Although I have
simple names, you should keep your names useful for coding. Here is an
example:

-   pRE gp60-63 = BAD!!! Don’t ever use spaces
-   pRE\_gp60-63 = GOOD Use \_ instead of spaces

Be consistent in your sample naming. Furthermore, you first column
**must** be the time column.

``` r
file <- "data/simpledata.csv"
data <- read_csv(file)

# change first column name to "Time"
colnames(data)[1] <- "Time"

data
```

<div class="kable-table">

| Time | MG1655 |    N4 |     A |     B |     C |     D |     E |
|-----:|-------:|------:|------:|------:|------:|------:|------:|
|    0 |  0.223 | 0.239 | 0.237 | 0.231 | 0.228 | 0.235 | 0.231 |
|   30 |  0.523 | 0.488 | 0.489 | 0.505 | 0.510 | 0.506 | 0.504 |
|   35 |  0.620 | 0.558 | 0.441 | 0.505 | 0.550 | 0.503 | 0.510 |
|   40 |  0.685 | 0.612 | 0.212 | 0.354 | 0.517 | 0.332 | 0.379 |
|   45 |  0.772 | 0.683 | 0.110 | 0.222 | 0.428 | 0.176 | 0.244 |
|   50 |  0.844 | 0.718 | 0.089 | 0.137 | 0.371 | 0.118 | 0.174 |
|   55 |  0.888 | 0.789 | 0.067 | 0.111 | 0.354 | 0.098 | 0.136 |
|   60 |  0.968 | 0.815 | 0.068 | 0.105 | 0.346 | 0.095 | 0.126 |
|   70 |  1.390 | 0.859 | 0.051 | 0.091 | 0.331 | 0.108 | 0.111 |
|   80 |  1.544 | 0.962 | 0.053 | 0.068 | 0.151 | 0.086 | 0.074 |
|   93 |  2.010 | 1.224 | 0.048 | 0.070 | 0.125 | 0.064 | 0.084 |

</div>

# Wide to Long formatting

To proceed, we need to take your wide-formatted data and convert it to
long-formatted data. This way each row will be a **singular**
observation. This is how computational software likes to work with data
since the software can use efficient vectorized operations.

If you only have one variable to test in your lysis curve like different
genetic backgrounds, you will only need separately colored lines to plot
for the visual difference. This will be a “simple” plot, and we can
re-format your data easily.

However, if you have multiple varibles in your lysis curve like genetic
background and +/- some chemical like DNP, nalidixic acid,
chloramphenicol, etc. then **READ CAREFULLY!!!**

You should name your sample columns with ODs with all variable levels
separated by \_ **UNDERSCORES ONLY!!!**

Example: suppose I have genotype A and B, and +/- DNP, I would name my
columns like this:

`A_- B_- A_+ B_+`

DO NOT, and I repeat DO NOT!!! use \_ anywhere else. This is because the
long formatting code will separate the column name into separate columns
at the \_ delimiter, so the above columns would separate into columns
like this:

<div class="kable-table">

| Genotype | DNP |
|:---------|:----|
| A        | \-  |
| B        | \-  |
| A        | \+  |
| B        | \+  |

</div>

I’ve included an example of both simple and multivariable data sets: -
`data/simpledata.csv` - `data/complexdata.csv`

## Convert data to long format

The `gather` function from `dplyr` will convert data from wide to long,
turning all numeric data into a single stacked column.

``` r
wideToLong <- function(data, variables=c()) {
  # check if any columns have the _ delimiter specifying multiple varibles
  var_check <- grepl("_", colnames(data))
  
  # if any columns have the _ delimiter
  if (TRUE %in% var_check && length(variables) != 0) { 
    data_long <- data %>% 
      gather(key="Sample", value = "OD", -Time) %>% 
      separate(Sample, sep="_", remove=F, into=variables)
  } else {
    data_long <- data %>% 
      gather(key="Sample", value = "OD", -Time)
  }
  
  return(data_long)
}

data_long <- wideToLong(data=data)
data_long %>% head(10)
```

<div class="kable-table">

| Time | Sample |    OD |
|-----:|:-------|------:|
|    0 | MG1655 | 0.223 |
|   30 | MG1655 | 0.523 |
|   35 | MG1655 | 0.620 |
|   40 | MG1655 | 0.685 |
|   45 | MG1655 | 0.772 |
|   50 | MG1655 | 0.844 |
|   55 | MG1655 | 0.888 |
|   60 | MG1655 | 0.968 |
|   70 | MG1655 | 1.390 |
|   80 | MG1655 | 1.544 |

</div>

# Plotting

I’ve made extensive use of the `ggplot2`, `ggprism`, and `ggrepel`
packages to make the best plots you will ever set your gaze on. This
code is *mostly* fullproof. If you only have simple plots, it should be
fine.

## Simple plots

Here is how I plot my graphs using my customizations:

``` r
# define custom offset to move line labels away from axis
offset <- max(data_long$Time)*0.05

# ggprism has default colors to use, but I want to reorder them
cols = ggprism_data$colour_palettes$colors[c(6,1:5,7:20)]

# make ggplot object
simpleplot <- function(data_long) {
  # set minor ticks based on max OD
  # y-axis needs to look different if OD values rise above 1 due to log scale
  if (max(data_long$OD, na.rm = T) > 1) {
    max_yax = 10
    y_minor = c(rep(1:9, 3)*(10^rep(-2:0, each=9)), 10) # minor ticks
  } else {
    max_yax = 1
    y_minor = c(rep(1:9, 2)*(10^rep(c(-2, -1), each=9)), 1) # minor ticks
  }
  
  # makeplot
  g <- data_long %>% 
      ggplot(aes(x=Time, y=OD)) +
      geom_line(aes(color=Sample), size=1.25) +
      geom_point(aes(shape=Sample), color="black", size=5) +
      geom_text_repel(data=subset(data_long, Time == max(data_long$Time)), # labels next to lines
                      aes(label=Sample, 
                          color=Sample, 
                          x=Inf, # put label off plot
                          y=OD), # put label at same height as last data point
                      direction="y",
                      xlim=c(max(data_long$Time)+offset, Inf), # offset labels
                      min.segment.length=Inf, # won't draw lines
                      hjust=0, # left justify
                      size=5,
                      fontface="bold") +
      scale_shape_prism(palette = "complete") + # change prism bullet shape palette
      scale_color_manual(values=cols) +
      scale_y_log10(limit=c(0.01,max_yax), # put y on log10 scale
                         minor_breaks=y_minor,
                         guide=guide_prism_minor(),
                         expand=c(0,0)) + 
      scale_x_continuous(minor_breaks=seq(0,max(data_long$Time),by=10),
                         guide=guide_prism_minor(),
                         expand=c(0,0)) + 
      labs(x="Time (min)",
           y="A550") +
      theme_prism(border=T) + # theme like prism plot
      coord_cartesian(clip="off") +
      theme(aspect.ratio=1/1, 
            legend.position = "none",
            plot.margin=unit(c(1,5,1,1), "lines"))
  return(g)
}

simpleplot(data_long)
```

![](README_files/figure-gfm/simple%20plot-1.png)<!-- -->

## Complex plots

Let’s suppose you did a lysis curve testing more than just one variable
like in `data/complexdata.csv`. Let’s first take a look at the data:

### Complex input

``` r
file <- "data/complexdata.csv"
data <- read_csv(file)
colnames(data)[1] <- "Time"

data
```

<div class="kable-table">

| Time | pRE\_-N4\_None | gp60-63\_-N4\_None | pRE\_+N4\_t=20 | gp60-63\_+N4\_t=20 | pRE\_+N4\_t=25 | gp60-63\_+N4\_t=25 | pRE\_+N4\_t=30 | gp60-63\_+N4\_t=30 |
|-----:|---------------:|-------------------:|---------------:|-------------------:|---------------:|-------------------:|---------------:|-------------------:|
|    0 |          0.200 |              0.201 |          0.219 |              0.208 |          0.217 |              0.204 |          0.219 |              0.204 |
|   15 |          0.337 |              0.307 |          0.331 |              0.295 |          0.335 |              0.314 |          0.335 |              0.312 |
|   20 |          0.366 |              0.326 |          0.363 |              0.377 |          0.365 |              0.357 |          0.374 |              0.363 |
|   25 |          0.391 |              0.374 |          0.420 |              0.378 |          0.415 |              0.406 |          0.403 |              0.396 |
|   30 |          0.440 |              0.421 |          0.467 |              0.414 |          0.465 |              0.393 |          0.449 |              0.444 |
|   35 |          0.501 |              0.395 |          0.538 |              0.374 |          0.519 |              0.338 |          0.511 |              0.268 |
|   40 |          0.552 |              0.334 |          0.572 |              0.247 |          0.588 |              0.191 |          0.571 |              0.193 |
|   45 |          0.607 |              0.105 |          0.616 |              0.159 |          0.624 |              0.094 |          0.614 |              0.063 |
|   50 |          0.662 |              0.056 |          0.692 |              0.125 |          0.683 |              0.072 |          0.690 |              0.056 |
|   55 |          0.725 |              0.050 |          0.730 |              0.128 |          0.766 |              0.070 |          0.779 |              0.049 |
|   60 |          0.816 |              0.061 |          0.813 |              0.126 |          0.860 |              0.075 |          0.792 |              0.059 |

</div>

### Wide to Long

If you take a look at the function that converts the data from wide to
long, you will notice you can input variable names. This tells the code
to split your sample columns into n columns for each variable you have
using the `separate` function from `dplyr`.

``` r
wideToLong <- function(data, variables=c()) {
  # check if any columns have the _ delimiter specifying multiple varibles
  var_check <- grepl("_", colnames(data))
  
  # if any columns have the _ delimiter
  if (TRUE %in% var_check && length(variables) != 0) { 
    data_long <- data %>% 
      gather(key="Sample", value = "OD", -Time) %>% 
      separate(Sample, sep="_", remove=F, into=variables)
  } else {
    data_long <- data %>% 
      gather(key="Sample", value = "OD", -Time)
  }
  
  return(data_long)
}
```

In this dataset, the variables are genotype, N4 addition, and Time of
addition, so I code the variable names as `Genotype`, `N4_add`, and
`Time_add`.

``` r
# define your variables
var <- c("Genotype", "N4_add", "Time_add")
data_long <- wideToLong(data, var)
data_long %>% head(10)
```

<div class="kable-table">

| Time | Sample         | Genotype | N4\_add | Time\_add |    OD |
|-----:|:---------------|:---------|:--------|:----------|------:|
|    0 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.200 |
|   15 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.337 |
|   20 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.366 |
|   25 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.391 |
|   30 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.440 |
|   35 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.501 |
|   40 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.552 |
|   45 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.607 |
|   50 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.662 |
|   55 | pRE\_-N4\_None | pRE      | -N4     | None      | 0.725 |

</div>

See how there are extra columns in our long-formatted data frame based
on the variables we input! We can use these extra columns to better
distinguish all our curves in the lysis curve.

### Complex Plotting

Currently, you are limited to only 3 different variables. Since there
are only 9 possible spots in the shaker bath, I don’t think it is
possible to have more than 3 different total conditions. You can modify
the code below if you somehow have 4 or more different experimental
conditions tested.

``` r
# ggprism has default colors to use, but I want to reorder them
cols = ggprism_data$colour_palettes$colors[c(6,1:5,7:20)]

complexplot <- function(data_long, variables) {
  if (max(data_long$OD, na.rm = T) > 1) {
    max_yax = 10
    y_minor = c(rep(1:9, 3)*(10^rep(-2:0, each=9)), 10) # minor ticks
  } else {
    max_yax = 1
    y_minor = c(rep(1:9, 2)*(10^rep(c(-2, -1), each=9)), 1) # minor ticks
  }
  
  variables = rep(variables, 2)
  g <- data_long %>% 
    ggplot(aes_string(x="Time", y="OD", 
                      color=variables[1], linetype=variables[2],
                      shape=variables[3]
                      )) +
    geom_line(size=1.25) +
    geom_point(color="black", fill="black", size=5) +
    scale_shape_prism(palette = "complete") + # change prism bullet shape palette
    scale_color_manual(values=cols) +
    scale_y_log10(limit=c(0.01,max_yax), # put y on log10 scale
                  minor_breaks=y_minor,
                  guide=guide_prism_minor(),
                  expand=c(0,0)) + 
    scale_x_continuous(breaks=seq(0,max(data_long$Time),by=10),
                       guide=guide_prism_minor(),
                       expand=c(0,0)) + 
    labs(x="Time (min)",
         y="A550",
         color=variables[1], 
         linetype=variables[2],
         shape=variables[3]
         ) +
    theme_prism(border=T) + # theme like prism plot
    coord_cartesian(clip="off") +
    theme(aspect.ratio=1/1, 
          legend.title = element_text(),
          plot.margin=unit(c(1,5,1,1), "lines"))
  return(g)
}

complexplot(data_long, var)
```

![](README_files/figure-gfm/complex%20plot-1.png)<!-- -->

# Saving output

To save your plots as png images, you can just use this simple code:

``` r
save = paste0(strsplit(basename(file), ".csv")[[1]], ".png")
png(save, width=7.5, height=7.5, units="in", res=200)
## MAKE PLOT IN HERE
## IE do this
simpleplot(data_long)
dev.off()
```

# Final example

This dataset has two different experimental variables: strain and
addition of N4. Everything works exactly as described, but just to show
the generality of my `complexplot` code:

``` r
file <- "data/complexdata2.csv"
data <- read_csv(file)
colnames(data)[1] <- "Time"
data
```

<div class="kable-table">

| Time | pRE\_-N4 | gp60-63\_-N4 | gp63-T65I\_-N4 | gp63-T71A\_-N4 | pRE\_+N4 | gp60-63\_+N4 | gp63-T65I\_+N4 | gp63-T71A\_+N4 |
|-----:|---------:|-------------:|---------------:|---------------:|---------:|-------------:|---------------:|---------------:|
|    0 |    0.208 |        0.176 |          0.179 |          0.167 |    0.190 |        0.167 |          0.176 |          0.168 |
|   15 |    0.300 |        0.267 |          0.260 |          0.251 |    0.299 |        0.262 |          0.268 |          0.250 |
|   20 |    0.326 |        0.302 |          0.279 |          0.265 |    0.326 |        0.296 |          0.272 |          0.291 |
|   25 |    0.380 |        0.321 |          0.224 |          0.305 |    0.383 |        0.337 |          0.178 |          0.318 |
|   30 |    0.441 |        0.382 |          0.102 |          0.263 |    0.475 |        0.380 |          0.080 |          0.268 |
|   35 |    0.485 |        0.390 |          0.038 |          0.181 |    0.505 |        0.368 |          0.040 |          0.195 |
|   40 |    0.550 |        0.273 |          0.030 |          0.066 |    0.566 |        0.308 |          0.044 |          0.089 |
|   45 |    0.571 |        0.111 |          0.032 |          0.036 |    0.574 |        0.233 |          0.032 |          0.052 |
|   50 |    0.671 |        0.078 |          0.031 |          0.033 |    0.637 |        0.212 |          0.031 |          0.039 |
|   55 |    0.702 |        0.081 |          0.027 |          0.036 |    0.711 |        0.216 |          0.035 |          0.036 |
|   60 |    0.745 |        0.076 |          0.037 |          0.037 |    0.777 |        0.223 |          0.040 |          0.037 |

</div>

``` r
var <- c("Strain", "N4_addition")
data_long <- wideToLong(data, var)
data_long %>% head(10)
```

<div class="kable-table">

| Time | Sample   | Strain | N4\_addition |    OD |
|-----:|:---------|:-------|:-------------|------:|
|    0 | pRE\_-N4 | pRE    | -N4          | 0.208 |
|   15 | pRE\_-N4 | pRE    | -N4          | 0.300 |
|   20 | pRE\_-N4 | pRE    | -N4          | 0.326 |
|   25 | pRE\_-N4 | pRE    | -N4          | 0.380 |
|   30 | pRE\_-N4 | pRE    | -N4          | 0.441 |
|   35 | pRE\_-N4 | pRE    | -N4          | 0.485 |
|   40 | pRE\_-N4 | pRE    | -N4          | 0.550 |
|   45 | pRE\_-N4 | pRE    | -N4          | 0.571 |
|   50 | pRE\_-N4 | pRE    | -N4          | 0.671 |
|   55 | pRE\_-N4 | pRE    | -N4          | 0.702 |

</div>

``` r
complexplot(data_long, var)
```

![](README_files/figure-gfm/complex%20example%202-1.png)<!-- -->
