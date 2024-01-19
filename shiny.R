library(shiny)
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
library(shinyWidgets)
library(shinythemes)

options(shiny.launch.browser = .rs.invokeShinyWindowExternal) 
options(browser = NULL)

source("movie_recommend_model.R")

# Define the UI
ui <- fluidPage(
  # White cover layer
  div(id = "loading-cover",
      style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background-color: white; z-index: 2000;"
  ),
  
 # Adding the Random Movie button at the bottom left
  div(
    actionButton("random_movie_btn", "Lucky Draw", class = "btn btn-primary"),
    style = "position: fixed; left: 10px; bottom: 10px; z-index: 10; font-family: 'Comic Sans MS', cursive, sans-serif; color: white; background-color: #7F7FBF; border-color: #ADD8E6; border-radius: 15px; padding: 10px 20px; box-shadow: 3px 3px 5px rgba(0,0,0,0.3); font-size: 16px; font-weight: bold;"
  ),
  
  # Splash screen (with GIF)
  div(id = "splash-screen",
      img(src = "https://i.gifer.com/3Of13.gif", height = '100%', width = '100%'),
      style = "position: fixed; top: 0; left: 0; width: 100%; height: 130%; z-index: 1000; display: flex; align-items: center; justify-content: center;"
  ),
  
  tags$head(
    tags$script(HTML("
    $(document).on('shiny:connected', function(event) {
      var gifLoaded = false;

      // Handling when the GIF is loaded
      var gif = new Image();
      gif.onload = function() {
        gifLoaded = true;
        $('#loading-cover').fadeOut(500); // Fade out the white cover layer when the GIF is loaded
      };
      gif.src = 'https://i.gifer.com/3Of13.gif';

      // Fade out the GIF after a total of 3.5 seconds
      setTimeout(function() {
        $('#splash-screen').fadeOut(500);
      }, 3500); // Set the timer to 3.5 seconds
    });
  ")),
    
    # change action_button_bymovie color
    tags$style(HTML("
      .sidebar {
        background-image: url('https://img.freepik.com/free-vector/question-marks-background_78370-2896.jpg?w=1800&t=st=1702798643~exp=1702799243~hmac=20d49ef38ab2293dbcce6d0221f5e3137c93fcad6b0cfb933655081bcbd06998');
        background-size: cover; /* Cover the entire page */
      }    
      #action_button_bymovie {
        background-color: #7F7FBF; 
        color: white; /* White text */
        padding: 10px 20px; /* Some padding */
        border: none; /* No border */
        border-radius: 5px; /* Rounded corners */
        cursor: pointer; /* Pointer/hand icon */
        font-size: 16px; /* Larger font size */
        transition: background-color 0.3s; /* Smooth transition for hover effect */
      }
      #action_button_bymovie:hover {
        background-color: #ADD8E6; 
      }
    ")),
    # change action_button_bygenre color
    tags$style(HTML("
      #action_button_bygenre {
        background-color: #7F7FBF; 
        color: white; /* White text */
        padding: 10px 20px; /* Some padding */
        border: none; /* No border */
        border-radius: 5px; /* Rounded corners */
        cursor: pointer; /* Pointer/hand icon */
        font-size: 16px; /* Larger font size */
        transition: background-color 0.3s; /* Smooth transition for hover effect */
      }
      #action_button_bygenre:hover {
        background-color: #ADD8E6; 
      }
    ")),
    
    # change title + don't change color
    # Include the Google Font
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Great+Vibes&display=swap"),
    tags$style(HTML("
      .navbar .navbar-brand {
        font-family: 'Great Vibes', cursive; /* Apply the font */
        color: white !important;
        font-size: 24px; /* Font size */
        padding: 10px 15px; /* Padding around the text */
        line-height: 50px; /* Adjust line height for vertical centering */
        display: inline-block;
        vertical-align: middle;
      }
      .navbar { 
        height: 70px; /* Adjust the navbar height */
      }
    ")),
    # By tabPanel color change
    tags$style(HTML("
  /* Style for normal state */
  .nav > li > a {
    color: white !important; /* White color in normal state */
  }

  /* Style for hover state */
  .nav > li > a:hover {
    color: #7F7FBF !important; /* Change to light blue-purple when hovered */
  }

  /* Style for active state */
  .nav > li.active > a, 
  .nav > li.active > a:focus, 
  .nav > li.active > a:hover {
    color: #7F7FBF !important; /* Change to light blue-purple when active */
    background-color: transparent !important; /* Optional: makes background transparent */
  }
"))
  ),
  
  ##### Audio 
  tags$head(
    tags$style(HTML("
      .music-control-container {
        position: fixed;
        right: 20px;
        bottom: 60px;
        z-index: 1000;
      }
      .select-music {
        margin-bottom: 5px;
      }
      .select-music label {
        color: white;  /* Change label color to white */
      }
    ")),
    tags$script(HTML("
      $(document).on('shiny:sessioninitialized', function(event) {
        setTimeout(function() { 
          $('#audio-player').prop('volume', 0.25); 
        }, 1000);
      });
    "))
  ),
  
  # Container for music controls
  div(class = "music-control-container",
      # Custom label and selectInput without a label
      div(class = "select-music",
          tags$label("Music Box", style = "color: white;"),
          selectInput("music_choice", label = NULL,
                      choices = c("Love" = "love-in-paris.mp3",
                                  "Discovery" = "cornfield-chase.mp3",
                                  "Suspense" = "suspense-piano.mp3",
                                  "Joy" = "suntan-oil.mp3"),
                      selected = NULL)
      ),
      
      # Audio player with an ID for easy JavaScript targeting
      uiOutput("music_player")
  ),
  
  
  
  # NavbarPage
  navbarPage(
    title = "Movie Recommendation System",
    theme = shinytheme("flatly"),
    
    tabPanel("By Previously Watched Movie",
             fluidPage(
               setBackgroundImage(
                 src = "https://media.gq.com/photos/5a281accaf51350755188d9f/16:9/w_1920,c_limit/2017_12_Best%20Movies%202017_16x9.jpg"),
               
               titlePanel(h2("Recommend by Previously Watched Movie", style = "color: white; text-shadow: 2px 2px 4px #000000;")),
               
               sidebarPanel(
                 selectizeInput("fav_movie", 
                                HTML('<span style="color: black; text-shadow: 2px 2px 4px white;">What is your favorite movie?</span>'),
                                choices = unique_titles, 
                                options = list(maxOptions = 1000),
                                selected = NULL),
                 actionButton("action_button_bymovie", "Recommend"),
                 class = "sidebar" 
               ),
               
               mainPanel(
                 # ConditionalPanel that becomes visible after the button is clicked
                 conditionalPanel(
                   condition = "input.action_button_bymovie > 0",
                   uiOutput("movie_links_bymovie")
                   
                 )
               )
             )
    ),
    
    tabPanel("Specify Genres/Actors/Directors",
             fluidPage(
               setBackgroundImage(
                 src = "https://media.gq.com/photos/5a281accaf51350755188d9f/16:9/w_1920,c_limit/2017_12_Best%20Movies%202017_16x9.jpg"),
               
               titlePanel(h2("Recommend by Genres/Actors/Directors", style = "color: white; text-shadow: 2px 2px 4px #000000;")),
               
               sidebarPanel(
                 selectizeInput("actor_input", 
                                HTML('<span style="color: black;text-shadow: 2px 2px 4px white;">Who is your favorite actor/actress?</span>'),
                                choices = unique_cast, 
                                options = list(maxOptions = 1500),
                                selected = NULL),
                 selectInput("genre_input", HTML('<span style="color: black;text-shadow: 2px 2px 4px white;">What is your favorite genre?</span>'), choices = unique_genres),
                 selectInput("director_input", HTML('<span style="color: black;text-shadow: 2px 2px 4px white;">Who is your favorite director?</span>'), choices = unique_directors),
                 actionButton("action_button_bygenre", "Recommend"),
                 class = "sidebar"
               ),
               
               mainPanel(
                 # ConditionalPanel that becomes visible after the button is clicked
                 conditionalPanel(
                   condition = "input.action_button_bygenre > 0",
                   uiOutput("movie_links_bygenre")
                 )
               )
             )
    )
  )
  )

# Define the server logic

server <- function(input, output, session) {
  
  # Initialize an empty data frame to store recommendations
  recommendations_df_bymovie <- reactiveVal(data.frame())
  # Initialize an empty data frame to store recommendations
  recommendations_df_bygenre <- reactiveVal(data.frame())
  # 'learn more' reaction 
  random_movie_info <- reactiveVal()
  
  # Observe event for the "Recommend" button in the "Previously Watched Movies" tab
  observeEvent(input$action_button_bymovie, {
    req(input$fav_movie)  # Ensure that fav_movie is not NULL
    recommended_titles <- recommend_movies(input$fav_movie)
    recommendations_df_bymovie(data.frame(title = recommended_titles))
  })
  

  # Observe event for the "Recommend" button in the "Specify Genres/Actors/Directors" tab
  observeEvent(input$action_button_bygenre, {
    req(input$actor_input, input$genre_input, input$director_input)  # Ensure inputs are not NULL
    recommended_titles <- recommend_movies_b(input$genre_input, input$actor_input, input$director_input)
    recommendations_df_bygenre(data.frame(title = recommended_titles))
  })

  
 # random_movie_btn info
  observeEvent(input$random_movie_btn, {
    # Ensure movies_data is available
    req(movies_data)
    
    # Select a random movie
    random_movie <- sample_n(movies_data, 1)
    random_movie_info(random_movie)
    movie_title <- random_movie$title
    movie_tagline <- random_movie$tagline
    
    # Show the modal dialog with movie details
    showModal(modalDialog(
      title = tags$p("Lucky! Lucky! Here's a special movie for you:", 
             style = "text-shadow: 3px 3px 6px #000000; font-size: 22px;"),
      tags$div(
        tags$span(style = "font-weight: bold; color: #FFFFF0; font-size: 28px;text-shadow: 3px 3px 6px #000000;", movie_title),
        tags$br(),
        tags$span(style = "color: #FFFFF0; font-style: italic; font-size: 20px;text-shadow: 3px 3px 6px #000000;", movie_tagline)
      ),
      actionLink("learn_more_btn", "Learn More", class = "btn btn-primary", style = "font-size: 12px;background-color: #FFFFF0; color: black;border: none;"),
      footer = modalButton("Close"),
      size = "m",
      easyClose = FALSE,
      tags$style(HTML("
            .modal-content {
                background-image: url('https://www.brussels.be/sites/default/files/styles/article_image__hd_/public/cinema2.jpg?itok=zLqlwHnh');
                background-size: cover;
                color: #fff;
            }
            .modal-body {
                background: rgba(127, 127, 191, 0.8);  /* Set modal body background to purple (#7F7FBF) with 50% transparency */
            }
            .modal-footer .btn { /* Targeting the modal button */
            background-color: #FAFAD2; 
            color: black; 
            text-shadow: 2px white;
            padding: 10px 20px; 
            border: none; /* No border */
            border-radius: 5px; /* Rounded corners */
            cursor: pointer; /* Pointer/hand icon */
            font-size: 16px; /* Larger font size */
          }
           .modal-footer .btn:hover {
           background-color: #FFFFFF; 
          }
        "))
    ))
  })

  # learn more reaction
  observeEvent(input$learn_more_btn, {
    showModal(modalDialog(
      title = tags$p(style = "font-size: 28px;color: #FFFFF0;font-weight: bold;text-shadow: 3px 3px 6px #000000;", random_movie_info()$title[1]),
      tags$p(style = "font-size: 18px;color: #FFFFF0;font-style: italic;text-shadow: 3px 3px 6px #000000;", random_movie_info()$release_date[1]),
      tags$p(style = "font-size: 16px;color: #FFFFF0;text-shadow: 3px 3px 6px #000000;", random_movie_info()$overview[1]),
      easyClose = FALSE,
      footer = modalButton("Close"),
      size = "m",
      tags$style(HTML("
            .modal-content {
                background-image: url('https://www.brussels.be/sites/default/files/styles/article_image__hd_/public/cinema2.jpg?itok=zLqlwHnh');
                background-size: cover;  /* Cover the entire modal area */
                color: #fff;  /* Change text color if needed */
            }
            .modal-body {
                background: rgba(127, 127, 191, 0.8);  /* Make modal body background purple for better readability */
            }
            
            .modal-footer .btn { /* Targeting the modal button */
                background-color: #FAFAD2; 
                color: black; /* black text */
                text-shadow: 2px white;
                padding: 10px 20px; /* Some padding */
                border: none; /* No border */
                border-radius: 5px; /* Rounded corners */
                cursor: pointer; /* Pointer/hand icon */
                font-size: 16px; /* Larger font size */
            }
            .modal-footer .btn:hover {
                background-color: #FFFFFF; 
            }
        "))
    ))
  })
  
  
  ### Audio Player Output
  output$music_player <- renderUI({
    req(input$music_choice)
    tags$audio(
      src = input$music_choice,
      type = "audio/mpeg",
      controls = TRUE,
      autoplay = TRUE,  # Set to TRUE if you want the music to play automatically when selected
      loop = TRUE
    )
  })
  
  
  output$movie_links_bymovie <- renderUI({
    req(recommendations_df_bymovie())  # Ensure that recommendations_df is not NULL
    tags$ul(
      style = "list-style-type: none; padding: 0; background: url('https://happy-families.s3.ap-southeast-2.amazonaws.com/s3fs-public/styles/max_1300x1300/public/2022-10/AdobeStock_312349880%20%281%29.jpeg?itok=7BxOIvWX') no-repeat center center fixed; background-size: cover; font-family: Arial, sans-serif;",
      lapply(recommendations_df_bymovie()$title, function(movie_name) {
        movie_info <- movies_data[movies_data$title == movie_name, ]
        js_safe_movie_name <- shQuote(movie_name, type = "sh")
        tags$li(
          style = "margin-bottom: 8px; padding: 8px; background-color: rgba(255, 255, 255, 0.8); border-radius: 5px;",
          h3(
            a(href="#", 
              style = "text-decoration: none; color: inherit;",
              onclick = sprintf("Shiny.setInputValue('selected_movie', %s, {priority: 'event'})", js_safe_movie_name),
              span(style = "color: #800080; font-size: 20px; font-weight: bold;", movie_info$title), 
              span(style = "color: black; font-size: 16px; font-style: italic;", movie_info$tagline)  
            )
          )
        )
      })
    )
  })
  
  output$movie_links_bygenre <- renderUI({
    req(recommendations_df_bygenre())  # Ensure that recommendations_df is not NULL
    tags$ul(
      style = "list-style-type: none; padding: 0; background: url('https://happy-families.s3.ap-southeast-2.amazonaws.com/s3fs-public/styles/max_1300x1300/public/2022-10/AdobeStock_312349880%20%281%29.jpeg?itok=7BxOIvWX') no-repeat center center fixed; background-size: cover; font-family: Arial, sans-serif;",
      lapply(recommendations_df_bygenre()$title, function(movie_name) {
        movie_info <- movies_data[movies_data$title == movie_name, ]
        js_safe_movie_name <- shQuote(movie_name, type = "sh")
        tags$li(
          style = "margin-bottom: 8px; padding: 8px; background-color: rgba(255, 255, 255, 0.8); border-radius: 5px;",
          h3(
            a(href="#", 
              style = "text-decoration: none; color: inherit;",
              onclick = sprintf("Shiny.setInputValue('selected_movie', %s, {priority: 'event'})", js_safe_movie_name),
              span(style = "color: #800080; font-size: 20px; font-weight: bold;", movie_info$title), 
              span(style = "color: black; font-size: 16px; font-style: italic;", movie_info$tagline)  
            )
          )
        )
      })
    )
  })
  
  
  # Observe when a movie link is clicked and display a modal dialog with movie details
  observeEvent(input$selected_movie, {
    # Find the movie information based on the selected movie title
    movie_info <- movies_data[movies_data$title == input$selected_movie, ]
    # create links for genres 
    genres <- unlist(strsplit(movie_info$genres_cleaned, ",\\s*"))
    genre_links <- lapply(seq_along(genres), function(idx) {
      genre_link <- actionLink(inputId = paste0("genre_", gsub("[^A-Za-z0-9]", "", genres[idx])), label = genres[idx])
      # Add a comma and space except for the last genre
      if (idx < length(genres)) {
        return(list(genre_link, tags$span(", ")))
      } else {
        return(list(genre_link))
      }
    })
    
    # create links for cast members
    cast_members <- unlist(strsplit(movie_info$cast_cleaned, ",\\s*"))
    cast_links <- lapply(seq_along(cast_members), function(idx) {
      cast_link <- actionLink(inputId = paste0("cast_", gsub("[^A-Za-z0-9]", "", cast_members[idx])), label = cast_members[idx])
      # Add a comma and space except for the last cast member
      if (idx < length(cast_members)) {
        return(list(cast_link, tags$span(", ")))
      } else {
        return(list(cast_link))
      }
    })
    
    # Check if the homepage link is valid
    if (!is.na(movie_info$homepage) && nzchar(movie_info$homepage)) {
      homepage_link <- tags$a(href = movie_info$homepage, 
                              "Movie Homepage Link (possibly outdated)", 
                              target = "_blank")
    } else {
      homepage_link <- "No Link Available"
    }
    
    # Show a modal dialog with the movie overview
    showModal(modalDialog(
      title = h3(paste(input$selected_movie)),
      h3("Director"),
      actionLink("directorLink", label = movie_info$director),
      h3("Cast"),
      do.call(tagList, cast_links),
      h3("Genres"),
      do.call(tagList, genre_links),
      h3("Release Date"),
      movie_info$release_date,
      h3("Overview"),
      movie_info$overview, 
      h3("Homepage Link"),
      homepage_link,
      h3("Other info"),
      tags$table(
        id="table", 
        tags$tbody(
          tags$tr(
            tags$td("Budget"), 
            tags$td("$", movie_info$budget)
          ),
          tags$tr(
            tags$td("Revenue"), 
            tags$td("$", movie_info$revenue)
          ),
          tags$tr(
            tags$td("Popularity"), 
            tags$td(movie_info$popularity)
          ),
          tags$tr(
            tags$td("Runtime"), 
            tags$td(movie_info$runtime, " (minutes)")
          ),
          tags$tr(
            tags$td("Vote Average"), 
            tags$td(movie_info$vote_average)
          ),
          tags$tr(
            tags$td("Vote Count"), 
            tags$td(movie_info$vote_count)
          )
        )
      ),
      easyClose = TRUE,
      footer = modalButton("Close"),
      # Apply custom CSS styles
      # Apply custom CSS styles to modalDialog
      tags$style(HTML("
              .modal-content {
                border: 2px solid #337ab7;
                border-radius: 5px;
                box-shadow: 0px 0px 10px #888888;
                background-color: #f9f9f9;
              }
              .modal-header {
                background-color: #337ab7;
                color: white;
                border-bottom: none;
                text-align: center;
                font-size: 1.25em;
                font-weight: bold;
              }
              .modal-footer {
                background-color: #f9f9f9;
                border-top: none;
              }
              .btn-primary {
                background-color: #337ab7;
                color: white;
              }
              .modal-body h3 {
                color: #800080;
                font-weight: bold;
              }
              #table{
	                width:100%;
	                border-collapse:collapse;
	                border: 1px solid #ddd;
              }
              #table > tbody > tr > td{
                  padding: 8px;
                  line-height: 1.42857143;
                  vertical-align: top;
                  border:1px solid black;
              }
              .modal-footer .btn { /* Targeting the modal button */
                  background-color: #7F7FBF; 
                  color: white; /* White text */
                  padding: 10px 20px; /* Some padding */
                  border: none; /* No border */
                  border-radius: 5px; /* Rounded corners */
                  cursor: pointer; /* Pointer/hand icon */
                  font-size: 16px; /* Larger font size */
              }
            .modal-footer .btn:hover {
                  background-color: #800080; 
              }
            "))
    ))
    
    # List of background images
    bg_images <- c(
      'https://www.austinchronicle.com/binary/bf7f/SS.Spellbound.jpg',
      'https://media.gq.com/photos/55834f183655c24c6c961e29/master/w_1600,c_limit/style-blogs-the-gq-eye-A-Clockwork-Orange-a-clockwork-orange-alex-delarge.jpg',
      'https://nypost.com/wp-content/uploads/sites/2/2017/12/171204-casablanca-anniversary-inside-feature.jpg?resize=1064,709&quality=75&strip=all',
      'https://anticosoleitaly.com/wp-content/uploads/2020/11/Roman-Holiday-ROCCA.jpeg',
      'https://decider.com/wp-content/uploads/2016/02/silence-of-the-lambs.jpg?quality=90&strip=all&w=1156&h=771&crop=1',
      'https://phantom-marca.unidadeditorial.es/5a27fb0feca01095b49b3e8fc215d2da/resize/828/f/webp/assets/multimedia/imagenes/2023/02/27/16775256562832.jpg',
      'https://www.hollywoodreporter.com/wp-content/uploads/2022/07/11-MSDSTWA_EC001-EMBED-2022.jpg?w=1000&h=666&crop=1',
      'https://jaredmobarak.com/wp-content/uploads/2017/09/bladerunner01.jpg',
      'https://ichef.bbci.co.uk/images/ic/1024xn/p0639ffn.jpg.webp',
      'https://miro.medium.com/v2/resize:fit:1100/format:webp/1*RwKjcnNhDsr0PSy5wyorwQ.jpeg'
    )
    # Randomly select a background image
    selected_bg <- sample(bg_images, 1)
    
    # create observers for each genre
    lapply(genres, function(genre) {
      observeEvent(input[[paste0("genre_", gsub("[^A-Za-z0-9]", "", genre))]], {
        # search movies under each genre
        genre_movies <- sort(filter(movies_by_genre, genres_cleaned == genre)$movies[[1]])
        # if the number of movies is larger than 10, randomly select 10 movies to display
        if(length(genre_movies) > 10) {
          genre_movies <- sort(sample(genre_movies, 10))
        }
        showModal(modalDialog(
          title = paste("Randomly Selected Movies in", genre),
          footer = modalButton("Close"),
          renderUI({
            tags$ul(
              lapply(genre_movies, function(title) {
                tags$li(title)
              })
            )
          }),
          
          # Add custom CSS for background image
          tags$style(HTML(paste0("
        .modal-content {
          background-image: url('", selected_bg, "');
          background-size: cover; /* Cover the entire modal area */
          color: #fff; /* Change text color if needed */
          text-shadow: 2px 2px 4px black;
        }
        .modal-body {
          background: transparent; /* Make modal body background transparent */
        }
        .modal-header h4 { /* Assuming title is within an h4 element */
          color: white;
          text-shadow: 2px 2px 4px black;
        }
        .modal-footer .btn { /* Targeting the modal button */
        background-color: #7F7FBF; 
        color: white; /* White text */
        padding: 10px 20px; /* Some padding */
        border: none; /* No border */
        border-radius: 5px; /* Rounded corners */
        cursor: pointer; /* Pointer/hand icon */
        font-size: 16px; /* Larger font size */
      }
      .modal-footer .btn:hover {
        background-color: #800080; 
      }
      ")))
        ))
      }, ignoreInit = TRUE, once = TRUE)
    })
    
    
    # Similar logic for cast members
    lapply(cast_members, function(member) {
      observeEvent(input[[paste0("cast_", gsub("[^A-Za-z0-9]", "", member))]], {
        cast_movies <- sort(filter(movies_by_cast, cast_cleaned == member)$movies[[1]])
        if(length(cast_movies) > 10) {
          cast_movies <- sort(sample(cast_movies, 10))
        }
        
        showModal(modalDialog(
          title = paste("Movies by", member),
          footer = modalButton("Close"),
          renderUI({
            tags$ul(
              lapply(cast_movies, function(title) {
                tags$li(title)
              })
            )
          }),
          # Add custom CSS for background image
          tags$style(HTML(paste0("
        .modal-content {
          background-image: url('", selected_bg, "');
          background-size: cover; /* Cover the entire modal area */
          color: #fff; /* Change text color if needed */
          text-shadow: 2px 2px 4px black;
        }
        .modal-body {
          background: transparent; /* Make modal body background transparent */
        }
        .modal-header h4 { /* Assuming title is within an h4 element */
          color: white;
          text-shadow: 2px 2px 4px black;
        }
      .modal-footer .btn { /* Targeting the modal button */
        background-color: #7F7FBF; 
        color: white; /* White text */
        padding: 10px 20px; /* Some padding */
        border: none; /* No border */
        border-radius: 5px; /* Rounded corners */
        cursor: pointer; /* Pointer/hand icon */
        font-size: 16px; /* Larger font size */
      }
      .modal-footer .btn:hover {
        background-color: #800080; 
      }
      ")))
        ))
      }, ignoreInit = TRUE, once = TRUE)
    })
    
  }, ignoreNULL = TRUE)
  
  # Observe the director link click event
  observeEvent(input$directorLink, {
    # Get the name of the clicked director
    selected_director <- movies_data[movies_data$title == input$selected_movie, ]$director
    # Retrieve all movies by that director
    director_movies <- director_works %>%
      filter(director == selected_director) %>%
      pull(works) %>% unlist() %>% sort
    
    # List of background images
    bg_images <- c(
      'https://www.austinchronicle.com/binary/bf7f/SS.Spellbound.jpg',
      'https://media.gq.com/photos/55834f183655c24c6c961e29/master/w_1600,c_limit/style-blogs-the-gq-eye-A-Clockwork-Orange-a-clockwork-orange-alex-delarge.jpg',
      'https://nypost.com/wp-content/uploads/sites/2/2017/12/171204-casablanca-anniversary-inside-feature.jpg?resize=1064,709&quality=75&strip=all',
      'https://anticosoleitaly.com/wp-content/uploads/2020/11/Roman-Holiday-ROCCA.jpeg',
      'https://decider.com/wp-content/uploads/2016/02/silence-of-the-lambs.jpg?quality=90&strip=all&w=1156&h=771&crop=1',
      'https://phantom-marca.unidadeditorial.es/5a27fb0feca01095b49b3e8fc215d2da/resize/828/f/webp/assets/multimedia/imagenes/2023/02/27/16775256562832.jpg',
      'https://www.hollywoodreporter.com/wp-content/uploads/2022/07/11-MSDSTWA_EC001-EMBED-2022.jpg?w=1000&h=666&crop=1',
      'https://jaredmobarak.com/wp-content/uploads/2017/09/bladerunner01.jpg',
      'https://ichef.bbci.co.uk/images/ic/1024xn/p0639ffn.jpg.webp',
      'https://miro.medium.com/v2/resize:fit:1100/format:webp/1*RwKjcnNhDsr0PSy5wyorwQ.jpeg'
    )
    # Randomly select a background image
    selected_bg <- sample(bg_images, 1)
    
    # Show all movies by the director
    showModal(modalDialog(
      title = h4(paste0(selected_director, "'s Movies")),
      renderTable(data.frame('Movie Name:' = director_movies, check.names = FALSE)),
      easyClose = TRUE,
      footer = modalButton("Close"),
      tags$style(HTML("
      .modal-content {
        background-image: url('", selected_bg, "');
        background-size: cover; /* Cover the entire modal area */
        color: #fff; /* Change text color if needed */
        text-shadow: 2px 2px 4px black;
      }
      .modal-body {
        background: transparent; /* Make modal body background transparent */
      }
      .modal-header h4 { /* Assuming title is within an h4 element */
        color: white;
        text-shadow: 2px 2px 4px black;
      }
      .modal-footer .btn { /* Targeting the modal button */
        background-color: #7F7FBF; 
        color: white; /* White text */
        padding: 10px 20px; /* Some padding */
        border: none; /* No border */
        border-radius: 5px; /* Rounded corners */
        cursor: pointer; /* Pointer/hand icon */
        font-size: 16px; /* Larger font size */
      }
      .modal-footer .btn:hover {
        background-color: #800080; 
      }
    "))
    ))
  }, ignoreNULL = TRUE)
}

# Run the application 
shinyApp(ui = ui, server = server)