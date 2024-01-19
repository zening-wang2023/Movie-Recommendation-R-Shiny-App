library(superml)
library(dplyr)
library(stringr)
library(proxy)
library(stringdist)
library(tm)
library(ggplot2)
library(tidyverse)
library(tidyr)
library(purrr)
library(stringi)
library(clue)
library(text2vec)

movies = read.csv("movies.csv")

######## Function to extract top n movie as base
movie_top_n = function(topn, pop_p, rev_p, vote_p, votec_p){
  movies_df_topn = movies |>
    mutate(overall_pop = pop_p*popularity+rev_p*(revenue-budget)/budget+vote_p*vote_average+votec_p*vote_count) |>
    arrange(desc(overall_pop)) |>
    slice_head(n = topn)
  return (movies_df_topn)
}
######## Remove unicode 
remove_unicode = function(text) {
  cleaned_text = gsub("\\\\u[a-zA-Z0-9]{4}", "", text)
  return(cleaned_text)
}
######## Remove stop words
remove_stopwords = function(text) {
  suppressWarnings({
    corpus = Corpus(VectorSource(text))
    corpus = tm_map(corpus, removePunctuation)
    corpus = tm_map(corpus, removeWords, stopwords("english"))
    cleaned_text = unlist(sapply(corpus, function(x) paste(unlist(x), collapse=" ")))
    return(cleaned_text)
  })
}

######## Select the top 1000 movies for recommendation
movies_data = movie_top_n(1000, 1, 0, 0, 0)
selected_features = c('genres', 'keywords', 'tagline', 'cast', 'director')
movies_data <- movies_data |>
  mutate(across(all_of(selected_features), ~ifelse(is.na(.), '', .))) |>
  mutate(combined = str_c(genres, keywords, tagline, cast, director, sep = " ")) |>
  mutate(combined = sapply(combined, remove_stopwords)) |>
  mutate(across(everything(), remove_unicode)) |>
  mutate(genres_cleaned = gsub("Science Fiction", "Science-Fiction", genres)) |>
  mutate(genres_cleaned = gsub(" ", ", ", genres_cleaned)) |>
  mutate(genres_cleaned = gsub("Science-Fiction", "Science Fiction", genres_cleaned)) |>
  mutate(cast_cleaned = sapply(strsplit(cast, " "), function(words) {
    short_words <- head(words, 6)  
    paired_words <- mapply(function(w1, w2) paste(w1, w2, sep = " "), 
                           short_words[c(TRUE, FALSE)],  
                           short_words[c(FALSE, TRUE)])  
    paste(paired_words, collapse = ", ")
  }))


############################################################################
### Recommend 5 best movies based on favorite movie

# Transform combined text data into a TF-IDF matrix for similarity computation
text_data <- movies_data$combined
tokens <- itoken(text_data, tokenizer = word_tokenizer, progressbar = FALSE)
vocab <- create_vocabulary(tokens)
vectorizer <- vocab_vectorizer(vocab)
dtm <- create_dtm(tokens, vectorizer)
tfidf_transformer <- TfIdf$new()
tfidf_matrix <- tfidf_transformer$fit_transform(dtm)
tfidf_matrix <- as.matrix(tfidf_matrix)

# Use the cosine similarity method to compute similarity scores between movies
similarity <- proxy::simil(tfidf_matrix, method = "cosine") %>% 
  as.matrix() %>%
  `rownames<-`(seq_len(nrow(.))) %>%
  `colnames<-`(seq_len(ncol(.)))
diag(similarity) <- 1

# Function to Recommend the 5 Best Movies Based on the Input of a Movie Name
recommend_movies = function(movie_name) {
  list_of_titles = movies_data$title
  distances = stringdist::stringdist(movie_name, list_of_titles)
  index_of_closest_match = which.min(distances)
  closest_match = list_of_titles[index_of_closest_match]
  index_of_movie = which(list_of_titles == closest_match)
  
  similarity_scores = as.data.frame(similarity[index_of_movie, ], stringsAsFactors = FALSE)
  names(similarity_scores) = "score"
  similarity_scores = similarity_scores |>
    arrange(desc(score)) |>
    # can change to desired recommendation count here
    head(6)
  
  recommended_movies = movies_data$title[as.numeric(rownames(similarity_scores))]
  recommended_movies = recommended_movies[!tolower(recommended_movies) %in% tolower(movie_name)]
  return(head(recommended_movies, 5))
}

recommend_movies_b = function(genre, actor, director) {
  new_observation = data.frame(
    input = paste(genre, actor, director, sep = " ")
  )
  movies_data_b = movies_data$combined
  movies_data_combine = c(movies_data_b,new_observation$input)
  
  # Transform combined text data into a TF-IDF matrix for similarity computation
  text_data <- movies_data_combine
  tokens <- itoken(text_data, tokenizer = word_tokenizer, progressbar = FALSE)
  vocab <- create_vocabulary(tokens)
  vectorizer <- vocab_vectorizer(vocab)
  dtm <- create_dtm(tokens, vectorizer)
  tfidf_transformer <- TfIdf$new()
  tfidf_matrix <- tfidf_transformer$fit_transform(dtm)
  
  # Use the cosine similarity method to compute similarity scores between movies
  tfidf_matrix <- as.matrix(tfidf_matrix)
  
  # Compute TF-IDF vector for the new observation (user's dream movie)
  new_observation_tfidf <- tfidf_matrix[1000:1001, ]
  new_observation_tfidf <- as.matrix(new_observation_tfidf)
  existing_movies_tfidf <- tfidf_matrix[-1001,]
  
  # Compute similarity scores between the new observation and all movies
  similarity_scores <- proxy::simil(new_observation_tfidf, existing_movies_tfidf, method = "cosine")
  similarity_scores = as.data.frame(similarity_scores[2, ], stringsAsFactors = FALSE)
  names(similarity_scores) = "score"
  similarity_scores$ID <- c(1:1000)
  similarity_scores = similarity_scores |>
    arrange(desc(score)) |>
    head(5)
  # print(similarity_scores$score)
  movie_l = c()
  for (i in similarity_scores$ID){
      movie_l = c(movie_l, movies_data$title[i])
  }
  # recommended_movies_b = movies_data$title[as.numeric(rownames(similarity_scores))]
  return(movie_l)
}


############################################################################
# Extract genres, directors, cast, titles
split_genres <- strsplit(movies_data$genres, " ")
genres <- unique(unlist(split_genres))
unique_genres <- sort(c(setdiff(genres, c("Science", "Fiction")), "Science fiction"))

unique_titles <- sort(unlist(movies_data$title))
#print(unique_titles)

unique_directors <- sort(unique(unlist(movies_data$director)))
#print(unique_directors)

split_cast <- strsplit(movies_data$cast_cleaned, ", ")
unique_cast <- sort(unique(unlist(split_cast)))
#print(unique_cast)


##########
# group by directors and extract their movies
director_works <- movies_data |>
  group_by(director) |>
  summarise(works = list(title), .groups = 'drop')


####################
# group by genres and extract their movies
movies_data_separated <- movies_data %>%
  separate_rows(genres_cleaned, sep = ",\\s*")
movies_by_genre <- movies_data_separated %>%
  group_by(genres_cleaned) %>%
  summarize(movies = list(title))

##################
# group by cast and extract their movies
cast_data_separated <- movies_data %>%
  separate_rows(cast_cleaned, sep = ",\\s*")
movies_by_cast <- cast_data_separated %>%
  group_by(cast_cleaned) %>%
  summarize(movies = list(title))

