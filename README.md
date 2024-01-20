Movie Recommendation Shiny App
-----------
This script is designed to recommend the five best movies based on user preferences, such as favorite movie or favorite actor/actress/director/genre, using content-based modeling in the Shiny app.

## Introduction

### App overview and how to use the app

All the data are stored in a file named "movies.csv". At the beginning of the Shiny app, we use the `source` function to run the code in "movie_recommend_model.R", which loads the data from "movies.csv" and implements the model for this movie recommendation Shiny app (note that it takes about 20-30 seconds to run "movie_recommend_model.R"). Upon opening the app, users are greeted with an engaging opening animation and selectable background music, offering various styles such as love, discovery, suspense, and joy to suit different moods. The music can be paused or resumed at any time. The app is divided into two main sections, accessible through tab panels at the top: "Recommend by Previously Watched Movie" and "Recommend by Genres/Actors/Directors". Recognizing that people seek movie recommendations in different ways, the app contains two models: one for suggesting movies similar to those previously enjoyed, and another for recommendations based on favorite genres, actors, or directors. Users can seamlessly switch between these models using the panels at the top.

After inputting their favorite movie or movie traits, users can get recommendations by clicking the "Recommend" button. Both recommendation methods run smoothly without any waiting time. We have also added a "random movie button" (luck draw) for users’ entertainment. It generates a random movie and provides a brief overview, with an option to learn more about the movie by clicking the 'Learn more' button.

Once the five movie recommendations are available, users are encouraged to click on each movie title for detailed information, presented in modal dialogs that include the director, cast, genre, release date, and more. Additionally, clickable green fonts provide links for further exploration. Specific details, such as the director, cast, genres, and homepage link (if applicable), are available to click on. Clicking on the director or cast name provides users with other movies by the same director or cast. Clicking on the genres suggests random movies in that specific genre for further exploration. Movie homepage links are also provided, with a note in the app notifying users that some homepages might be outdated due to dataset limitations. The background of the modal dialog is randomly chosen from a group of delightful images, enhancing the user experience. Finally, the Shiny app is accessed through a browser, and users need to press the stop button in RStudio to terminate the app after closing the browser tab. With these features, the app aims to provide an efficient and enjoyable movie recommendation experience.

## Methods / Implementation

### Data cleaning

The first step in our process is data cleaning. Initially, the script reads in "movies.csv" and defines a function `movie_top_n` to extract top movies based on parameters like popularity, revenue, vote average, and vote count. Additionally, it incorporates functions to remove Unicode characters and stop words from the movie data.

Subsequently, the script generates a subset of the movie dataset, named "movies_data", which includes the top 1000 movies. It then selects specific features such as genres, keywords, taglines, cast, and director. Text processing functions are applied to clean and preprocess this data.

The next phase involves transforming the character data into numeric values. For this purpose, we use a TF-IDF (Term Frequency-Inverse Document Frequency) vectorizer. The resulting TF-IDF matrix is instrumental in calculating the cosine similarity between movies. This calculation leads to the creation of a similarity matrix. The similarity matrix is a 1000x1000 symmetric matrix, containing the similarity scores of each movie with every other movie in the dataset.

### Models building
Our process begins with the movie recommendation function, designed to suggest films based on a user's input of their favorite movie. The function `recommend_movies` achieves this by identifying the closest match in the dataset, retrieving that movie's similarity score with other films, and then ranking these scores to select the six most similar movies. The core logic involves using a similarity score matrix for movies, selecting scores associated with a specific movie, sorting these scores to find the most similar movies, and finally returning the top recommendations, excluding the original movie from the list. The reason for retrieving the top six movies is to ensure the original movie, if it appears in the top ranks, is removed, leaving five distinct recommendations based on the user's previously enjoyed movies.

In addition to this, we have developed another model for movie recommendations based on genre, actor, and director. The function `recommend_movies_b` recommends movies based on a user’s combination of preferred genre, actor, and director. It treats the user's input as a new, hypothetical "dream movie" in the dataset, encompassing all the user's favorite characteristics. The model calculates TF-IDF vectors and assesses the similarity of the "dream movie" to all other movies in the dataset. To enhance run-time efficiency, instead of computing the entire 1001x1001 similarity matrix, which would take approximately 15 seconds, we calculate only the last column/row, representing the similarity scores of the "dream movie" to the other 1000 movies. We then rank these similarity scores and identify the top 5 movies with the highest similarity to the "dream movie". This approach enables us to recommend the five most suitable movies to users based on their preferred genre, actor, and director.


## Discussion & Conclusion

This script lays the groundwork for building a personalized movie recommendation system. It allows users to input their preferences, and in response, the system generates relevant movie suggestions based on textual features and similarity analysis. The script’s versatility makes it adaptable for various datasets and recommendation scenarios.

We have integrated the models into a Shiny app, enhancing it with additional features such as an opening animation, background music, and modal dialogs. These elements enable users to further explore the recommended movies, with the aim of creating a smooth, efficient, and entertaining experience within our movie recommendation Shiny app.

One potential area for improvement involves grouping similar actors and directors to refine the suggestion model. Additionally, we are considering the integration of filtering techniques with similarity score computation, forming a hybrid method to better match movies with users' inputs.

Regarding the Shiny app's technical aspects, we have noticed a warning regarding the large number of options in dropdown menus. However, we have chosen to ignore this warning as it does not significantly impact the model's ability to identify specific options and recommend movies accordingly. It's also worth noting that the Shiny app takes approximately 20 seconds to launch when run directly. This delay is due to the necessity of running the model first, which includes calculating the similarity matrix.
