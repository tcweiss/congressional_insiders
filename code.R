

##################################################################
##                     House Helper Function 1                  ##
##################################################################

# Function to extract stock transactions from periodic transactions reports
# (PTRs) that do not contain asset type abbreviations (common before 2019).
# Input is URL or path (if saved locally) pointing to PTR. Output is tibble with
# variables: 'owner', 'asset', 'ticker', 'type', 'transaction_date', 'amount',
# 'comment', 'id', 'filing_status'. If handwritten, returns tibble with one row
# and entry 'HANDWRITTEN' everywhere. If not handwritten but contents could not
# be read, returns tibble with one row and entry 'PARSING ERROR' everywhere.
# Otherwise, returns tibble with all transactions contained in report, i.e. stocks
# and any other assets.
house_helper_old <- function(path) {
  
  # Extract text.
  text <- pdf_text(path) 
  
  # Check if report is handwritten. If so, return tibble with one row and entry
  # 'HANDWRITTEN' everywhere.
  if(all(nchar(text)) == 0) {
    
    tibble("transaction_date" = 'HANDWRITTEN',
           "ticker" = 'HANDWRITTEN',
           "asset" = 'HANDWRITTEN',
           "type" = 'HANDWRITTEN',
           "amount" = 'HANDWRITTEN',
           "owner" = 'HANDWRITTEN',
           "comment" = 'HANDWRITTEN',
           "id" = 'HANDWRITTEN',
           "filing_status" = 'HANDWRITTEN') %>% 
      return()
    
    # If not handwritten but there aren't any asset type abbreviations (common for
    # reports before 2019), proceed here.
  } else if(!any(grepl('\\[[A-Z]{2}\\]', text, ignore.case = TRUE))) {
    
    # Store text line by line.
    text %<>% read_lines()
    
    # Try to remove metadata before and after table entries containing
    # transactions. If this results in an error, create tibble with one row and
    # 'PARSING ERROR' everywhere.
    from <- grep("Amount", text, ignore.case = TRUE)[1] + 2
    to <- if(any(grepl('Asset class details', text, ignore.case = TRUE))) {
      grep("Asset class details", text, ignore.case = TRUE)[1] - 2
    } else {
      grep("Initial public offerings", text, ignore.case = TRUE) - 2
    }
    
    text <- tryCatch(text[from:to],
                     error = function(e) {
                       return(tibble("transaction_date" = 'PARSING ERROR',
                                     "ticker" = 'PARSING ERROR',
                                     "asset" = 'PARSING ERROR',
                                     "type" = 'PARSING ERROR',
                                     "amount" = 'PARSING ERROR',
                                     "owner" = 'PARSING ERROR',
                                     "comment" = 'PARSING ERROR',
                                     "id" = 'PARSING ERROR',
                                     "filing_status" = 'PARSING ERROR'))},
                     finally={})
    
    # If object 'text' returned above contains a tibble, there was a parsing
    # error and the tibble is returned. Otherwise, 'text' contains a vector, so
    # there was no parsing error and the cleaning process continues below.
    if(is_tibble(text) == TRUE) {
      
      return(text)
      
    } else {
      
      # Define amount ranges (needed in the cleaning process).
      ranges <- '\\$1,001 - \\$15,000|\\$15,001 - \\$50,000|\\$50,001 - \\$100,000|\\$100,001 - \\$250,000|\\$250,001 - \\$500,000|\\$500,001 - \\$1,000,000|\\$1,000,001 - \\$5,000,000|\\$5,000,001 - \\$25,000,000|\\$25,000,001 - \\$50,000,000|Over \\$50,000,000| >\\$50,000,000|Over \\$1,000,000'
      ranges_first <- '(\\$1,001 - |\\$15,001 - |\\$50,001 - |\\$100,001 - |\\$250,001 - |\\$500,001 - |\\$1,000,001 - |\\$5,000,001 - |\\$25,000,001 - )'
      ranges_second <- '(\\$15,000|\\$50,000|\\$100,000|\\$250,000|\\$500,000|\\$1,000,000|\\$5,000,000|\\$25,000,000|\\$50,000,000)'
      
      # Vector 'text' now contains all table contents, with one vector entry per
      # line. The first step is to remove any lines that contain still table
      # headers. Headers occur at the top of every page, and are always spread
      # over two adjacent lines. When removing headers, it's important to make
      # sure that there are no empty lines immediately after a header, since
      # this would mess up the assignment of text elements to individual
      # transactions later on. Start by getting the finding indexes of all
      # vector elements containing table headers.
      index <- c(grep('^ID .* Amount$', text, ignore.case = TRUE), 
                 grep('Type .* Date', text, ignore.case = TRUE)) %>% sort()
      
      # If there are any lines containing headers, proceed to remove them here.
      if(length(index) != 0) {
        
        # Create empty vector for row indices to be dropped, and find number of
        # headers.
        drop <- c()
        z <- ceiling(length(index)/3)
        
        # Loop through all 2-index sequences (=headers) except the last. If a header
        # is followed by more than two empty rows, keep adding the next row to the
        # vector of row indices to be dropped.
        if(z != 1) {
          for(v in 1:(z-1)) {
            
            drop <- append(drop, index[(1:2+2*(v-1))])
            
            # Check if the next row after the header contains two dates separated by
            # a space, i.e. if the next line directly starts with a new transaction
            # (of any kind, not just stocks).  This happens rarely, but it would
            # mean that two transactions are not separated by an empty line. In that
            # case, replace the row corresponding to the last index with an empty
            # row and remove the index from the vector of rows to be dropped.
            if(str_detect(text[(last(drop) + 1)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
              text[last(drop)] <- ''
              drop <- drop[-length(drop)]
            } else {
              while(nchar(text[(last(drop) + 1)]) == 0 & !str_detect(text[(last(drop) + 2)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
                drop <- append(drop, (last(drop) + 1))
              }
            }
          }
        }
        
        # Append the last 2-index sequence.
        drop <- append(drop, index[(1:2+2*(z-1))])
        drop <- drop[!is.na(drop)]
        
        # If the end of the last header is the last row of the document, don't do
        # anything. If there are still rows after the last header, proceed here.
        if(length(text)-last(drop) > 0) {
          
          char_after <- text[c((last(drop)+1):length(text))] %>% 
            str_squish() %>% nchar() %>% sum()
          
          # If the rows after the header still contain characters
          # (=transactions), continue as before.
          if(char_after > 0) {
            
            if(str_detect(text[(last(drop) + 1)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
              
              text[last(drop)] <- ''
              drop <- drop[-length(drop)]
            } else {
              while(nchar(text[(last(drop) + 1)]) == 0 & !str_detect(text[(last(drop) + 2)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
                drop <- append(drop, (last(drop) + 1))
              }
              
            }
            
            # If the rows after the header don't contain characters (empty), add them
            # to the vector of rows to be dropped as well.
          } else {
            drop <- append(drop, (last(drop)+1):length(text))
          }
          
        }
        
        # Finally, drop all lines in 'drop' from the vector 'text' to remove any
        # headers. Vector 'text' will now only contain table contents, line by
        # line, starting with the first transaction and ending with the last
        # one. Lines of text referring to the same transaction are spread over
        # multiple adjacent rows. Lines of text referring to different
        # transactions are always separated by at least one empty row.
        text <- text[-drop]
        
      }
      
      # Remove any single letters occurring at the end a line (these are
      # from the checking boxes).
      text <- gsub('[ ]{1,15}[bcdefg]$', '', text)
      
      # Concatenate all lines of text elements that refer to the same
      # transaction. Each element of vector 'text' will now contain all text
      # referring to a given transaction listed in the table.
      result <- character()
      current <- ""
      for (element in text) {
        if (element != "") {
          current <- paste0(current, element)
        } else {
          if (nchar(current) > 0) {
            result <- c(result, current)
            current <- ""
          }
        }
      }
      if (nchar(current) > 0) {
        result <- c(result, current)
      }
      text <- result %>% str_squish()
      
      # Remove any potential stock indicators and '(partial) '. Also remove
      # whitespaces at beginning and end of each string.
      text %<>% 
        str_remove(., '\\[ST\\] ') %>%
        gsub('\\(partial\\) ', '', ., ignore.case = TRUE) %>% 
        str_trim()
      
      # Create tibble to store transactions data.
      data <- tibble("transaction_date" = rep(NA_character_, length(text)),
                     "ticker" = rep(NA_character_, length(text)),
                     "asset" = rep(NA_character_, length(text)),
                     "type" = rep(NA_character_, length(text)),
                     "amount" = rep(NA_character_, length(text)),
                     "owner" = rep(NA_character_, length(text)),
                     "comment" = rep(NA_character_, length(text)),
                     "id" = rep(NA_character_, length(text)),
                     "filing_status" = rep(NA_character_, length(text)))
      
      # Loop over all elements of vector 'text'.
      for(i in 1:length(text)) {
        
        amount_exac <- c()
        
        # Before extracting transaction information, one must make sure that
        # everything is in the right place. If the asset description is very
        # long, the second half of it may end up in between the range boundaries
        # (if the amount is large), or after it (if the amount is small). If
        # this is the case, extract everything until the first occurrence of 
        # ' S ', ' P ', or ' E ', and append the second part that is located in
        # between the range bounds.
        
        # Case 1: Amount is large and part of asset entry between bounds. This means
        # there won't be any range match. 
        if(!str_detect(text[i], ranges)) {
          
          # In rare cases, people enter the precise amount instead of a range, in
          # which case the above condition holds as well. However, one cannot use
          # pre-defined ranges to filter out information. Check for that using
          # below condition; if only range, proceed here.
          if(str_detect(text[i], ranges_first)) {
            
            # Find index of transaction type, then extract everything until but
            # excluding type (=first part of asset entry). Store first part and
            # remove it from original transaction entry.
            from_first <- 1
            to_first <- regexpr(' S | P | E ', text[i], ignore.case = TRUE)[1] 
            first <- substr(text[i], from_first, to_first)
            text[i] <- substr(text[i], to_first+1, nchar(text[i]))
            
            # Find indexes of string in between upper and lower bound of amount (=second
            # part of asset entry). Store second part and remove it from original
            # transaction entry.
            from_second <- regexpr(ranges_first, text[i])
            from_second <- from_second[1] + attr(from_second, "match.length")
            to_second <- regexpr(ranges_second, text[i])[1] - 1
            second <- substr(text[i], from_second, to_second)
            text[i] <- paste0(substr(text[i], 1, from_second-1), substr(text[i], to_second+1, nchar(text[i])))
            
            # Prepend fixed version of asset entry to transaction entry.
            text[i] <- paste0(first, second, text[i]) %>% str_trim()
            
            # If precise amount, find and store precise amount.
          } else {
            
            # Find and store precise amount.
            amount_exac_reg <- '\\$(\\d{1,3},)*(\\d{1,3})?\\.(\\d{1,2})'
            amount_exac <- str_extract(text[i], amount_exac_reg)
            
          }
          
        }
        
        # Case 2: Amount is small (and part of asset entry after amount). This
        # means there will be a range match, but the ticker comes after the
        # amount. Find ending index of amount and then find starting index of
        # first (and only) occurrence of letters in parentheses. If precise
        # amount, use corresponding regex.
        if(length(amount_exac) == 0) {
          
          amount_ends <- regexpr(ranges, text[i])[1] + attr(regexpr(ranges, text[i]), 'match.length')
          ticker_starts <- regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i])[1]
        } else {
          
          amount_ends <- regexpr(amount_exac_reg, text[i])[1] + attr(regexpr(amount_exac_reg, text[i]), 'match.length')
          ticker_starts <- regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i])[1]
        }
        
        
        if(amount_ends < ticker_starts) {
          
          # Get ending index of ticker.
          ticker_ends <- regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i])[1] + attr(regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i]), 'match.length') - 1
          
          # Extract everything from first character after amount ends and the
          # end of the ticker (=second part of asset entry). Store second part
          # and remove it from original transaction entry.
          from_second <- amount_ends + 1
          to_second <- ticker_ends
          second <- paste0(substr(text[i], from_second, to_second), ' ')
          text[i] <- paste0(substr(text[i], 1, from_second-1), substr(text[i], to_second+1, nchar(text[i])))
          
          # Find index of transaction type, then extract everything until but
          # excluding type (=first part of asset entry). Store first part and remove
          # it from original transaction entry.
          from_first <- 1
          to_first <- regexpr(' S | P | E ', text[i], ignore.case = TRUE)[1] 
          first <- substr(text[i], from_first, to_first)
          text[i] <- substr(text[i], to_first+1, nchar(text[i]))
          
          # Prepend fixed version of asset entry to transaction entry to get the
          # correct entry.
          text[i] <- paste0(first, second, text[i]) %>% str_squish()
          
        }
        
        # Each element in vector 'text' now contains all pieces of text
        # referring to a certain transactions, and the individual pieces always
        # occur in the same order. One can now extract the information step by
        # step.
        
        # ID. Extract any 10-digit number at the beginning of the transaction.
        # If it exists, this is the document ID of another filing, so the
        # transaction is either an amendment or a deletion of a previous
        # transaction.
        data$id[i] <- str_extract(text[i], '^\\d{10}')
        text[i] <- str_remove(text[i], '^\\d{10} ')
        text[i] %<>% 
          str_trim()
        
        # Ownership. Checks if the first two characters in a line are either SP, DC,
        # or nothing. In the latter case, ownership will be "Self".
        if(substr(text[i],1,3) %in% c('SP ','sP ','Sp ','sp ','DC ','dC ','Dc ','dc ', 'JT ', 'jT ', 'Jt ', 'jt ')) {
          data$owner[i] <- substr(text[i],1,2) %>% str_to_upper()
          text[i] <- substr(text[i], 4, nchar(text[i]))
        } else {
          data$owner[i] <- "Self"
        }
        text[i] %<>% 
          str_trim()
        
        # Asset. Extract everything until but excluding the first parenthesis "(".
        data$asset[i] <- sub('^(.*?) \\(.*', '\\1', text[i]) %>% 
          str_to_title()
        
        text[i] %<>% 
          gsub(sub('^(.*? )\\(.*', '\\1', .), '', .) %>% 
          str_trim()
        
        # Ticker. Extract all letters in the first set of parentheses, and convert to
        # upper case.
        data$ticker[i] <- str_extract(text[i], '\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)') %>% 
          str_remove_all(., '[\\(\\) ]') %>% 
          str_to_upper()
        
        text[i] %<>%          
          str_remove(., '(.*?)\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)') %>% 
          str_trim()
        
        # Type. Checks if the first letter is S, P, or E, and stores it accordingly.
        # If none of these apply, assign "ISSUE".
        if(substr(text[i],1,2) %in% c('S ', 's ', 'P ', 'p ', 'E ', 'e ')) {
          data$type[i] <- substr(text[i],1,1) %>% str_to_upper()
        } else {
          data$type[i] <- 'ISSUE'
        }
        text[i] %<>% 
          substr(., 3, nchar(.)) %>% 
          str_trim()
        
        # Transaction date. Extract the first set of one or two numbers followed by /
        # followed by one or two numbers followed by / followed by four numbers.
        data$transaction_date[i] <- str_extract(text[i], '\\d{1,2}/\\d{1,2}/\\d{4}')
        text[i] %<>% 
          str_remove_all(., '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}') %>%
          str_trim()
        
        # Amount. If precise amount, use that. Otherwise, find first and last
        # index of range match, then use it to extract amount.
        if(length(amount_exac) != 0) {
          data$amount[i] <- amount_exac
        } else {
          data$amount[i] <- str_extract(text[i], ranges) %>% str_trim()
        }
        
        # Filing status. If there is no id, leave this empty. If there is, look
        # for respective keyterms.
        if(is.na(data$id[i]) == FALSE) {
          id_index <- regexpr('\\: Amended|\\: Deleted', text[i], ignore.case = TRUE)
          data$filing_status[i] <- substr(text[i], id_index[1], id_index[1]+attr(id_index, "match.length")) %>% 
            str_remove(., '\\:') %>% 
            str_trim()
        } else {
          data$filing_status[i] <- NA_character_
        }
        
        # Comment. This is what follows "Description:", if the entry contains it.
        if(length(grep('Description\\:', text[i], ignore.case = TRUE)) == 1) {
          data$comment[i] <-  gsub('.*Description\\: ', '', text[i], ignore.case = TRUE) %>% str_to_sentence()
        } else {      
          data$comment[i] <- NA_character_
        }
      }
      
      # Return tibble with transactions.
      return(data)
      
    }
  }
}



##################################################################
##                     House Helper Function 2                  ##
##################################################################

# Function that extracts stock transactions from periodic transaction report if
# asset type abbreviations exist (2019 onwards). Input is URL or path (if saved
# locally) pointing to PTR. Output is tibble with variables: 'owner', 'asset',
# 'ticker', 'type', 'transaction_date', 'amount', 'comment', 'id',
# 'filing_status'. If handwritten, returns tibble with one row and entry
# 'HANDWRITTEN' everywhere. If not handwritten but contents could not be read,
# returns tibble with one row and entry 'PARSING ERROR' everywhere. Otherwise,
# returns tibble with all stock transactions contained in report.
house_helper_new <- function(path) {
  
  # Extract text.
  text <- pdf_text(path) 
  
  # Check if report is handwritten. If so, return tibble with one row and entry
  # 'HANDWRITTEN' everywhere.
  if(all(nchar(text)) == 0) {
    
    tibble("transaction_date" = 'HANDWRITTEN',
           "ticker" = 'HANDWRITTEN',
           "asset" = 'HANDWRITTEN',
           "type" = 'HANDWRITTEN',
           "amount" = 'HANDWRITTEN',
           "owner" = 'HANDWRITTEN',
           "comment" = 'HANDWRITTEN',
           "id" = 'HANDWRITTEN',
           "filing_status" = 'HANDWRITTEN') %>% 
      return()
    
    
    # If not handwritten but no stock transactions, return empty tibble.
  } else if(!any(grepl('\\[ST\\]', text, ignore.case = TRUE))) {
    
    tibble() %>% 
      return()
    
    # If not handwritten and there are stock transactions, extract them.
  } else {
    
    # Store text line by line.
    text %<>% read_lines()
    
    # Try to remove metadata before and after table entries containing
    # transactions. If this results in an error, create tibble with one row and
    # 'PARSING ERROR' everywhere.
    from <- grep("\\$200\\?", text, ignore.case = TRUE)[1] + 2
    to <- grep("\\* For the complete list of asset type abbreviations", text, ignore.case = TRUE) - 2
    text <- tryCatch(text[from:to],
                     error = function(e) {
                       return(tibble("transaction_date" = 'PARSING ERROR',
                                     "ticker" = 'PARSING ERROR',
                                     "asset" = 'PARSING ERROR',
                                     "type" = 'PARSING ERROR',
                                     "amount" = 'PARSING ERROR',
                                     "owner" = 'PARSING ERROR',
                                     "comment" = 'PARSING ERROR',
                                     "id" = 'PARSING ERROR',
                                     "filing_status" = 'PARSING ERROR'))},
                     finally={})    
    
    # If object 'text' returned above contains a tibble, there was a parsing
    # error and the tibble is returned. Otherwise, 'text' contains a vector, so
    # there was no parsing error and the cleaning process continues below.
    if(is_tibble(text) == TRUE) {
      
      return(text)
      
    } else {
      
      # Define amount ranges (needed in the cleaning process).
      ranges <- '\\$1,001 - \\$15,000|\\$15,001 - \\$50,000|\\$50,001 - \\$100,000|\\$100,001 - \\$250,000|\\$250,001 - \\$500,000|\\$500,001 - \\$1,000,000|\\$1,000,001 - \\$5,000,000|\\$5,000,001 - \\$25,000,000|\\$25,000,001 - \\$50,000,000|Over \\$50,000,000| >\\$50,000,000|Over \\$1,000,000'
      ranges_first <- '(\\$1,001 - |\\$15,001 - |\\$50,001 - |\\$100,001 - |\\$250,001 - |\\$500,001 - |\\$1,000,001 - |\\$5,000,001 - |\\$25,000,001 - )'
      ranges_second <- '(\\$15,000|\\$50,000|\\$100,000|\\$250,000|\\$500,000|\\$1,000,000|\\$5,000,000|\\$25,000,000|\\$50,000,000)'
      
      # Vector 'text' now contains all table contents, with one vector entry per
      # line. The first step is to remove any lines that contain still table
      # headers. Headers occur at the top of every page, and are always spread
      # over two adjacent lines. When removing headers, it's important to make
      # sure that there are no empty lines immediately after a header, since
      # this would mess up the assignment of text elements to individual
      # transactions later on. Start by getting the finding indexes of all
      # vector elements containing table headers.
      index <- c(grep('^ID .* Cap\\.$', text, ignore.case = TRUE), 
                 grep('Gains >$', text, ignore.case = TRUE),
                 grep('\\$200\\?$', text)) %>% sort()
      
      # If there are any lines containing headers, proceed here.
      if(length(index) != 0) {
        
        # Create empty vector for row indices to be dropped, and find number of
        # headers.
        drop <- c()
        z <- ceiling(length(index)/3)
        
        # Loop through all 3-index sequences (=headers) except the last. If a header
        # is followed by more than two empty rows, keep adding the next row to the
        # vector of row indices to be dropped.
        if(z != 1) {
          for(v in 1:(z-1)) {
            
            drop <- append(drop, index[(1:3+3*(v-1))])
            
            # Check if the next row after the header contains two dates separated by
            # a space, i.e. if the next line directly starts with a new transaction
            # (of any kind, not just stocks).  This happens rarely, but it would
            # mean that two transactions are not separated by an empty line. In that
            # case, replace the row corresponding to the last index with an empty
            # row and remove the index from the vector of rows to be dropped.
            if(str_detect(text[(last(drop) + 1)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
              text[last(drop)] <- ''
              drop <- drop[-length(drop)]
            } else {
              while(nchar(text[(last(drop) + 1)]) == 0 & !str_detect(text[(last(drop) + 2)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
                drop <- append(drop, (last(drop) + 1))
              }
            }
          }
        }
        
        # Append the last 3-index sequence.
        drop <- append(drop, index[(1:3+3*(z-1))])
        drop <- drop[!is.na(drop)]
        
        # If the end of the last header is the last row of the document, don't do
        # anything. If there are still rows after the last header, proceed here.
        if(length(text)-last(drop) > 0) {
          
          char_after <- text[c((last(drop)+1):length(text))] %>% 
            str_squish() %>% nchar() %>% sum()
          
          # If the rows after the header still contain characters
          # (transaction-data), continue as before.
          if(char_after > 0) {
            
            if(str_detect(text[(last(drop) + 1)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
              
              text[last(drop)] <- ''
              drop <- drop[-length(drop)]
            } else {
              while(nchar(text[(last(drop) + 1)]) == 0 & !str_detect(text[(last(drop) + 2)], '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}')) {
                drop <- append(drop, (last(drop) + 1))
              }
              
            }
            
            # If the rows after the header don't contain characters (empty), add them
            # to the vector of rows to be dropped as well.
          } else {
            drop <- append(drop, (last(drop)+1):length(text))
          }
          
        }
        
        # Finally, drop all lines in 'drop' from the vector 'text' to remove any
        # headers. Vector 'text' will now only contain table contents, line by
        # line, starting with the first transaction and ending with the last
        # one. Lines of text referring to the same transaction are spread over
        # multiple adjacent rows. Lines of text referring to different
        # transactions are always separated by at least one empty row.
        text <- text[-drop]
        
      }
      
      # Remove any single letters occurring at the end a line (these are
      # from the checking boxes).
      text <- gsub('[ ]{1,15}[bcdefg]$', '', text)
      
      # Concatenate all lines of text elements that refer to the same
      # transaction. Each element of vector 'text' will now contain all text
      # referring to a given transaction listed in the table.
      result <- character()
      current <- ""
      for (element in text) {
        if (element != "") {
          current <- paste0(current, element)
        } else {
          if (nchar(current) > 0) {
            result <- c(result, current)
            current <- ""
          }
        }
      }
      if (nchar(current) > 0) {
        result <- c(result, current)
      }
      text <- result %>% str_squish()
      
      # Fix cases of some inputs, then subset to observation containing
      # public stock transactions.
      text %<>% 
        gsub('\\[ST\\]', '\\[ST\\]', ., ignore.case = TRUE) %>% 
        gsub('Subholding of\\:', 'Subholding of\\:', ., ignore.case = TRUE)
      text <- text[grep('\\[ST\\]', text)]
      
      # Remove public stock indicator and '(partial) '. Also remove whitespaces
      # at beginning and end of each string.
      text %<>% 
        str_remove(., '\\[ST\\] ') %>%
        gsub('\\(partial\\) ', '', ., ignore.case = TRUE) %>% 
        str_trim()
      
      # Create tibble to store transactions data.
      data <- tibble("transaction_date" = rep(NA_character_, length(text)),
                     "ticker" = rep(NA_character_, length(text)),
                     "asset" = rep(NA_character_, length(text)),
                     "type" = rep(NA_character_, length(text)),
                     "amount" = rep(NA_character_, length(text)),
                     "owner" = rep(NA_character_, length(text)),
                     "comment" = rep(NA_character_, length(text)),
                     "id" = rep(NA_character_, length(text)),
                     "filing_status" = rep(NA_character_, length(text)))
      
      
      for(i in 1:length(text)) {
        
        amount_exac <- c()
        
        # Before extracting transaction information, one must make sure that
        # everything is in the right place. If the asset description is very
        # long, the second half of it may end up in between the range boundaries
        # (if the amount is large), or after it (if the amount is small). If
        # this is the case, extract everything until the first occurrence of 
        # ' S ', ' P ', or ' E ', and append the second part that is located in
        # between the range bounds.
        
        # Case 1: Amount is large and part of asset entry between bounds. This means
        # there won't be any range match. 
        if(!str_detect(text[i], ranges)) {
          
          # In rare cases, people enter the precise amount instead of a range,
          # so the above above condition will be true as well. However, one
          # cannot use pre-defined ranges to filter out information. Check for
          # that using below condition; if only range, proceed here.
          if(str_detect(text[i], ranges_first)) {
            
            # Find index of transaction type, then extract everything until but
            # excluding type (=first part of asset entry). Store first part and
            # remove it from original transaction entry.
            from_first <- 1
            to_first <- regexpr(' S | P | E ', text[i], ignore.case = TRUE)[1] 
            first <- substr(text[i], from_first, to_first)
            text[i] <- substr(text[i], to_first+1, nchar(text[i]))
            
            # Find indexes of string in between upper and lower bound of amount (=second
            # part of asset entry). Store second part and remove it from original
            # transaction entry.
            from_second <- regexpr(ranges_first, text[i])
            from_second <- from_second[1] + attr(from_second, "match.length")
            to_second <- regexpr(ranges_second, text[i])[1] - 1
            second <- substr(text[i], from_second, to_second)
            text[i] <- paste0(substr(text[i], 1, from_second-1), substr(text[i], to_second+1, nchar(text[i])))
            
            # Prepend fixed version of asset entry to transaction entry.
            text[i] <- paste0(first, second, text[i]) %>% str_trim()
            
            
            # If precise amount, find and store precise amount.
          } else {
            
            # Find and store precise amount.
            amount_exac_reg <- '\\$(\\d{1,3},)*(\\d{1,3})?\\.(\\d{1,2})'
            amount_exac <- str_extract(text[i], amount_exac_reg)
            
          }
          
        }
        
        # Case 2: Amount is small (and part of asset entry after amount). This
        # means there will be a range match, but the ticker comes after the
        # amount. Find ending index of amount and then find starting index of
        # first (and only) occurrence of letters in parentheses. If precise
        # amount, use corresponding regex.
        if(length(amount_exac) == 0) {
          
          amount_ends <- regexpr(ranges, text[i])[1] + attr(regexpr(ranges, text[i]), 'match.length')
          ticker_starts <- regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i])[1]
        } else {
          
          amount_ends <- regexpr(amount_exac_reg, text[i])[1] + attr(regexpr(amount_exac_reg, text[i]), 'match.length')
          ticker_starts <- regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i])[1]
        }
        
        
        if(amount_ends < ticker_starts) {
          
          # Get ending index of ticker.
          ticker_ends <- regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i])[1] + attr(regexpr('\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)', text[i]), 'match.length') - 1
          
          # Extract everything from first character after amount ends and the
          # end of the ticker (=second part of asset entry). Store second part
          # and remove it from original transaction entry.
          from_second <- amount_ends + 1
          to_second <- ticker_ends
          second <- paste0(substr(text[i], from_second, to_second), ' ')
          text[i] <- paste0(substr(text[i], 1, from_second-1), substr(text[i], to_second+1, nchar(text[i])))
          
          # Find index of transaction type, then extract everything until but
          # excluding type (=first part of asset entry). Store first part and remove
          # it from original transaction entry.
          from_first <- 1
          to_first <- regexpr(' S | P | E ', text[i], ignore.case = TRUE)[1] 
          first <- substr(text[i], from_first, to_first)
          text[i] <- substr(text[i], to_first+1, nchar(text[i]))
          
          # Prepend fixed version of asset entry to transaction entry to get the
          # correct entry.
          text[i] <- paste0(first, second, text[i]) %>% str_squish()
          
        }
        
        # Each element in vector 'text' now contains all pieces of text
        # referring to a certain transactions, and the individual pieces always
        # occur in the same order. One can now extract the information step by
        # step.
        
        # ID. Extract any 10-digit number at the beginning of the transaction.
        # If it exists, this is the document ID of another filing, so the
        # transaction is either an amendment or a deletion of a previous
        # transaction.
        data$id[i] <- str_extract(text[i], '^\\d{10}')
        text[i] <- str_remove(text[i], '^\\d{10} ')
        text[i] %<>% 
          str_trim()
        
        # Ownership. Checks if the first two characters in a line are either SP, DC,
        # or nothing. In the latter case, ownership will be "Self".
        if(substr(text[i],1,3) %in% c('SP ','sP ','Sp ','sp ','DC ','dC ','Dc ','dc ', 'JT ', 'jT ', 'Jt ', 'jt ')) {
          data$owner[i] <- substr(text[i],1,2) %>% str_to_upper()
          text[i] <- substr(text[i], 4, nchar(text[i]))
        } else {
          data$owner[i] <- "Self"
        }
        text[i] %<>% 
          str_trim()
        
        # Asset. Extract everything until but excluding the first parenthesis "(".
        data$asset[i] <- sub('^(.*?) \\(.*', '\\1', text[i]) %>% 
          str_to_title()
        
        text[i] %<>% 
          gsub(sub('^(.*? )\\(.*', '\\1', .), '', .) %>% 
          str_trim()
        
        # Ticker. Extract all letters in the first set of parentheses, and convert to
        # upper case.
        data$ticker[i] <- str_extract(text[i], '\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)') %>% 
          str_remove_all(., '[\\(\\) ]') %>% 
          str_to_upper()
        
        text[i] %<>%          
          str_remove(., '(.*?)\\([A-Za-z]+([.|$]?)([A-Za-z]*)\\)') %>% 
          str_trim()
        
        # Type. Checks if the first letter is S, P, or E, and stores it accordingly.
        # If none of these apply, assign "ISSUE".
        if(substr(text[i],1,2) %in% c('S ', 's ', 'P ', 'p ', 'E ', 'e ')) {
          data$type[i] <- substr(text[i],1,1) %>% str_to_upper()
        } else {
          data$type[i] <- 'ISSUE'
        }
        text[i] %<>% 
          substr(., 3, nchar(.)) %>% 
          str_trim()
        
        # Transaction date. Extract the first set of two numbers followed by /
        # followed by two numbers followed by / followed by four numbers.
        data$transaction_date[i] <- str_extract(text[i], '\\d{1,2}/\\d{2}/\\d{4}')
        text[i] %<>% 
          str_remove_all(., '\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}/\\d{1,2}/\\d{4}') %>%
          str_trim()
        
        # Amount. If precise amount, use that. Otherwise, find first and last
        # index of range match, then use it to extract amount.
        if(length(amount_exac) != 0) {
          data$amount[i] <- amount_exac
        } else {
          data$amount[i] <- str_extract(text[i], ranges) %>% str_trim()
        }
        
        # Filing status. If there is no id, leave this empty. If there is, look
        # for respective keyterms.
        if(is.na(data$id[i]) == FALSE) {
          id_index <- regexpr('\\: Amended|\\: Deleted', text[i], ignore.case = TRUE)
          data$filing_status[i] <- substr(text[i], id_index[1], id_index[1]+attr(id_index, "match.length")) %>% 
            str_remove(., '\\:') %>% 
            str_trim()
        } else {
          data$filing_status[i] <- NA_character_
        }
        
        # Comment. This is what follows "Description:", if the entry contains it.
        if(length(grep('Description\\:', text[i], ignore.case = TRUE)) == 1) {
          data$comment[i] <-  gsub('.*Description\\: ', '', text[i], ignore.case = TRUE) %>% str_to_sentence()
        } else {      
          data$comment[i] <- NA_character_
        }
      }
      
      # Return tibble with transactions.
      return(data)
      
    }
  }
}


#################################################################
##                      Scrape House Report                    ##
#################################################################

# Function to extract stock transactions from periodic transactions reports.
# Input is URL or path (if saved locally) pointing to PTR. Output is
# tibble with variables: 'owner', 'asset', 'ticker', 'type', 'transaction_date',
# 'amount', 'comment', 'id', 'filing_status', and 'is_stock'. If handwritten,
# returns tibble with one row and entry 'HANDWRITTEN' everywhere. If not
# handwritten but contents could not be read, returns tibble with one row and
# entry 'PARSING ERROR' everywhere. Otherwise, returns tibble with all
# transactions contained in report (stocks and any other assets).
scrape_house <- function(path) {
  
  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(magrittr),
      require(pdftools)))
  
  # Extract text.
  text <- pdf_text(path) 
  
  # If no security abbreviations, use function for old reports and add variable
  # showing that it's not clear whether asset is stock (or that report is handwritten).
  if (!any(grepl('\\[[A-Z]{2}\\]', text, ignore.case = TRUE))) {
    
    data <- house_helper_old(path) %>% 
      mutate("is_stock" = if_else(asset == "HANDWRITTEN", "HANDWRITTEN", "?"))
    
  # If there are security abbreviations, use function for old reports add variable
  # showing that asset is stock (or that report is handwritten).
  } else {
    
    data <- house_helper_new(path) %>% 
      mutate("is_stock" = if_else(asset == "HANDWRITTEN", "HANDWRITTEN", "Yes"))
    
  }
  return(data)
}



#################################################################
##                  Scrape House Reports by Year               ##
#################################################################

# Scrape all House trades for a given year. Input is year for which PTRs 
# should be scraped. Output is tibble with variables: 'name', 'district',
# 'disclosure_date', 'doc_link', 'owner', 'asset', 'ticker', 'type',
# 'transaction_date', 'amount', 'comment', 'id', 'filing_status', and
# 'is_stock'.
scrape_house_all <- function(year) {
  
  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(magrittr),
      require(janitor)))
  
  # Construct filename, download summary of reports filed for given year, and unzip file.
  filename <- paste0("house_", year, ".zip")
  url <- paste0("https://disclosures-clerk.house.gov/public_disc/financial-pdfs/", year, "FD.ZIP")
  download.file(url, destfile = filename)
  unzip(filename)
  
  # Import text file contained in zip, remove honorary prefix and subset to filing
  # types containing stock transactions (P for periodic transaction reports).
  docs <- read_delim(paste0(year, "FD.txt"), 
                     delim = "\t", 
                     escape_double = FALSE, 
                     trim_ws = TRUE) %>% 
    clean_names() %>% 
    select(-prefix) %>% 
    filter(filing_type == "P")
  unlink(c(filename, paste0(year, "FD.txt"), paste0(year, "FD.xml")))
  
  # Create empty tibble to store results and loop over all filings.
  trades <- tibble()
  for(i in 1:nrow(docs)) {
    
    doc <- docs[i,]
    
    # Download the file, then check then import the text from the pdf line by line.
    url <- paste0('https://disclosures-clerk.house.gov/public_disc/ptr-pdfs/', year, '/', doc$doc_id, '.pdf')
    trade <- scrape_house(url)
    
    # Add columns for doc_id, rep's name, district and disclosure date.
    trade %<>% 
      mutate("name" = str_squish(paste(doc$first, doc$last)),
             "district" = doc$state_dst,
             "disclosure_date" = doc$filing_date,
             "doc_link" = url)
    
    trades <- rbind(trades, trade)
    
  }
  
  # Return tibble with trades.
  return(trades)
  
}



##################################################################
##                   Scrape Senate Reports                      ##
##################################################################

# Function to scrape trades from senate webpage. Inputs are starting date
# and ending date (format MM/DD/YYYY), and chrome driver version (must match
# installed version of Google chrome). Output is tibble with variables:
# 'doc_link', 'name', 'disclosure_date', transaction_date, 'owner', 'ticker',
# 'asset', 'type', 'amount', 'comment'.
scrape_senate_all <- function(start_date, end_date, driver) {
  
  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(janitor),
      require(magrittr),
      require(rvest),
      require(jsonlite),
      require(htmltools),
      require(utils),
      require(RSelenium),
      require(xml2),
      require(netstat)))
  
  # Start Selenium browser.
  rD <- RSelenium::rsDriver(browser = "chrome",
                            chromever = driver,
                            port= free_port())
  
  # Store client in object.
  remDr <- rD[["client"]]
  
  # Go to senate disclosures webpage.
  remDr$navigate("https://efdsearch.senate.gov/search/home/")
  Sys.sleep(2)
  
  # Accept user agreement.
  userAgree <- remDr$findElement(using = 'xpath', value = '//*[(@id = "agree_statement")]')
  userAgree$clickElement()
  Sys.sleep(2)
  
  # Click checkboxes for senator and former senator.
  Sen <- remDr$findElement(using = 'id', value = 'filerTypeLabelSenator')
  Sen$clickElement()
  formerSen <- remDr$findElement(using = 'id', value = 'filerTypeLabelFormerSenator')
  formerSen$clickElement()
  
  # CLick PTR checkbox.
  filerTypes <- remDr$findElement(using = 'id', value = 'reportTypeLabelPtr')
  filerTypes$clickElement()
  
  # Enter starting and ending date.
  start <- remDr$findElement(using = 'id', value = 'fromDate')
  start$sendKeysToElement(list(start_date))
  end <- remDr$findElement(using = 'id', value = 'toDate')
  end$sendKeysToElement(list(end_date))
  
  # Search for reports.
  searchReport <- remDr$findElement(using = 'xpath', value = '//*[@id="searchForm"]/div/button')
  searchReport$submitElement()
  Sys.sleep(3)
  
  # Get number of pages with search results.
  source <- remDr$getPageSource()[[1]]
  pages <- read_html(source) %>%
    html_nodes(xpath = '//*[(@id = "filedReports_info")]') %>% 
    html_text() %>% 
    str_extract_all(' .{1,5} entries$') %>% 
    str_remove_all(',') %>% 
    str_extract_all('\\d{1,4}') %>% 
    as.numeric()
  pages <- ceiling(pages/25)
  i <- 1
  results <- tibble()
  
  # Unlike for the House, Senate URLs do not follow some predictable pattern.
  # Therefore, the first step is to loop over all pages in the search results
  # and extract the URLs leading to individual reports.
  while(i <= pages) {
    
    # Unless first page, go to next page and get source code.
    if(i != 1) {
      nextPage <- remDr$findElement(using = 'xpath', value = '//*[(@id = "filedReports_next")]') 
      nextPage$clickElement()
      Sys.sleep(4)
      source <- remDr$getPageSource()[[1]] 
    }
    
    # Extract URLs for reports.
    doc_link <- read_html(source) %>% 
      html_nodes(xpath = '//tbody') %>% 
      html_children() %>% 
      html_nodes(., 'a')
    doc_link <- bind_rows(lapply(xml_attrs(doc_link), function(x) data.frame(as.list(x), stringsAsFactors=FALSE)))['href'] %>% 
      as_tibble() %>% 
      mutate(href = paste0('https://efdsearch.senate.gov', href))
    doc_link <- as.vector(doc_link$href)
    
    # Extract first names.
    first <- read_html(source) %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]') %>% 
      html_text() %>% 
      str_trim() %>% 
      str_to_title()
    
    # Extract last names.
    last <- read_html(source) %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]') %>% 
      html_text() %>% 
      str_trim() %>% 
      str_to_title()
    
    # Extract disclosure dates.
    disclosure_date <- read_html(source) %>% 
      html_nodes(css = '.noWrap~ td+ td') %>%
      html_text() %>% 
      str_trim()
    
    # Append to tibble with previous search results. 
    result <- tibble("doc_link" = doc_link,
                     "first" = first,
                     "last" = last,
                     "disclosure_date" = disclosure_date) %>% 
      mutate("name" = paste(first, last)) %>% 
      select(doc_link, name, disclosure_date)
    results <- rbind(results, result)
    
    # Increment index.
    i <- i+1
    
  }
  
  # Next, we can loop over all URLs pointing to the individual reports to scrape
  # individual trades.
  trades <- tibble("doc_link" = c(),
                   "asset" = c(),
                   "ticker" = c(),
                   "owner" = c(),
                   "type" = c(),
                   "transaction_date" = c(),
                   "amount" = c(),
                   "comment" = c(),
                   "name" = c(),
                   "disclosure_date" = c(),
                   "asset_type" = c(),
                   "refer_date" = c(),
                   "amendment" = c()) 
  
  for(i in 1:nrow(results)) {
    
    # Go to page.
    remDr$navigate(results$doc_link[i])
    Sys.sleep(4)
    
    # Get source code.
    source <- remDr$getPageSource()[[1]] %>% 
      read_html()
    
    # Extract variables.
    transaction_date <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]') %>% 
      html_text2()
    
    owner <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 3) and parent::*)]') %>% 
      html_text2()
    
    ticker <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 4) and parent::*)]') %>% 
      html_text2()
    
    asset <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 5) and parent::*)]') %>% 
      html_text2()
    
    asset_type <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 6) and parent::*)]') %>% 
      html_text2()
    
    type <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 7) and parent::*)]') %>% 
      html_text2()
    
    amount <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 8) and parent::*)]') %>% 
      html_text2()
    
    comment <- source %>% 
      html_nodes(xpath = '//td[(((count(preceding-sibling::*) + 1) = 9) and parent::*)]') %>% 
      html_text2()
    
    # Extract info on amendment.
    title <- source %>% 
      html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "mb-2", " " ))]') %>% 
      html_text2()
    refer_date <- str_extract(title, '\\d{1,2}/\\d{1,2}/\\d{4}')
    amendment <- str_extract(title, '\\(Amendment \\d\\)$') %>% str_extract('\\d')
    
    # If handwritten, append empty tibble.
    if(length(transaction_date) == 0) {
      
      trades <- rbind(trades, tibble("doc_link" = results$doc_link[i],
                                     "asset" = "HANDWRITTEN",
                                     "ticker" = "HANDWRITTEN",
                                     "owner" = "HANDWRITTEN",
                                     "type" = "HANDWRITTEN",
                                     "transaction_date" = "HANDWRITTEN",
                                     "amount" = "HANDWRITTEN",
                                     "comment" = "HANDWRITTEN",
                                     "name" = results$name[i],
                                     "disclosure_date" = results$disclosure_date[i],
                                     "asset_type" = "HANDWRITTEN",
                                     "refer_date" = "HANDWRITTEN",
                                     "amendment" = "HANDWRITTEN"))
      
      # If not handwritten, determine number of transactions, append trades of current page.
    } else {
      
      n_trans <- length(transaction_date)
      trades <-  rbind(trades, tibble("doc_link" = rep(results$doc_link[i], n_trans),
                                      "asset" = asset,
                                      "ticker" = ticker,
                                      "owner" = owner,
                                      "type" = type,
                                      "transaction_date" = transaction_date,
                                      "amount" = amount,
                                      "comment" = comment,
                                      "name" = rep(results$name[i], n_trans),
                                      "disclosure_date" = rep(results$disclosure_date[i], n_trans),
                                      "asset_type" = asset_type,
                                      "refer_date" = rep(refer_date, n_trans),
                                      "amendment" = rep(amendment, n_trans)))
      
    }
  }
  
  # We also need to adjust for amendments. If there are multiple filing referring to
  # the same date, only keep the latest amendment. First find reports with
  # amendments and determine the latest one.
  x <- trades %>% 
    mutate(amendment = if_else(is.na(amendment) == TRUE, "0", amendment)) %>% 
    filter(amendment != "HANDWRITTEN") %>% 
    mutate(amendment = as.integer(amendment)) %>% 
    group_by(name, refer_date) %>% 
    summarize("latest" = max(amendment)) %>% 
    ungroup() %>% 
    filter(latest != 0)
  
  # Next, exclude all reports which are not the latest version.  
  for(i in 1:nrow(x)) {
    
    trades %<>% 
      filter(!(name == x$name[i] & refer_date == x$refer_date[i] & amendment != x$latest[i]))
    
  }
  
  # Drop refer_date and amendment, make sure all variables are clean, include only
  # stocks and handwritten reports, remove exchange transactions and non-stock assets.
  trades %<>%
    select(-c(refer_date, amendment)) %>% 
    mutate(disclosure_date = as.Date(disclosure_date, format = "%m/%d/%Y"),
           owner = str_trim(owner),
           ticker = str_trim(ticker),
           asset = str_trim(asset_name),
           asset_type = str_trim(asset_type),
           type = str_trim(type),
           amount = str_trim(amount),
           comment = str_trim(comment)) %>% 
    filter(asset_type %in% c("Stock", "HANDWRITTEN")) %>% 
    filter(type != "Exchange") %>% 
    filter(asset_type == "Stock") %>% 
    select(-asset_type)
  
  # Return tibble with all trades.
  return(trades)
  
}
