# *Insider Trading in The U.S. Congress - An Empirical Analysis*


<a name="overview"></a>

## Overview
This is the online appendix for *Insider Trading in The U.S. Congress - An Empirical Analysis* (2023), a paper I wrote. On this site, you can find R code for scraping stock trades reported by members of Congress, as well as a clean dataset of congressional stock trades executed between 01/2019 and 07/2023. Details can be found below.

If you would like to reuse any of the content found here, please feel free to do so. In case you republish my data, I kindly ask you to give proper credit by linking to this site. For you questions or remarks, I can be reached at tcweiss@protonmail.com.



<br><br>

<a name="code"></a>
## Code

I wrote three R functions for scraping congressional stock trades:
- `scrape_house()` scrapes trades of a House member from an individual report
- `scrape_house_year()` scrapes trades of House members from all reports filed in a given year
- `scrape_senate_year()` scrapes trades of Senate members for a specified starting and ending date

<br>

In order to use these functions, make sure to have all dependencies installed by running:

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

Scraping the Senate webpage additionally requires [Google Chrome](https://www.google.com/chrome/) and [Chromedriver](https://chromedriver.chromium.org/home). Make sure that your version of Chromedriver matches the version of Google Chrome installed on your machine. To load the three functions into you session, run code.R contained in this repo.



<br>

### `scrape_house()`

Congressional stock trades can be found in *periodic transaction reports* (PTRs). The House publishes PTRs on [this](https://disclosures-clerk.house.gov/FinancialDisclosure) page. You can extract all stock trades from a PTR using `scrape_house()`. The only argument is the URL pointing the PTR (or the path, if you saved the file saved locally):

```
url <- 'https://disclosures-clerk.house.gov/public_disc/ptr-pdfs/2022/20020393.pdf'
scrape_house(url)

```

The function returns a tibble with the following variables:
- owner: Owner of the brokerage account. Can be the member, their spouse (SP), a joint account (JT), or their dependent child (DC).
- asset: Name of the asset. For report filed from 2019 onwards, reports contain asset type abbreviations, so the functions automatically extracts stocks only. For reports filed before 2019, there are no abbreviations and the function extracts all assets.
- is_stock: Indicates if the asset is known to be a stock (Yes), or whether it may be some other asset (?).
- ticker: Ticker of the asset.
- type: Sale (S), purchase (P), or exchange (E).
- transaction_date: Day on which the trade was executed.
- amount: Amount range for the value of the trade. If exact amount was reported, this will be the exact amount.
- comment: Any comments the filer has added. If no comments, this will be empty.
- id: If the trade was reported at an earlier date already, filers can amend or delete it. In this case, there will be an id (without further meaning). If the trade was reported for the first time, this will be empty.
- filing_status: If the trade was reported at an earlier date already, this indicates the reason why the trade is filed again (amendment or deletion). If the trade was reported for the first time, this will be empty.

If a report does not contain stock trades, the function does not return anything. If the report was handwritten and scanned, it will return a tibble with one row and the entry HANDWRITTEN for all variables.

<br>

### `scrape_house_year()`

To scrape all House trades filed in a given year, you can use `scrape_house_year()`. The only argument is the year:

```
scrape_house_year(2022)

```

The exact runtime depends on your internet connection, but I would expect about 1-2h. The function returns a tibble with the same variables as `scrape_house()`, as well as the following four variables:
- name: Name of the filer
- district: Political district of the filer
- disclosure_date: Date the trade was disclosed
- doc_link: URL linking to the concerning report on the House webpage

<br><br>

### `scrape_senate_year()`

The Senate publishes PTRs on [this](https://efdsearch.senate.gov/search/) page. This is a non-static webpage and the URL do not follow some predictable pattern as for the House, meaning that the scraping approach also works differently. To scrape all Senate trades filed over a certain period, use `scrape_senate_year()`. The arguments are the starting and ending date (format MM/DD/YYYY) and a version of Chromedriver that matches your installed version of Chrome:

```
scrape_senate_year(start_date = '01/01/2019', end_date = '12/31/2019', chromedriver = '119.0.6045.159')

```

Running this function will open a window in Google chrome. Since the function automatically controls the window, make sure not to close it until it has run. Scraping a window of one year takes about the same time as for the House. The function will return a tibble with the following variables

- name: Name of the filer
- disclosure_date: Day on which the trade was disclosed
- transaction_date: Day on which the trade was executed
- owner: Owner of the brokerage account. Can be the member, their spouse (SP), a joint account (JT), or their dependent child (DC).
- asset: Name of the stock
- ticker: Ticker of the stock
- type: Sale (S), purchase (P), or exchange (E)
- amount: Amount range for the value of the trade. If exact amount was reported, this will be the exact amount.
- comment: Any comments the filer has added. If no comments, this will be empty.
- doc_link: URL linking to the concerning report on the House webpage


### Remarks

Note that unlike for the House, there is no id/filing_status variables. The Senate webpage makes it easy to identify past trades to which an amendment refers, so the function automatically keeps only the most recent version of a trade that was amended (and it drops trades that were deleted). For the House, you need to needs to be done manually. 

After you scraped house trades, you should take a look at trades where the id and filing_status variables are not empty. These refer to previously filed trades that were erroneous (and the amended entry is the corrected version) or they refer to previously filed trades that were mistakenly added (and should not have been reported in the first place). The problem is that there is no way to automatically identify the previously filed trade. To identify it, look for trades in the same stock, by the same person, as some earlier date than the trade that was marked as amended or deleted. For amendments, you should then drop the original trade and only keep the trade marked as amended. For deletions, you should drop both the original trade and the one marked as deletion.



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
