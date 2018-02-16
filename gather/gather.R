if(!require(jsonlite)) {
  install.packages('jsonlite')
}
library(jsonlite)
if(!require(XML)) {
  install.packages('XML')
}
library(XML)
if(!require(httr)) {
  install.packages('httr')
}
library(httr)

getWikipediaSummaries = function(minimumCount, startingTitle) {
  githubTitlesVector = c(startingTitle)
  isUniqueTitle = function(title) {
    return(title %in% githubTitlesVector == FALSE)
  }
  
  relatedSitesAlreadyQueried = c()
  didNotGetRelatedTitlesForTitle = function(title) {
    return(title %in% relatedSitesAlreadyQueried == FALSE)
  }
  
  getRelatedTitlesToTitlesList = function(title) {
    relatedSitesAPIURL = paste0("https://en.wikipedia.org/api/rest_v1/page/related/", title)
    print(paste0("Getting related Wikipedia titles from: ", relatedSitesAPIURL))
    relatedTitles = fromJSON(relatedSitesAPIURL)$pages$title
    return(relatedTitles)
  }
  getWikipediaSummary = function(title) {
    summaryAPIURL = paste0("https://en.wikipedia.org/api/rest_v1/page/html/", title)
    print(paste0("Getting Wikipedia title html from: ", summaryAPIURL))
    html = GET(summaryAPIURL)
    document = htmlParse(html, asText=TRUE)
    plainText = xpathSApply(document, "//p", xmlValue)
    plainText = gsub("\\[\\d+\\]", '', plainText)
    plainText = paste(plainText, collapse = "\n")
    return(c(plainText))
  }
  
  safeGetWikipediaSummary = function(title) {
    result = tryCatch({
      getWikipediaSummary(title)
    }, error = function(e) {
      c()
    })
    return(result)
  }
  
  safeGetRelatedWikipedia = function(title) {
    result = tryCatch({
      getRelatedTitlesToTitlesList(title)
    }, error = function(e) {
      c()
    })
    return(result)
  }
  
  while (length(githubTitlesVector) < minimumCount) {
    titlesDidntSearchRelatedFor = Filter(didNotGetRelatedTitlesForTitle, githubTitlesVector)
    relatedSitesAlreadyQueried = append(relatedSitesAlreadyQueried, titlesDidntSearchRelatedFor)
    relatedTitles = unique(unlist(lapply(titlesDidntSearchRelatedFor, safeGetRelatedWikipedia)))
    uniqueRelatedTitles = Filter(isUniqueTitle, relatedTitles)
    githubTitlesVector = append(githubTitlesVector, uniqueRelatedTitles)
  }
  
  wikipediaSummaries = unlist(lapply(githubTitlesVector, safeGetWikipediaSummary))
  
  return(wikipediaSummaries)
}

getPokemonAbilities = function(minimumCount) {
  pokemonAbilities = c()
  morePagesAvailable = TRUE
  while(length(pokemonAbilities) < minimumCount && morePagesAvailable) {
    pageSize = min(50, minimumCount)
    page = 1 + length(pokemonAbilities) / pageSize
    pageSizeQueryParam = paste0("&pageSize=", toString(pageSize))
    pageQueryParam = paste0("&page=", toString(page))
    apiURL = "https://api.pokemontcg.io/v1/cards?supertype=Pok%C3%A9mon&abilityType=Pok%C3%A9mon%20Power"
    apiURL = paste0(apiURL, pageQueryParam)
    apiURL = paste0(apiURL, pageSizeQueryParam)
    
    print(paste0("Getting pokemon abilities from: ", apiURL))
    pokemonData = fromJSON(apiURL)$cards
    if (length(pokemonData$ability$text) < pageSize) {
      morePagesAvailable = FALSE
    }
    pokemonAbilities = append(pokemonAbilities, pokemonData$ability$text)
  }
  return(pokemonAbilities)
}


getTriviaFacts = function(minimumCount) {
  html2txt <- function(str) {
    xpathApply(htmlParse(str, asText=TRUE),
               "//body//text()", 
               xmlValue)[[1]] 
  }
  
  triviaFacts = c()
  
  isUniqueFact = function(fact) {
    return(fact %in% triviaFacts == FALSE)
  }
  
  while (length(triviaFacts) < minimumCount) {
    pageSize = min(50, minimumCount)
    pageSizeQueryParam = paste0("&amount=", toString(pageSize))
    apiURL = paste0("https://opentdb.com/api.php?difficulty=hard&type=boolean", pageSizeQueryParam)
    print(paste0("Getting facts from: ", apiURL))
    triviaQuestions = fromJSON(apiURL)$results
    triviaQuestionsWithCorrectAnswers = triviaQuestions[triviaQuestions$correct_answer == "True", ]$question
    uniqueAnswers = Filter(isUniqueFact, triviaQuestionsWithCorrectAnswers)
    triviaFacts = append(triviaFacts, triviaQuestionsWithCorrectAnswers)  
  }
  
  triviaFacts = unlist(lapply(triviaFacts, html2txt))
  return(triviaFacts)
}

wikipediaSummaries = getWikipediaSummaries(100, "Swift_(programming_language)")  
pokemonAbilities = getPokemonAbilities(100)
triviaFacts = getTriviaFacts(100)

write.csv(wikipediaSummaries, 'wikipediaSummaries.csv')
