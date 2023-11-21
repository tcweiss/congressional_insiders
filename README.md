## *Insider Trading in The U.S. Congress - An Empirical Analysis*: Online Appendix

#### Content
1. [ Overview ](#overview)
2. [ Code ](#code)
3. [ Data ](#data)

<br>
<a name="overview"></a>

## 1. Overview
This is the online appendix for *Insider Trading in The U.S. Congress - An Empirical Analysis*, a paper I wrote. This site contains R code for scraping stock trades reported by members of Congress, as well as a clean dataset of congressional stock trades executed between 01/2019 and 07/2023. Details can be found below.

If you woudl like to reuse any of the content found here, please feel free to do so. In case you plan to republish my data, I only ask you to give proper credit by linking to this site. If you have questions or want to report bugs, you can reach me at tcweiss@protonmail.com.



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
