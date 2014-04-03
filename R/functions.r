
# Imports
library(gdata)

# Global options
options(stringsAsFactors=F)
options(scipen=999)


# Functions

## Ignores "NA" values for standard functions
safeSum <- function(value) sum(value, na.rm = TRUE)
safeMean <- function(value) mean(value, na.rm = TRUE)

## Parses a currency value in the form "$1,000,000"
parseCurrency <- function(value) as.numeric(gsub(",", "", sub("\\$","", value)))
## Returns the correct financial year for a month and year
financialYear <- function(range) {
  month <- range[1]
  year <- range[2]
  firstMonths = c("January", "February", "March", "April", "May", "June")
  finYear <- if (is.element(month, firstMonths)) as.numeric(year) else as.numeric(year) + 1
  return(as.numeric(finYear))
}
## Generates a population ratio (based on June 2013)
popRatio <- function(baseYear) {
  baseYear <- as.numeric(baseYear)
  if ((baseYear - 1967) < 14) {
    popRow <- 10 + (baseYear - 1967)
  }
  else {
    popRow <- 24 + (baseYear - 1981) * 4  
  }
  popTest <- as.numeric(pop$Estimated.Resident.Population....Persons....Australia..[popRow])
  pop2013 <- as.numeric(pop$Estimated.Resident.Population....Persons....Australia..[152])
  return(pop2013 / popTest)
}
## Generates a cpi ratio (based on June 2013)
cpiRatio <- function(baseYear) {
  cpiRow <- 85 + (baseYear - 1967) * 4
  cpiTest <- as.numeric(cpi$Index.Numbers....All.groups.CPI....Australia[cpiRow])
  cpi2013 <- as.numeric(cpi$Index.Numbers....All.groups.CPI....Australia[269])
  return(cpi2013 / cpiTest)
}
## Generates a gdp ratio based on chain volume measures (based on June 2013)
gdpRatio <- function(baseYear) {
  gdpRow <- 41 + (baseYear - 1967) * 4
  gdpTest <- as.numeric(gdp$Gross.domestic.product..Chain.volume.measures..[gdpRow])
  gdp2013 <- as.numeric(gdp$Gross.domestic.product..Chain.volume.measures..[225])
  gdpGross <- (gdp2013 / gdpTest)
  # Correct for Pop ratio to correct for per capita
  gdpGross <- gdpGross / popRatio(baseYear)
  return(gdpGross)
}
## Generates an CPI indexed cost (based on June 2013)
indexCosts <- function(range) {
  baseYear <- range[1]
  insuredCost <- range[2]
  return(insuredCost * cpiRatio(baseYear))
}
## Normalise cost - TODO: this needs to be much more robust (cf. discussion on normalisation)
normalisedCosts <- function(range) {
  baseYear <- range[1]
  cost <- range[2]
  # Normalise for [1] inflation; [2] population growth; [3] wealth increase (GDP as a temporary proxy)
  # TODO: Add at least state-based equivalents
  return(cost * cpiRatio(baseYear) * popRatio(baseYear) * gdpRatio(baseYear))
}
## Normalise population
normalisedPopulation <- function(range) {
  baseYear <- as.numeric(range[1])
  pop <- as.numeric(range[2])
  # Normalise for inflation
  return(pop * popRatio(baseYear))
}
## Load data
loadData <- function() {
  mydata <<- read.xls("./data/report_v5.xlsx", 2)
  cpi <<- read.xls("./data/cpi.xlsx", 2)
  pop <<- read.xls("./data/pop_consolidate.xlsx", 1)
  gdp <<- read.xls("./data/5206001_key_aggregates.xlsx", 2)
}
## Generate computed columns
computeColumns <- function() {

  # ... for cleaned up costs 
  mydata$Costs.cleaned <<- apply(data.matrix(mydata[,20]), 1, parseCurrency)
  
  # ... for financial years
  mydata$Year.financial <<- apply(mydata[c("Month", "Year")], 1, financialYear)

  # ... for CPI-indexed insured costs
  mydata$Insured.Costs.indexed <<- apply(mydata[c("Year.financial", "Costs.cleaned")], 1, indexCosts)
  
  # ... for normalised insured costs
  mydata$Insured.Costs.normalised <<- apply(mydata[c("Year.financial", "Costs.cleaned")], 1, normalisedCosts)
  
  # ... for population-inflated deaths and injuries
  mydata$Deaths.normalised <<- apply(mydata[c("Year.financial", "Deaths")], 1, normalisedPopulation)
  mydata$Injuries.normalised <<- apply(mydata[c("Year.financial", "Injuries")], 1, normalisedPopulation)
}

## Specific cost estimation functions
### Cost of public services
costOfPublicServices <- function() {
  # Cost per call? Say $10 - TODO: NEEDS BETTER EVIDENCE
  callsToSES * 10
}
### Intangibles
#### Cost of life
costOfLife <- function() {
  # 2006 BTE figure, adjusted to 2013
  # return(indexCosts(c(2006, 2400000)))
  # 2008 Best Practice Regulation - Value of Statistical Life
  return(indexCosts(c(2008, 3500000)))
  # Victorian Guidance Note on Dam Safety Decision DSE 2012
  #return(indexCosts(c(2012, 4500000)))
  # US - value of safety in different industries
}
costOfLife()

costOfHospitalisedInjury <- function() {
  # 2006 BTE figure, adjusted to 2013
  return(indexCosts(c(2006, 214000)))
}
costOfNonHospitalisedInjury <- function() {
  # 2006 BTE figure, adjusted to 2013
  return(indexCosts(c(2006, 2200)))
}
## Returns the proportion of hospitalised injury to overall injuries
proportionOfHospitalisedInjury <- function() {
  # Completely manufactured - TODO: NEEDS BETTER EVIDENCE
  0.2
}


# Costs

## Get all events for the purpose of generating costs
getEvents <- function() {
  events <- mydata[c("Year.financial", "resourceType", "State.1", "State.2..", "Insured.Costs.indexed", "Insured.Costs.normalised", "Calls.to.SES", "Deaths", "Injuries", "Deaths.normalised", "Injuries.normalised")]
  events$Deaths <- as.numeric(events$Deaths)
  events$Injuries <- as.numeric(events$Injuries)
  events$Deaths.normalised <- as.numeric(events$Deaths.normalised)
  events$Injuries.normalised <- as.numeric(events$Injuries.normalised)
  xsub <- events[,4:11] 
  xsub[is.na(xsub)] <- 0 
  events[,4:11]<-xsub
  return (events)
}

# Calculate direct costs
directCosts <- function(events) {
  events$directCost <- with(events, Insured.Costs.indexed)
  
  # Normalised values
  events$directCost.normalised <- with(events, Insured.Costs.normalised)

  return (events)
}

# Calculate indirect costs
indirectCosts <- function(events) {
  events$indirectCost <- with(events, Calls.to.SES * 10)
  
  # Normalised values
  events$indirectCost.normalised <- events$indirectCost

  return (events)
}

# Calculate intangible costs
intangibleCosts <- function(events) {
  events$deathCosts <- with(events, Deaths * costOfLife())
  events$injuryCosts <- with(events, 
                             Injuries * proportionOfHospitalisedInjury() * costOfHospitalisedInjury() +
                               Injuries * (1 - proportionOfHospitalisedInjury()) * costOfNonHospitalisedInjury())
  events$intangibleCost <- rowSums(subset(events, select = c(deathCosts, injuryCosts)), na.rm = TRUE)

  # Normalised values
  events$deathCosts.normalised <- with(events, Deaths.normalised * costOfLife())
  events$injuryCosts.normalised <- with(events, 
                                        Injuries.normalised * proportionOfHospitalisedInjury() * costOfHospitalisedInjury() +
                                          Injuries.normalised * (1 - proportionOfHospitalisedInjury()) * costOfNonHospitalisedInjury())
  events$intangibleCost.normalised <- rowSums(subset(events, select = c(deathCosts.normalised, injuryCosts.normalised)), na.rm = TRUE)
  return (events)
}

## Total cost for evant
totalCostForEvent <- function() {
  events <- getEvents()
  events <- directCosts(events)
  events <- indirectCosts(events)
  events <- intangibleCosts(events)
  events$total <- rowSums(subset(events, select = c(directCost, indirectCost, intangibleCost)), na.rm = TRUE)
  events$total.normalised <- rowSums(subset(events, select = c(directCost.normalised, indirectCost.normalised, intangibleCost.normalised)), na.rm = TRUE)
  return(events) 
}
