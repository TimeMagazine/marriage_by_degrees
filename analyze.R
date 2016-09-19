# Code for degree compability
# Link: http://time.com/4497291/college-degree-major-love-marriage/
# By Chris Wilson
# LICENSE: Creative Commons Attribution 4.0
# https://creativecommons.org/licenses/by/4.0/
# DISCLAIMER: I am not a pro at R by any stretch,
# so all calculations here were tested against 
# manual SQL queries of the same dataset
# Please forgive sloppy code, or better yet, correct it with 
# a pull request or email to chris.wilson@time.com


# to install "foreign", run `install.packages("foreign")` or manually install from the R interface
library(foreign)
# load the data from IPUMS. Make sure you unzip it first. This will take a minute
print("Loading data (will take about a minute)");
data <- read.spss("ipums/usa_00094.sav", to.data.frame = TRUE);

# IPUMS-USA, University of Minnesota, www.ipums.org.
# https://usa.ipums.org/usa/cite.shtml

# reduce that population to only those where the spouse also has a degree
two_degrees <- subset(data, data$DEGFIELDD_SP != "N/A" & !is.na(data$DEGFIELDD_SP))

# get the total population by summing the individual weights of each person
# in the sample. This is technically twice the size of the population since
# each couple is in the data twice, once and the primary and once as the spouse
population <- sum(two_degrees$PERWT)

# load the simplified list of degrees that TIME curated from DEGFIELDD
# https://docs.google.com/spreadsheets/d/1q_ZQDYDvtJzpI8jQ8y8Y68z23j3OgVGORSG80rcgAcQ/edit?usp=sharing
degrees <- read.csv("canonical.csv")

# function to simplify the degrees for both partners
simplifyDegrees <- function(degfieldd) {
  canonical <- as.character(degrees$canonical[degrees$detailed==degfieldd]);
  # print(paste(degfieldd,"-",canonical));
  two_degrees$DEGSIMPLE[two_degrees$DEGFIELDD==degfieldd] <- canonical
  two_degrees$DEGSIMPLE_SP[two_degrees$DEGFIELDD_SP==degfieldd] <- canonical
  return (two_degrees);
}

# run this function for every specific degree
# this will take about 30 seconds

print("Reducing complexity in degree definitions");
for (detailed in degrees$detailed) {
  two_degrees <- simplifyDegrees(detailed)
}

# every couple is in the data twice, once as the primary and once as the spouse
# let's confirm that we have the same number of degrees
# in both DEGSIMPLE AND DEGSIMPLE_SP
# table(two_degrees$DEGSIMPLE) == table(two_degrees$DEGSIMPLE_SP)

# Let's look at overall popularity of degrees in primaries and spouses
# we're going to look at the raw record count and the weighted count
count    <- aggregate(two_degrees$PERWT, by=list("degree" = two_degrees$DEGSIMPLE), FUN = length)
weighted <- aggregate(two_degrees$PERWT, by=list("degree" = two_degrees$DEGSIMPLE), FUN = sum)

# let's combine into one data frame
colnames(count) <- c("degree","count_degree")
colnames(weighted) <- c("degree","weighted_degree")
popularity <- merge(count, weighted, by=c("degree"))

# and do the same for spouses
count    <- aggregate(two_degrees$PERWT, by=list("degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = length)
weighted <- aggregate(two_degrees$PERWT, by=list("degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = sum)

# again, let's combine into one data frame
colnames(count) <- c("degree_spouse","count_spouse")
colnames(weighted) <- c("degree_spouse","weighted_spouse")
popularity_spouse <- merge(count, weighted, by=c("degree_spouse"))

# and merge into one data frame
popularity <- merge(popularity, popularity_spouse, by.x=c("degree"), by.y=c("degree_spouse"))

# and measure the percent of spouses with a given degree from 0-100
popularity$percent <- popularity$weighted_degree / population * 100
popularity$percent_spouse <- popularity$weighted_spouse / population * 100

# phew, these sum to 100
# sum(popularity$percent)
# sum(popularity$percent_spouse)

#NOTE
# You may notice that the percentages for percent and percent_spouse
# do no perfectly match, even though everyone is in the data twice
# This is because a person and his or her spouse do not have exactly
# the same weight. We expect this. But the values are VERY close

print("Calculating matches");

# now let's do the same thing for every combination of major
count    <- aggregate(two_degrees$PERWT, by=list("degree" = two_degrees$DEGSIMPLE, "degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = length)
weighted <- aggregate(two_degrees$PERWT, by=list("degree" = two_degrees$DEGSIMPLE, "degree_spouse" = two_degrees$DEGSIMPLE_SP), FUN = sum)

# and combine again
colnames(count) <- c("degree", "degree_spouse", "count");
colnames(weighted) <- c("degree", "degree_spouse", "weighted");
matches <- merge(count, weighted, by=c("degree", "degree_spouse"))

# okay, now we need to find the RELATIVE popularity of a degree 
# in a spouse compared to that of the general population
popularity_by_degree_combo <- function(match) {
  # how popular is the primary degree?
  number_of_primary_majors = popularity$weighted_degree[popularity$degree==match[["degree"]]]
  specific_popularity = as.numeric(match[["weighted"]]);
    
  # and what percent of people with the spouse's degree married someone
  # with the primary's degree?
  return(100 * specific_popularity / number_of_primary_majors);
}

matches$percent <- apply(matches, 1, popularity_by_degree_combo)

# and compare that to the overall percent to get the relative odds
odds_by_degree_combo <- function(match) {
  overall_percent = popularity$percent_spouse[popularity$degree==match[["degree_spouse"]]]
  specific_percent = as.numeric(match[["percent"]]);
  # print(paste(match[["degree"]], match[["degree_spouse"]], match[["degree_spouse"]], overall_percent, specific_percent));
  
  # and what percent of people with the spouses degree married someone with the 
  # primary's degree?
  return(specific_percent / overall_percent);
}

matches$odds <- apply(matches, 1, odds_by_degree_combo)

# NOTE
# Again, because of different weights, the compatibilities
# are not perfectly reciprocal, but very close

# We only want combos with at least 30 examples
filtered = subset(matches, matches$count >= 30);

# and only those degrees that show up in over 10 combinations
frequencies = as.data.frame(table(filtered$degree))
colnames(frequencies) <- c("degree", "frequency");

pare_down <- function(deg) {
  freq <- frequencies$frequency[frequencies$degree==deg];
  if (is.na(freq) | freq < 20) {
    print(paste("Not enough",deg, freq));
    filtered = subset(filtered, degree != deg);
    filtered = subset(filtered, degree_spouse != deg);
  }
  return (filtered);
}

for (deg in unique(filtered$degree)) {
  filtered = pare_down(deg)
}

print("Writing data file");
write.csv(filtered, "filtered.csv")

# For fun, let's look at who is most provincial
same_majors <- subset(filtered, degree == degree_spouse)

same_majors[order(-same_majors$odds),]
