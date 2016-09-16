# Marriage by Degrees
The R code to calculate marital compatibility between people with different academic degrees

## Getting started
+ You need [R](https://www.r-project.org/), and I recommend [RStudio](https://www.rstudio.com/)
+ Unzip the IPUMS data (`ipums/usa_00094.sav.zip`) file manually or via `unzip ipums/usa_00094.sav.zip`

## The Data
The data was extracted from [ipums.org](ipums.org), the fantastic Census microdata site, in SPSS format (`.sav`) for easy importing into R. You can see the codebook for the extract at [`ipums/usa_00094.txt`](ipums/usa_00094.txt), which contains all the information on the variables that were extracted.

[Citation](https://usa.ipums.org/usa/cite.shtml): IPUMS-USA, University of Minnesota, [www.ipums.org](ipums.org).

## Running the script
You need the "foreign" library, which you can install manually through R interface or like so:

	install.packages("foreign")

Then open [`analyze.R`](analyze.R) to see the heavily commented code, `data.Rproj` in RStudio for a nice visual version, or just run the file:

	RScript analyze.R

This will spit out a file called `filtered.csv` with all of the information used in the interactive.

# LICENSE
[Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/)

**tl;dr**

You are free to:
+ Share — copy and redistribute the material in any medium or format
+ Adapt — remix, transform, and build upon the material for any purpose, even commercially.
+ **You must give appropriate credit by linking to this repository and the associated TIME article, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.**

