# *Insider Trading in The U.S. Congress - An Empirical Analysis*


<a name="overview"></a>

## Overview
This is the online appendix for *Insider Trading in The U.S. Congress - An Empirical Analysis* (2023), a paper I wrote. On this site, you can find R code for scraping stock trades reported by members of Congress, as well as a clean dataset of congressional stock trades executed between 01/2019 and 07/2023. Details can be found below.

If you would like to reuse any of the content found here, please feel free to do so. If you intend to republish my data, I kindly ask you to give credit by linking to this site. For you questions or remarks, I can be reached at tcweiss@protonmail.com.



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

#### `scrape_house()`

Congressional stock trades can be found in *periodic transaction reports* (PTRs). The House publishes them [here](https://disclosures-clerk.house.gov/FinancialDisclosure). You can extract all stock trades from a PTR using `scrape_house()`. The only argument is the URL pointing the PTR (or the path, if you saved the file saved locally):

```
url <- 'https://disclosures-clerk.house.gov/public_disc/ptr-pdfs/2022/20020393.pdf'
scrape_house(url)

```

The function returns a tibble with the following variables:
- *owner*: Owner of the brokerage account. Can be the member, their spouse (SP), a joint account (JT), or their dependent child (DC).
- *asset*: Name of the asset. For report filed from 2019 onwards, reports contain asset type abbreviations, so the functions automatically extracts stocks only. For reports filed before 2019, there are no abbreviations and the function extracts all assets.
- *is_stock*: Indicates if the asset is known to be a stock (Yes), or whether it may be some other asset (?).
- *ticker*: Ticker of the asset.
- *type*: Sale (S), purchase (P), or exchange (E).
- *transaction_date*: Day on which the trade was executed.
- *amount*: Amount range for the value of the trade. If exact amount was reported, this will be the exact amount.
- *comment*: Any comments the filer has added. If no comments, this will be empty.
- *id*: If the trade was reported at an earlier date already, filers can amend or delete it. In this case, there will be an id (without further meaning). If the trade was reported for the first time, this will be empty.
- *filing_status*: If the trade was reported at an earlier date already, this indicates the reason why the trade is filed again (amendment or deletion). If the trade was reported for the first time, this will be empty.

<br>
If a report does not contain stock trades, the function does not return anything. If the report was handwritten and scanned, it will return a tibble with one row and the entry HANDWRITTEN for all variables.

<br><br>

#### `scrape_house_year()`

To scrape all House trades filed in a given year, you can use `scrape_house_year()`. The only argument is the year:

```
scrape_house_year(2022)

```

The exact runtime depends on your internet connection, but I would expect about 1-2h. The function returns a tibble with the same variables as `scrape_house()`, as well as the following four variables:
- *name*: Name of the filer
- *district*: Political district of the filer
- *disclosure_date*: Date the trade was disclosed
- *doc_link*: URL linking to the concerning report on the House webpage

<br><br>

#### `scrape_senate_year()`

The Senate publishes PTRs on [this](https://efdsearch.senate.gov/search/) page. This is a non-static webpage and the URL do not follow some predictable pattern as for the House, meaning that the scraping approach also works differently. To scrape all Senate trades filed over a certain period, use `scrape_senate_year()`. The arguments are the starting and ending date (format MM/DD/YYYY) and a version of Chromedriver that matches your installed version of Chrome:

```
scrape_senate_year(start_date = '01/01/2019', end_date = '12/31/2019', chromedriver = '119.0.6045.159')

```

<br>

Running this function will open a window in Google chrome. Since the function automatically controls the window, make sure not to close it until it has run. Scraping a window of one year takes about the same time as for the House. The function will return a tibble with the following variables

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

Note that unlike for the House, the Senate function returns no id/filing_status variables. Due to the way the trades are reported, it is possible to automatically correct for amended or deleted trades by the Senate - the function does that automatically. For the House, you must do it yourself. 

After you scraped house trades, take a look at trades where the id and filing_status variables are not empty. These refer to previously filed trades that were erroneous (and the amended entry is the corrected version) or they refer to previously filed trades that were mistakenly reported (and should not have been reported in the first place). Unfortunately, there is no way to automatically identify the previously filed trade these amendments or deletions refer to. To identify it, look for trades in the same stock, by the same person, as some earlier date than the trade that was marked as amended or deleted. For amendments, you should then drop the original trade and only keep the trade marked as amended. For deletions, you should drop both the original trade and the one marked as deletion.

<br><br>

<a name="data"></a>
## Data

This repo contains a cleaned-up [sample](https://github.com/tcweiss/congressional_insiders/tree/main/data) of congressional stock trades executed between 01-01-2019 and 31-07-2023. I compiled it as follows:
- Use the above functions to scrape all congressional trades disclosed between 2019 and 2023.
- Drop any trades with trading date before 01-01-2019. Some trades are reported with a (sometimes massive) delay, so some of the trades disclosed in 2019 have actually been executed earlier than that.
- Export the subset of handwritten/scanned entries that could not be scraped. Using the URLs returned by the function, I looked up all these reports on the webpages of the House and Senate and transcribed information on public stocks.
- Account for any amendments and deletions in scraped House trades (see the previous section for details). For each House trade marked as 'Amended' or 'Deleted', I looked for a corresponding trade of the same asset, by the same filer, and with the same transaction date, that was already disclosed at a previous date. For trades marked as 'Amended', I drop the identified trade that was filed at an earlier date (the erroneous version). For those marked as 'Deleted', both the identified and the newer trade with the marking are dropped. This is not necessary for Senate trades, as it can be done automatically by the scraping function.
- Drop all exchange transactions (that is, keep only sales and purchases). Exchanges occur as result of mergers or takeovers, in which case a persons's shares in company A are automatically converted to a certain amount of shares in company B. I dropped them since 1) they only accounted for some ~ 0.02% of all transactions, 2) it is not straightforward how to incorporate them in portfolio-based analyses, and 3) they do not occur on initiative of the filer, so they are unlikely to reflect any potential insider trading practices. 
- Look up all unique assets in Refiniv Eikon. Some assets are mistakenly marked as public stocks but are actually some other asset (e.g. ETFs, bonds, options, etc). Since I only focus on stocks, these are dropped. Sometimes companies are renamed, in which case the stock and the ticker may trade under a different name today than at the point of disclosure. In these cases, the old stock's name and ticker are replaced with the current (July/August 2023) version. Since different people often list the same stock in different ways, also standardized all stocks' names, (e.g. "Berkshire Hathaway B", "Berkshire Class B", "Berkshire Hathaway" are all renamed to "Berkshire Hathaway - Class B").
- Finally, I slightly adjusted the names of politicians to be in line with those listed in other databases (e.g. "Jim Inhofe" was changed to "James M Inhofe"). This means first and middle names might be differnt from those in reports. 



