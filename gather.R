if(!require(jsonlite)) {
  install.packages('jsonlite')
}
library(jsonlite)

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



