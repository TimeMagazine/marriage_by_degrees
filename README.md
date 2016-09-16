# Marriage by degrees
The R code to calculate marital compatibility between people with different degrees

## Getting started
+ You need [R](https://www.r-project.org/), and I recommend [RStudio](https://www.rstudio.com/)
+ Unzip the IPUMS data (`ipums/usa_00094.sav.zip`) file manually or via `unzip ipums/usa_00094.sav.zip`

## The Data
+ The data was extracted from [ipums.org](ipums.org), the fantastic Census microdata site. You can see the codebook for the extract at `ipums/usa_00094.txt`, which contains all the information on the variables that were extracted.

## Running the script
Open `analyze.R` to see the heavily commented code, `data.Rproj` in RStudio for a nice visual version, or just run the file:

	RScript analyze.R

This will spit out a file called `filtered.csv` with all of the information used in the interactive.