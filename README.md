## *Insider Trading in The U.S. Congress - An Empirical Analysis*
#### Online Appendix

1. [ General Information ](#desc)
2. [ Code ](#code)
3. [ Data ](#data)

<br>
<a name="desc"></a>

## 1. General Information
This is the online appendix for *Insider Trading in The U.S. Congress - An Empirical Analysis*, a paper I wrote. This appendix contains R code for scraping stock trades reported by members of Congress, as well as a cleaned-up dataset of congressional stock trades executed between 01/2019 and 07/2023. Details can be found below.

Congress does not make it easy to investigate their transactions. If you think that any of the content here might be useful for you, please feel free to ue it. However, in case you plan to republish my data in some form, I kindly ask you to give proper credit by linking to this site.



<br><br>

<a name="code"></a>
## 2. Code

### Online

Since I deployed the web-app online, all you need is an internet connection. For best results, I recommend opening the app on a screen with at least 13''. Note that it may take a few second for the program to run. 

Link to app: [Investing@HSG](https://thomas-weiss.shinyapps.io/investing_at_hsg/)


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
## 3. Data
