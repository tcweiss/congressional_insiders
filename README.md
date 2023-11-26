# *Insider Trading in The U.S. Congress - An Empirical Analysis*


<a name="overview"></a>

## Overview
This is the online appendix for *Insider Trading in The U.S. Congress - An Empirical Analysis* (2023), a paper I wrote. On this site, you can find R code for scraping stock trades reported by members of Congress, as well as a clean dataset of congressional stock trades executed between 01/2019 and 07/2023. Details can be found below.

If you would like to reuse any of the content found here, please feel free to do so. If you intend to republish my data, I kindly ask you to give credit by linking to this site. For questions or remarks, I can be reached at tcweiss@protonmail.com



<br><br>

<a name="code"></a>
## Code

This repo contains three R functions for scraping congressional stock trades:
- `scrape_house()` scrapes trades of a Representative from an individual report
- `scrape_house_all()` scrapes trades of all Representatives from all reports filed in a given year
- `scrape_senate_all()` scrapes trades of all Senators filed between a starting and ending date

<br>

To use these functions, make sure to have all dependencies installed:

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

<br>

Scraping the Senate webpage additionally requires [Google Chrome](https://www.google.com/chrome/) and [Chromedriver](https://chromedriver.chromium.org/home). It is important that your version of Chromedriver matches the version of Google Chrome installed on your machine. To load the three functions into you session, run [code.R](https://github.com/tcweiss/congressional_insiders/blob/main/code.R).



<br>

#### `scrape_house()`

Congressional stock trades are disclosed in *periodic transaction reports* (PTRs). The House of Representatives publishes them as PDFs [here](https://disclosures-clerk.house.gov/FinancialDisclosure). To extract all public stock trades from a report, use `scrape_house()`. The only argument is the URL pointing the report (or the path, if you saved the report locally):

```
url <- 'https://disclosures-clerk.house.gov/public_disc/ptr-pdfs/2022/20020393.pdf'
scrape_house(url)

```

The function returns a tibble with the following variables:
- *owner*: Owner of the brokerage account. This is either the politician, their spouse (SP), a dependent child (DC), or it's a joint account (JT).
- *asset*: Name of the asset. Reports disclosed 2019 or later abbreviations indicating the asset type, so the functions will automatically extracts public stocks only. For reports filed before 2019, there are no abbreviations and the function will returns trades of involving any asset type.
- *is_stock*: Indicates if the asset is known to be a stock (Yes), or whether it may be some other asset (?).
- *ticker*: Ticker under which the asset trades.
- *type*: Sale (S), purchase (P), or exchange (E).
- *transaction_date*: Day on which the trade was executed.
- *amount*: Amount range for the value of the trade. If exact amount was reported, this contains the exact amount.
- *comment*: Any comments the filer has added. If no comments were added, this is empty.
- *id*: If a trade was already reported at some point, filers can amend or delete it by listing it again in a later report and marking it accordingly. In this case, the transaction will shows up again on a later report and is accompanies by an id (more details below). If the trade was reported for the first time, this will be empty.
- *filing_status*: If the trade was filed again has an id, this variables indicates specifies the reason why the trade is filed again (Amended/Deleted). If the trade was reported for the first time, this will be empty.

<br>
If a report does not contain stock trades, the function does not return anything. If the report was handwritten and scanned, it will return a tibble with one row and the entry HANDWRITTEN for all variables.

<br><br>

#### `scrape_house_all()`

To scrape all House trades filed in a given year, use `scrape_house_year()`. The only argument is the year of disclosure:

```
scrape_house_year(2022)

```

The exact runtime depends on your internet connection, but I would expect about 1-2h. The function returns a tibble with the same variables as `scrape_house()`, as well as the following four variables:
- *name*: Name of the filer
- *district*: Political district of the filer
- *disclosure_date*: Date the trade was disclosed
- *doc_link*: URL linking to the concerning report on the House webpage

<br><br>

#### `scrape_senate_all()`

The Senate publishes PTRs on [this](https://efdsearch.senate.gov/search/) page. This is a non-static webpage, and the URLs do not follow a predictable pattern as in the House, so the scraping approach works differently. To scrape all Senate trades filed over a certain period, use `scrape_senate_year()`. The arguments are the starting and ending date (format MM/DD/YYYY) and a version of Chromedriver that matches your installed version of Chrome:

```
scrape_senate_year(start_date = '01/01/2019',
                   end_date = '12/31/2019',
                   chromedriver = '119.0.6045.159')

```

<br>

Running this function will open a window in Google Chrome that interacts with the Senate's webpage. The window is controlled by the function, so do not close it until it the function has completed running. Scraping a period of one year should take less time than for the House. The output will be a tibble with the following variables

- *name*: Name of the filer
- *disclosure_date*: Day on which the trade was disclosed
- *transaction_date*: Day on which the trade was executed
- *owner*: Owner of the brokerage account. Can be the member, their spouse (SP), a joint account (JT), or their dependent child (DC).
- *asset*: Name of the stock
- *ticker*: Ticker of the stock
- *type*: Sale (S), purchase (P), or exchange (E)
- *amount*: Amount range for the value of the trade. If exact amount was reported, this will be the exact amount.
- *comment*: Any comments the filer has added. If no comments, this will be empty.
- *doc_link*: URL linking to the concerning report on the House webpage

<br><br>

#### Remarks

Note that unlike for the House, the Senate function returns no id or filing_status variable. Due to the way the trades are reported, it is possible to automatically correct for amended or deleted trades by the Senate - the function does that automatically. For the House, you must do it yourself. 

After scraping House trades, look at all trades where the id and filing_status variables are not empty. These refer to previously filed trades that were erroneous (and the trade marked a 'Amended' in a later report show a corrected version) or they refer to previously filed trades that were mistakenly reported (and should not have been reported in the first place). Look for trades of the same stock, by the same person, and the same transaction date, but which was filed at some earlier point than the trade that was marked as amended/deleted. For trades where 'filing_status' is 'Amended', one should then drop the original trade and only keep the trade marked as amended. For deletions, both the original trade and the subsequent one where 'filing_status' shows 'Deleted' must be dropped.

<br><br>

<a name="data"></a>
## Data

This repo contains a cleaned-up [sample](https://github.com/tcweiss/congressional_insiders/tree/main/data) of congressional stock I compiled, covering all congressional trades of public stocks executed between 01-01-2019 and 31-07-2023. It was prepared as follows:
1) Use the functions above to scrape all congressional trades disclosed between 2019 and 2023.
2) Drop any trades with trading date before 01-01-2019. Some trades are reported with a (sometimes massive) delay, so some trades disclosed in 2019 have actually been executed earlier in earlier years.
3) Export the subset of handwritten/scanned entries that could not be scraped. Using the URLs returned by the function, I looked up all these reports on the webpages of the House and Senate and transcribed information on trades involving public stock.
4) Account for any amendments and deletions in scraped House trades (see the previous section for details). For each House trade marked as 'Amended' or 'Deleted', I looked for a corresponding trade of the same asset, by the same filer, and with the same transaction date, that was already disclosed at a previous date. For trades marked as 'Amended', I drop the identified trade that was filed at an earlier date (the erroneous version). For those marked as 'Deleted', both the identified and the newer trade with the marking are dropped. This is not necessary for Senate trades, as it can be done automatically by the scraping function.
5) Drop all exchange transactions (that is, keep only sales and purchases). Exchanges occur as result of mergers or takeovers, in which case a persons's shares in company A are automatically converted to a certain number of shares in company B. I dropped them since 1) they only accounted for some ~ 0.02% of all transactions, 2) it is not straightforward how to incorporate them in portfolio-based analyses, and 3) they do not occur on initiative of the filer, so they are unlikely to reflect any potential insider trading practices. 
6) Look up all unique assets in Refiniv Eikon. Some assets are mistakenly marked as public stocks but are actually some other asset (e.g. ETFs, bonds, options, etc). Since I only focus on stocks, these are dropped. Sometimes companies are renamed, in which case the stock and the ticker may trade under a different name today than at the time of disclosure. In these cases, I replaced the old stock's name and ticker with the current (July/August 2023) version. Different people often list the same stock in different ways, so I also standardized all stocks' names, (e.g. "Berkshire Hathaway B", "Berkshire Class B", "Berkshire Hathaway" are all renamed to "Berkshire Hathaway - Class B").
7) Finally, I slightly adjusted the names of politicians to be in line with those listed in other databases (e.g. "Jim Inhofe" was changed to "James M Inhofe"). This means first and middle names might be different from those seen in reports. 

