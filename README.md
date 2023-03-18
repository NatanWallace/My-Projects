# My-Projects

Here are some projects I worked on

Feel free to take a look and leave comments.

## List of projects:

### 1. state country region feature
Python feature - This feature takes the STATE/REGION and COUNTRY/REGION data from HubSpot, cleans them from punctuation and wrongly imported data, and outputs a dataframe containing Record ID, cleaned STATE/REGION, cleaned COUNTRY/REGION, and a newly created Continent column based on the state and country.

It provides two input options: a Redshift table synced from HubSpot named "hs_contacts", or an exported CSV file from HubSpot containing Record ID, STATE/REGION, and COUNTRY/REGION.

The script uses the "awswrangler" library to connect to a Redshift cluster and reads data from the "public.hs_contacts" table. The main functions include removing diacritics from the input string, replacing long state names with abbreviations for US states and Canadian provinces, moving state names to the correct column, and looking up the continent for a given country.

A dictionary for US states, UK countries, and Canadian provinces is provided to facilitate data cleaning. Another dictionary for countries and their continents is used for creating the Continent column. The elapsed time for each operation is printed to keep track of the script's performance.

### 2. job title feature
- Python feature - This feature was created to address the issue of having a large number of unique job titles that made it difficult to analyze job title trends and patterns. By consolidating similar job titles into broader categories, this feature makes it easier to gain insights from job title data and helps to ensure consistency in reporting. The result is a more streamlined and effective way of analyzing job title data.
- SQL analysis - SQL Analysis - This analysis analyzes job titles from a the dataset that was created by the python feature. It seeks to understand the impact of these transformations on the data and gain insights into the job titles.

  The analysis is performed through a series of SQL views and queries that achieve the following:

  Create a view unique_simple_titles to show the distinct simple job titles.
  Create a view all_simple_titles to break the simple titles into separate rows for counting purposes.
  Create a view count_of_simple_titles to count the occurrences of each simple title and sort them in descending order.
  Create a view count_unique_titles to count the number of unique titles in each column, assessing the effectiveness of the transformations.
  Create a view how_many_have_a_simple_title to determine the percentage of job titles that have a simplified version.
  Create a view rows_affected_by_transformation to identify the number of rows affected by each transformation: removing punctuation, extending titles, and creating simple titles.

### 3. co2 emissions project
This Python code analyzes a dataset that provides detailed information on global fossil CO2 emissions by country until 2022. The data includes CO2 emissions from various sources such as coal, oil, gas, cement, flaring, and other industrial processes. The dataset also has a column for per capita CO2 emissions.

The code carries out the following steps:

Load the dataset into a pandas DataFrame.
Perform basic data exploration, such as checking for missing values and duplicates.
Drop unnecessary columns and preprocess the data by removing rows with NaN values for each country.
Create visualizations to analyze CO2 emissions trends by year and by source.
Analyze CO2 emissions from cement production for the last 5, 10, and 20 years and plot the top 10 countries with the highest emissions.
Plot CO2 emissions from cement production for the top 10 countries (excluding China and India) in the last 20 years.
Analyze CO2 emissions from cement production in the USA and Japan, considering important events like the 2008 real estate bubble and changes in building standards in Japan.
The visualizations generated by the code help users understand trends in CO2 emissions, the contribution of different sources to these emissions, and the countries with the highest emissions from cement production.

In addition, the code predicts 2020 CO2 emissions from cement production for the top 15 countries using linear regression, compares predictions to real values, and evaluates model performance with RMSE and R-squared.

### 4. weather analysis project
 - Python project - This is a weather analysis of weather trends in Fort Collins,CO. The data is collected directly from NASA API. Includes a ML model for rain prediction.
 - SQL project - Exploring data of weather in Fort Collins, CO and on top of mountain Longs Peak in Colorado. Looking at temperture, wind patterns, yearly precipitation and 

### 5. chicago arrests project
This Python code analyzes a dataset containing arrest records from the Chicago Police Department (CPD) between 2014 and 2023. The dataset is initially contained in a zip file, which the code extracts and loads into a pandas DataFrame. It then cleans and preprocesses the data by renaming columns, extracting the day, month, and year, and converting the date to a datetime object.

The analysis provides various insights into the data, such as the number of unique values in each column, the top 5 races in the data, and the number of arrests per day of the week. It also visualizes trends in the data using bar plots and line plots, showing the top 3 races per year, arrests by month and year, and the effect of events like the death of George Floyd and the implementation of new CPD policies on arrest records.

