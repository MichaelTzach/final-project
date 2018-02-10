if(!require(jsonlite)) {
  install.packages('jsonlite')
}
library(jsonlite)
if(!require(XML)) {
  install.packages('XML')
}
library(XML)

getTriviaFacts = function(minimumCount) {
  html2txt <- function(str) {
    xpathApply(htmlParse(str, asText=TRUE),
               "//body//text()", 
               xmlValue)[[1]] 
  }
  
  triviaFacts = c()
  
  while (length(triviaFacts) < minimumCount) {
    triviaQuestions = fromJSON("https://opentdb.com/api.php?amount=50&difficulty=hard&type=boolean")$results
    triviaQuestionsWithCorrectAnswers = triviaQuestions[triviaQuestions$correct_answer == "True", ]
    triviaFacts = append(triviaFacts, triviaQuestionsWithCorrectAnswers$question)  
  }
  
  triviaFacts = unlist(lapply(triviaFacts, html2txt))
  return(triviaFacts)
}

getWikipediaSummaries = function(minimumCount, startingTitle) {
  githubTitlesVector = c(startingTitle)
  
  isUniqueTitle = function(title) {
    return(title %in% githubTitlesVector == FALSE)
  }
  getRelatedTitlesToTitlesList = function(title) {
    relatedSitesAPIURL = paste0("https://en.wikipedia.org/api/rest_v1/page/related/", title)
    relatedTitles = fromJSON(relatedSitesAPIURL)$pages$title
    return(relatedTitles)
  }
  getWikipediaSummary = function(title) {
    summaryAPIURL = paste0("https://en.wikipedia.org/api/rest_v1/page/summary/", title)
    summaryJSON = fromJSON(summaryAPIURL)
    return(unlist(summaryJSON$extract))
  }
  
  while (length(githubTitlesVector) < minimumCount) {
    relatedTitles = unique(unlist(lapply(githubTitlesVector, getRelatedTitlesToTitlesList)))
    uniqueRelatedTitles = Filter(isUniqueTitle, relatedTitles)
    githubTitlesVector = append(githubTitlesVector, uniqueRelatedTitles)
  }

  wikipediaSummaries = unlist(lapply(githubTitlesVector, getWikipediaSummary))
  
  return(wikipediaSummaries)
}

wikipediaSummaries = getWikipediaSummaries(50, "Swift_(programming_language)")  
triviaFacts = getTriviaFacts(50)


