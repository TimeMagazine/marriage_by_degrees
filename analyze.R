# Code for degree compability
# Link TK
# By Chris Wilson
# DISCLAIMER: I am not a pro at R, so all calculations here were
# tested against manual SQL queries of the same dataset
# Please forgive sloppy code, or better yet, correct it with 
# a pull request or email to chris.wilson@time.com

library(foreign)
# load the data from IPUMS. Make sure you unzip it first. This will take a minute
data <- read.spss("ipums/usa_00094.sav", to.data.frame = TRUE);

# reduce that population to only those where the spouse also has a degree
two_degrees <- subset(data, data$DEGFIELDD_SP != "N/A" & !is.na(data$DEGFIELDD_SP))

# get the total population by summing the individual weights of each person
# in the sample
population <- sum(two_degrees$PERWT)

# load the simplified list of degrees that TIME curated from DEGFIELDD
# https://docs.google.com/spreadsheets/d/1q_ZQDYDvtJzpI8jQ8y8Y68z23j3OgVGORSG80rcgAcQ/edit?usp=sharing
degrees <- read.csv("canonical.csv")

# function to simplify the degrees for both partners
simplifyDegrees <- function(degfieldd) {
  canonical <- as.character(degrees$canonical[degrees$detailed==degfieldd]);
  print(paste(degfieldd,"-",canonical));
  two_degrees$DEGSIMPLE[two_degrees$DEGFIELDD==degfieldd] <- canonical
  two_degrees$DEGSIMPLE_SP[two_degrees$DEGFIELDD_SP==degfieldd] <- canonical
  return (two_degrees);
}

# run this function for every specific degree
# this will take about 30 seconds
for (detailed in degrees$detailed) {
  two_degrees <- simplifyDegrees(detailed)
}

# every couple is in the data twice, once as the primary and once as the spouse
# let's confirm that we have the same number of degrees in both DEGSIMPLE AND DEGSIMPLE_SP
table(two_degrees$DEGSIMPLE) == table(two_degrees$DEGSIMPLE_SP)

# Let's look at overall popularity of degrees in spouses
# we're going to look at the raw record count and the
# weighted count
count    <- aggregate(two_degrees$PERWT, by=list("degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = length)
weighted <- aggregate(two_degrees$PERWT, by=list("degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = sum)

# let's combine into one data frame
colnames(count) <- c("degree_spouse","count")
colnames(weighted) <- c("degree_spouse","weighted")
popularity <- merge(count, weighted, by=c("degree_spouse"))

# and measure the percent of spouses with a given degree from 0-100
popularity$percent <- popularity$weighted / population * 100

# few, this sums to 100
sum(popularity$percent)

# now let's do the same thing for every combination of major
count    <- aggregate(two_degrees$PERWT, by=list("degree" = two_degrees$DEGSIMPLE, "degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = length)
weighted <- aggregate(two_degrees$PERWT, by=list("degree" = two_degrees$DEGSIMPLE, "degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = sum)

# and combine again
colnames(count) <- c("degree", "degree_spouse","count")
colnames(weighted) <- c("degree", "degree_spouse","weighted")
matches <- merge(count, weighted, by=c("degree", "degree_spouse"))

# okay, now we need to find the RELATIVE popularity of a degree 
# in a spouse compared to that of the general population
popularity_by_degree_combo <- function(match) {
  overall_popularity = popularity$weighted[popularity$degree_spouse==match[["degree_spouse"]]]
  specific_popularity = as.numeric(match[["weighted"]]);
  
  # and what percent of people with the spouses degree married someone with the 
  # primary's degree?
  return(100 * specific_popularity / overall_popularity);
}

matches$percent <- apply(matches, 1, popularity_by_degree_combo)

# and compare that to the overall percent to get the relative odds
odds_by_degree_combo <- function(match) {
  overall_percent = popularity$percent[popularity$degree_spouse==match[["degree"]]]
  specific_percent = as.numeric(match[["percent"]]);
  
  # and what percent of people with the spouses degree married someone with the 
  # primary's degree?
  return(specific_percent / overall_percent);
}

matches$odds <- apply(matches, 1, odds_by_degree_combo)

# We only want combos with at least 30 examples
filtered = subset(matches, matches$count >= 30);

write.csv(filtered, "filtered.csv")
