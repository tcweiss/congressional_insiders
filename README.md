# *Insider Trading in The U.S. Congress - An Empirical Analysis*


<a name="overview"></a>

## Overview
This is the online appendix for *Insider Trading in The U.S. Congress - An Empirical Analysis* (2023), a paper I wrote. On this site, you can find R code for scraping stock trades reported by members of Congress, as well as a clean dataset of congressional stock trades executed between 01/2019 and 07/2023. Details can be found below.

If you would like to reuse any of the content found here, please feel free to do so. In case you republish my data, I kindly ask you to give proper credit by linking to this site. For you questions or remarks, I can be reached at tcweiss@protonmail.com.



<br><br>

<a name="code"></a>
## Code

I wrote three R functions that can be used to scrape congressional stock trades:
- ´scrape_house()´ scrapes trades of House members from an individual report
- ´scrape_house_year()´ scrapes trades of House members from all reports filed in a given year
- ´scrape_senate_year()´ scrapes trades of Senate members for a specified starting and ending date

First, make sure to have all dependencies installed by running the following code:

```
install.packages(c("tidyverse",                
                   "magrittr",        
                   "pdftools",          
                   "janitor",                
                   "rvest", 
                   "jsonlite",
                   "htmltools",
                   "utils",
                   "RSelenium",
                   "xml2",
                   "netstat"))
```

Scraping the Senate webpage also requires Google Chrome and Chromedriver. Make sure that your version of Chromedriver matches the version of Google Chrome installed on your machine. Finally, run code.R contained in this repo to load all functions into your session.

### Usage

Congressional stock trades can be found in *periodic transaction reports* (PTRs). The House publishes PTRs on this page


https://disclosures-clerk.house.gov/FinancialDisclosure

<a name="data"></a>


### Locally

Alternatively, you can also run the app locally. This requires the following programs:
- R version 4.2.0: https://cran.rstudio.com 
- RStudio: https://www.rstudio.com/products/rstudio/download/
- Required libraries: ```shiny``` ```shinyWidgets``` ```shinythemes``` ```PerformanceAnalytics``` ```PortfolioAnalytics``` ```tidyquant``` ```tidyverse``` ```magrittr``` ```reactable``` ```arrow``` ```bslib``` ```qs``` ```timetk``` ```dygraphs``` ```rvest```

In order to properly use our "Investing@HSG"-App, it is essential to have installed the above listed libraries prior to running this program. To install all libraries, run the following code in your R console:

```
install.packages(c("shiny",                
                   "shinyWidgets",        
                   "shinythemes",          
                   "bslib",                
                   "PerformanceAnalytics", 
                   "PortfolioAnalytics",
                   "tidyquant",
                   "tidyverse",
                   "magrittr",
                   "reactable",
                   "arrow",
                   "qs",
                   "timetk",
                   "dygraphs",
                   "rvest"))
```

<a name="data"></a>
## Data
