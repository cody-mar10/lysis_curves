#!/usr/bin/env Rscript --vanilla
# Author: Cody Martin
# Email: ccmartin6@wisc.edu
# Current Institution: University of Wisconsin-Madison
#                      Department of Bacteriology
# Created while affiliated with:
#   Texas A&M University
#   Dr. Ry Young lab
#   Department of Biochemistry & Biophysics
#   Center for Phage Technology
# 
# Date: June 18, 2021

pkgs <- c("tidyverse", "ggprism", "ggrepel") # note tidyverse includes ggplot2 and dplyr
# Check if packages are installed
for (p in pkgs) {
  if(! p %in% installed.packages()){
    install.packages(p, dependencies = TRUE)
  }
}

# Load packages
invisible(lapply(pkgs, library, character.only=T))

# Read in WIDE FORMATED data from command line argument
file <- "data/simpledata.csv"
#args <- commandArgs(trailingOnly=T)
#file <- args[1]
data <- read_csv(file)

# or complex data
file <- "data/complexdata.csv"
data <- read_csv(file)

# Reformat data into long format
# Rename first column with time to be Time
# first column MUSTTTTT BE TIME
colnames(data)[1] <- "Time"

# if you only have one variable to test in your lysis curve
# like different genetic backgrounds, you will only need one separately
# colored lines to plot -> this will be a "simple" plot so we can
# re-format your data easily

# however, if you have multiple varibles in your lysis curve like
# genetic background and +/- chemical like DNP, nalidixic acid,
# chloramphenicol, etc READ CAREFULLY!!!
# you should name your sample columns with ODs with all variable levels
# separated by _ UNDERSCORES ONLY!!!
# example: suppose I have genotype A and B, and +/- DNP,
# I would name my columns like this:

# A_Minus B_minus A_Plus B_Plus

# DO NOT, and I repeat DO NOT!!! use _ anywhere else
# his is because the long formatting code will separate
# the column name into separate columns at the _ delimiter
# so the above columns would separate into columns like this:
# Sample DNP
# A      Minus
# B      Minus
# A      Plus
# B      Plus

wideToLong <- function(data, variables=c()) {
  # check if any columns have the _ delimiter specifying multiple varibles
  var_check <- grepl("_", colnames(data))
  
  if (TRUE %in% var_check && length(variables) != 0) { # if any columns have the _ delimiter
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

#complex version
var <- c("Genotype", "N4_add", "Time_add")
data_long <- wideToLong(data, var)

# define custom offset to move line labels away from axis
offset <- max(data_long$Time)*0.035

# set minor ticks based on max OD
# y-axis needs to look different if OD values rise above 1 due to log scale

# ggprism has default colors to use, but I want to reorder them
cols = ggprism_data$colour_palettes$colors[c(6,1:5,7:20)]

# make ggplot object
simpleplot <- function(data_long) {
  if (max(data_long$OD, na.rm = T) > 1) {
    max_yax = 10
    y_minor = c(rep(1:9, 3)*(10^rep(-2:0, each=9)), 10) # minor ticks
  } else {
    max_yax = 1
    y_minor = c(rep(1:9, 2)*(10^rep(c(-2, -1), each=9)), 1) # minor ticks
  }
  
  g <- data_long %>% 
      ggplot(aes(x=Time, y=OD)) +
      geom_line(aes(color=Sample), size=1.25) +
      geom_point(aes(shape=Sample), fill="black", size=2.5) +
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

# save plot as .png
save = paste0(strsplit(basename(file), ".csv")[[1]], ".png")
png(save, width=7.5, height=7.5, units="in", res=200)
if (ncol(data_long) == 3) {
  simpleplot(data_long=data_long)
} else {
  complexplot(data_long=data_long, variables=var)
}
invisible(dev.off())
print(paste0("Saved: ", save))

save = paste0(strsplit(basename(file), ".csv")[[1]], ".svg")
svg(save, width=7.5, height=7.5)
if (ncol(data_long) == 3) {
  simpleplot(data_long=data_long)
} else {
  complexplot(data_long=data_long, variables=var)
}
dev.off()