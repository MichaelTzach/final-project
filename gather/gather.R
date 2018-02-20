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
    plainText = gsub("[[:space:]]", ' ', plainText)
    plainText = gsub("\"", '', plainText)
    plainText = paste(plainText, collapse = "")
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

getBBCArticls = function(minimumCount) {
  getArticleURLsFromFeed = function(feedURL) {
    print(paste0("Getting article URLs from feed from: ", feedURL))
    rssFeed = GET("http://feeds.bbci.co.uk/news/world/africa/rss.xml")
    doc = xmlParse(rssFeed, asText = TRUE)
    articleURLs = xpathSApply(doc, "//item/link",xmlValue)
    return(articleURLs)
  }
  getArticleContent = function(articleURL) {
    print(paste0("Getting BBC html from: ", articleURL))
    html = GET(articleURL)
    document = htmlParse(html, asText=TRUE)
    plainText = xpathSApply(document, "//div[@class='story-body__inner']/p",xmlValue)
    plainText = gsub("[[:space:]]", ' ', plainText)
    plainText = gsub("\"", '', plainText)
    plainText = paste(plainText, collapse = "")
    return(plainText)
  }
  
  bbcRSSFeeds = c('http://feeds.bbci.co.uk/news/world/europe/rss.xml', 'http://feeds.bbci.co.uk/news/world/middle_east/rss.xml', 'http://feeds.bbci.co.uk/news/video_and_audio/politics/rss.xml')
  
  bbcArticleURLs = unlist(lapply(bbcRSSFeeds, getArticleURLsFromFeed))
  bbcArticleURLs = head(bbcArticleURLs, minimumCount)
  bbcArticls = unlist(lapply(bbcArticleURLs, getArticleContent))
  bbcArticls = Filter(function(article) { return(nchar(article) > 700) }, bbcArticls)
  
  return(bbcArticls)
}

getTripAdvisorBlogPosts = function(minimumCount) {
  getBlogPostURLs = function() {
    travalStoriesListJSONURL = paste0("https://www.tripadvisor.com/blog/api/posts/?locale=en&posts_per_page=", toString(minimumCount * 3))
    print(paste0("Getting blog post URLs from: ", travalStoriesListJSONURL))
    travalStoriesListJSON = fromJSON(travalStoriesListJSONURL)
    travelBlogURLs = travalStoriesListJSON$data$posts$link
    return(travelBlogURLs)
  }
  getBlogPostContent = function(blogpostURL) {
    print(paste0("Getting blog post from: ", blogpostURL))
    html = GET(blogpostURL)
    document = htmlParse(html, asText = TRUE)
    plainText = xpathSApply(document, "//div[@class='ec__post-body']/p",xmlValue)
    plainText = gsub("[[:space:]]", ' ', plainText)
    plainText = gsub("\"", '', plainText)
    plainText = paste(plainText, collapse = "")
    return(plainText)
  }

  blogPostURLs = getBlogPostURLs()
  blogPosts = unlist(lapply(blogPostURLs, getBlogPostContent))
  blogPosts = rev(blogPosts[order(nchar(blogPosts))])
  blogPosts = head(blogPosts, minimumCount)

  return(blogPosts)
}

wikipediaSummaries = getWikipediaSummaries(50, "Swift_(programming_language)")  
tripAdvisorBlogPosts = getTripAdvisorBlogPosts(50)
bbcArticls = getBBCArticls(50)

write.csv(wikipediaSummaries, 'wikipediaSummaries.csv')
write.csv(tripAdvisorBlogPosts, 'tripAdvisorBlogPosts.csv')
write.csv(bbcArticls, 'bbcArticls.csv')
