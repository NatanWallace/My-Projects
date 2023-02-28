--Create the tables that we want to import the csv into

CREATE TABLE IF NOT EXISTS FOCO_WEATHER_DATA (
	date DATE, LOCATION VARCHAR(255),
	TEMP NUMERIC(7,2),
	TEMP_MAX NUMERIC(7,2),
	TEMP_MIN NUMERIC(7,2),
	HUMID_2M NUMERIC(7,2),
	PRECIPITATION NUMERIC(7,2),
	SURFACE_PRESSURE NUMERIC(9,2),
	WIND_SPEED_2M NUMERIC(7,2),
	WIND_SPEED_2M_MAX NUMERIC(7,2),
	WIND_SPEED_2M_MIN NUMERIC(7,2),
	DEW_OR_FROST_POINT NUMERIC(7,2),
	WIND_DIRECTION_2M NUMERIC(7,2),
	WIND_DIRECTION_10M NUMERIC(7,2),
	WIND_SPEED_10M_MIN NUMERIC(7,2),
	WIND_SPEED_10M_MAX NUMERIC(7,2));

CREATE TABLE IF NOT EXISTS LONGS_PEAK_WEATHER_DATA (
	date DATE, LOCATION VARCHAR(255),
	TEMP NUMERIC(7,2),
	TEMP_MAX NUMERIC(7,2),
	TEMP_MIN NUMERIC(7,2),
	HUMID_2M NUMERIC(7,2),
	PRECIPITATION NUMERIC(7,2),
	SURFACE_PRESSURE NUMERIC(9,2),
	WIND_SPEED_2M NUMERIC(7,2),
	WIND_SPEED_2M_MAX NUMERIC(7,2),
	WIND_SPEED_2M_MIN NUMERIC(7,2),
	DEW_OR_FROST_POINT NUMERIC(7,2),
	WIND_DIRECTION_2M NUMERIC(7,2),
	WIND_DIRECTION_10M NUMERIC(7,2),
	WIND_SPEED_10M_MIN NUMERIC(7,2),
	WIND_SPEED_10M_MAX NUMERIC(7,2));

-- I will start from inspecting the Fort Collins, CO data and then inspect Longs Peak,CO. once I see that they are good I will union them into one new table
-- View the first 10 rows of the foco_weather_data table

SELECT *
FROM FOCO_WEATHER_DATA
LIMIT 10;

-- View the first 10 rows of the longs_peak_weather_data table

SELECT *
FROM LONGS_PEAK_WEATHER_DATA
LIMIT 10;

--Update location names

UPDATE FOCO_WEATHER_DATA
SET LOCATION = 
	CASE
	WHEN LOCATION = 'foco' THEN 'Fort Collins'
	ELSE LOCATION
	END
WHERE LOCATION IN ('foco');


UPDATE LONGS_PEAK_WEATHER_DATA
SET LOCATION = 
	CASE
	WHEN LOCATION = 'longspeak' THEN 'Longs Peak'
	ELSE LOCATION
	END
WHERE LOCATION IN ('longspeak');

-- View the data types and columns in the foco_weather_data table

SELECT COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'foco_weather_data';

-- View the data types and columns in the longs_peak_weather_data table

SELECT COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'longs_peak_weather_data';

-- Check for missing values in the precipitation column

SELECT COUNT(*),
COUNT(PRECIPITATION)
FROM FOCO_WEATHER_DATA;


SELECT COUNT(*),
COUNT(PRECIPITATION)
FROM LONGS_PEAK_WEATHER_DATA;

-- Check for duplicate dates

SELECT date, COUNT(*) AS NUM_DUPLICATES
FROM FOCO_WEATHER_DATA
GROUP BY date
HAVING COUNT(*) > 1;


SELECT date, COUNT(*) AS NUM_DUPLICATES
FROM LONGS_PEAK_WEATHER_DATA
GROUP BY date
HAVING COUNT(*) > 1;


CREATE TABLE IF NOT EXISTS COMBINED_WEATHER_DATA AS
SELECT *
FROM FOCO_WEATHER_DATA
UNION ALL
SELECT *
FROM LONGS_PEAK_WEATHER_DATA;

-- View the range of values in the temp column, range of dates, max wind at 2 meter, max wind at 10 meter, max precipitation

SELECT 
	LOCATION,
	MIN(TEMP_MIN) AS MIN_TEMP,
	MAX(TEMP_MAX) AS MAX_TEMP,
	MIN(date) AS FIRST_DATE,
	MAX(date) AS LAST_DATE,
	MAX("wind_speed_2m_max") AS MAX_WIND_SPEED_2M,
	MAX("wind_speed_10m_max") AS MAX_WIND_SPEED_10M,
	MAX(PRECIPITATION) AS MAX_PRECIPITATION
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION;

--average temperature and precipitation for each year, make is into a table

CREATE VIEW TEMP_PRECIPITATION_YEARLY_SUMMARY AS
SELECT 
	LOCATION,
	EXTRACT(YEAR
	FROM date) AS YEAR,
	AVG(TEMP) AS AVG_TEMP,
	AVG(TEMP_MAX) AS AVG_TEMP_MAX,
	AVG(TEMP_MIN) AS AVG_TEMP_MIN,
	SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR
ORDER BY YEAR,
LOCATION;

-- Find the percentage of precipitation in 2023 relative to the average precipitation of the other years

CREATE VIEW AVG_PRECIPITAION_OF_YEARLY_AVG AS
SELECT 
	THIS_YEAR.LOCATION,
	THIS_YEAR.PRECIPITATION_2023,
	OTHER_YEARS.AVG_YEARLY_PRECIPITATION,
	THIS_YEAR.PRECIPITATION_2023 / OTHER_YEARS.AVG_YEARLY_PRECIPITATION * 100 AS PRECIPITATION_PERCENTAGE_OF_YEARLY_AVG
FROM 
(
SELECT 
	LOCATION,
	TOTAL_PRECIPITATION AS PRECIPITATION_2023
FROM TEMP_PRECIPITATION_YEARLY_SUMMARY
WHERE YEAR = 2023
) AS THIS_YEAR
JOIN --yearly avg no 2023
(
SELECT 
	LOCATION,
	AVG(TOTAL_PRECIPITATION) AS AVG_YEARLY_PRECIPITATION
FROM TEMP_PRECIPITATION_YEARLY_SUMMARY
WHERE YEAR <> 2023
GROUP BY LOCATION) AS OTHER_YEARS 
ON THIS_YEAR.LOCATION = OTHER_YEARS.LOCATION ;

-- Compare the period of the data that we have from 2023 (Until Jan 29) to the same period in the rest of the years
-- Calculate the average total precipitation for January in other years
WITH OTHER_YEARS_PRECIP AS (
	SELECT
		LOCATION,
		AVG(JAN_PRECIPITATION) AS AVG_JAN_PRECIPITATION
	FROM (
		SELECT
			LOCATION,
			EXTRACT(YEAR FROM date) AS YEAR,
			SUM(PRECIPITATION) AS JAN_PRECIPITATION
		FROM COMBINED_WEATHER_DATA
		WHERE EXTRACT(MONTH FROM date) = 1
			AND EXTRACT(DAY FROM date) <= 29
			AND EXTRACT(YEAR FROM date) <> 2023
		GROUP BY LOCATION, YEAR
	) YEARLY_PRECIPITATION
GROUP BY LOCATION), -- Calculate the total precipitation for January 2023
THIS_YEAR_PRECIP AS (
	SELECT 
		LOCATION,
		SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
	FROM COMBINED_WEATHER_DATA
	WHERE EXTRACT(YEAR FROM date) = 2023
	GROUP BY LOCATION) -- Compare the total precipitation for January 2023 to the average for other years
SELECT 
	THIS_YEAR_PRECIP.LOCATION,
	THIS_YEAR_PRECIP.TOTAL_PRECIPITATION AS "jan_2023_precipitation",
	OTHER_YEARS_PRECIP.AVG_JAN_PRECIPITATION AS OTHER_YEARS_AVG_PRECIPITATION,
	(THIS_YEAR_PRECIP.TOTAL_PRECIPITATION / OTHER_YEARS_PRECIP.AVG_JAN_PRECIPITATION) * 100 AS PERCENT_DIFFERENCE
FROM THIS_YEAR_PRECIP, OTHER_YEARS_PRECIP
WHERE THIS_YEAR_PRECIP.LOCATION = OTHER_YEARS_PRECIP.LOCATION;

--Find the days with the highest and lowest temperatures and highest precipitation.

SELECT 
	D.MAX_TEMP_DATE,
	D.MAX_TEMP,
	D.MIN_TEMP_DATE,
	D.MIN_TEMP,
	D.MAX_PRECIPITATION_DATE,
	D.MAX_PRECIPITATION,
	D.LOCATION
FROM (
	SELECT(	SELECT date FROM FOCO_WEATHER_DATA WHERE TEMP_MAX = (SELECT MAX(TEMP_MAX) FROM FOCO_WEATHER_DATA)) AS MAX_TEMP_DATE,
	(SELECT MAX(TEMP_MAX) FROM FOCO_WEATHER_DATA) AS MAX_TEMP,
	(SELECT date FROM FOCO_WEATHER_DATA WHERE TEMP_MIN = (SELECT MIN(TEMP_MIN) FROM FOCO_WEATHER_DATA)) AS MIN_TEMP_DATE,
	(SELECT MIN(TEMP_MIN) FROM FOCO_WEATHER_DATA) AS MIN_TEMP,
	(SELECT date FROM FOCO_WEATHER_DATA WHERE PRECIPITATION = (SELECT MAX(PRECIPITATION) FROM FOCO_WEATHER_DATA)) AS MAX_PRECIPITATION_DATE,
	(SELECT MAX(PRECIPITATION) FROM FOCO_WEATHER_DATA) AS MAX_PRECIPITATION,
	'foco' AS LOCATION
UNION ALL SELECT
	(SELECT date FROM LONGS_PEAK_WEATHER_DATA WHERE TEMP_MAX = (SELECT MAX(TEMP_MAX) FROM LONGS_PEAK_WEATHER_DATA)) AS MAX_TEMP_DATE,
	(SELECT MAX(TEMP_MAX) FROM LONGS_PEAK_WEATHER_DATA) AS MAX_TEMP,
	(SELECT date FROM LONGS_PEAK_WEATHER_DATA WHERE TEMP_MIN = (SELECT MIN(TEMP_MIN) FROM LONGS_PEAK_WEATHER_DATA)) AS MIN_TEMP_DATE,
	(SELECT MIN(TEMP_MIN) FROM LONGS_PEAK_WEATHER_DATA) AS MIN_TEMP,
	(SELECT date FROM LONGS_PEAK_WEATHER_DATA WHERE PRECIPITATION = (SELECT MAX(PRECIPITATION) FROM LONGS_PEAK_WEATHER_DATA)) AS MAX_PRECIPITATION_DATE,
	(SELECT MAX(PRECIPITATION)FROM LONGS_PEAK_WEATHER_DATA) AS MAX_PRECIPITATION,
	'longspeak' AS LOCATION
	) D;

-- Find the temp spread in every day

CREATE VIEW DAILY_TEMP_SPREAD AS
SELECT 
	LOCATION, 
	date, 
	TEMP_MIN,
	TEMP_MAX,
	TEMP_MAX - TEMP_MIN AS TEMP_SPREAD
FROM COMBINED_WEATHER_DATA
ORDER BY LOCATION,date;

-- Find the highest temp spread

SELECT 
	C.LOCATION,
	C.DATE,
	C.TEMP_MIN,
	C.TEMP_MAX,
	C.TEMP_MAX - C.TEMP_MIN AS TEMP_SPREAD
FROM COMBINED_WEATHER_DATA C
JOIN
(SELECT 
	LOCATION,
	MAX(TEMP_MAX - TEMP_MIN) AS MAX_TEMP_SPREAD
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION) MTS 
ON C.LOCATION = MTS.LOCATION
AND C.TEMP_MAX - C.TEMP_MIN = MTS.MAX_TEMP_SPREAD
ORDER BY C.LOCATION;

-- Find the lowest temp spread

SELECT 
	C.LOCATION,
	C.DATE,
	C.TEMP_MIN,
	C.TEMP_MAX,
	C.TEMP_MAX - C.TEMP_MIN AS TEMP_SPREAD
FROM COMBINED_WEATHER_DATA C
JOIN
(SELECT 
	LOCATION,
	MIN(TEMP_MAX - TEMP_MIN) AS MIN_TEMP_SPREAD
	FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION) MTS 
ON C.LOCATION = MTS.LOCATION
AND C.TEMP_MAX - C.TEMP_MIN = MTS.MIN_TEMP_SPREAD
ORDER BY C.LOCATION;

-- Find the avg temp change in every day

CREATE VIEW CHANGE_OF_TEMP_BETWEEN_DAYS AS
SELECT 
	LOCATION,
	date,
	TEMP,
	LAG(TEMP) OVER (ORDER BY date) AS PREV_DAY_TEMP,
	TEMP - LAG(TEMP) OVER (ORDER BY date) AS TEMP_CHANGE
FROM COMBINED_WEATHER_DATA
ORDER BY LOCATION,date;

-- Find the total precipitation of each month
CREATE VIEW MONTHLY_PRECIPITATION AS
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	EXTRACT(MONTH FROM date) AS MONTH,
	SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR,MONTH
ORDER BY LOCATION,YEAR,MONTH;

-- Find the total precipitation of each month and compare the months side by side

CREATE VIEW MONTHLY_PRECIPITATION_BY_MONTH AS
SELECT 
	LOCATION,
	YEAR,
	SUM(CASE WHEN MONTH = 1 THEN TOTAL_PRECIPITATION ELSE 0 END) AS JANUARY,
	SUM(CASE WHEN MONTH = 2 THEN TOTAL_PRECIPITATION ELSE 0 END) AS FEBRUARY,
	SUM(CASE WHEN MONTH = 3 THEN TOTAL_PRECIPITATION ELSE 0 END) AS MARCH,
	SUM(CASE WHEN MONTH = 4 THEN TOTAL_PRECIPITATION ELSE 0 END) AS APRIL,
	SUM(CASE WHEN MONTH = 5 THEN TOTAL_PRECIPITATION ELSE 0 END) AS MAY,
	SUM(CASE WHEN MONTH = 6 THEN TOTAL_PRECIPITATION ELSE 0 END) AS JUNE,
	SUM(CASE WHEN MONTH = 7 THEN TOTAL_PRECIPITATION ELSE 0 END) AS JULY,
	SUM(CASE WHEN MONTH = 8 THEN TOTAL_PRECIPITATION ELSE 0 END) AS AUGUST,
	SUM(CASE WHEN MONTH = 9 THEN TOTAL_PRECIPITATION ELSE 0 END) AS SEPTEMBER,
	SUM(CASE WHEN MONTH = 10 THEN TOTAL_PRECIPITATION ELSE 0 END) AS OCTOBER,
	SUM(CASE WHEN MONTH = 11 THEN TOTAL_PRECIPITATION ELSE 0 END) AS NOVEMBER,
	SUM(CASE WHEN MONTH = 12 THEN TOTAL_PRECIPITATION ELSE 0 END) AS DECEMBER
FROM
	(SELECT 
	 	LOCATION,
	 	EXTRACT(YEAR FROM date) AS YEAR,
		EXTRACT(MONTH FROM date) AS MONTH,
		SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
	FROM COMBINED_WEATHER_DATA
	GROUP BY LOCATION,YEAR,MONTH) SUB
GROUP BY LOCATION,YEAR
ORDER BY LOCATION,YEAR ;

-- Create a new column that indicates whether each day had above or below average temperature for that year

CREATE VIEW ABOVE_OR_BELOW_AVG_TEMP AS
SELECT
	COMBINED_WEATHER_DATA.LOCATION,
	COMBINED_WEATHER_DATA.DATE,
	COMBINED_WEATHER_DATA.TEMP,
	CASE WHEN COMBINED_WEATHER_DATA.TEMP > YEARLY_AVG.YEARLY_AVG_TEMP THEN 'above' ELSE 'below' END AS TEMP_AVG_INDICATOR
FROM COMBINED_WEATHER_DATA
JOIN
(SELECT
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	AVG(TEMP) AS YEARLY_AVG_TEMP
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR) YEARLY_AVG 
ON COMBINED_WEATHER_DATA.LOCATION = YEARLY_AVG.LOCATION
AND EXTRACT(YEAR FROM COMBINED_WEATHER_DATA.DATE) = YEARLY_AVG.YEAR;

--Calculate the total precipitation for each year and compare it to the average precipitation
--(Need to make sure that 2023 is not part of the avg since we dont have the full year)

CREATE VIEW YEARLY_PRECIPITATION_VS_AVG AS
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	SUM(PRECIPITATION) AS TOTAL_PRECIPITATION,
	(SUM(PRECIPITATION) / (SELECT AVG(TOTAL_PRECIPITATION)
							FROM
								(SELECT
									EXTRACT(YEAR FROM date) AS YEAR,
									SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
								FROM FOCO_WEATHER_DATA
								WHERE EXTRACT(YEAR FROM date) <> 2023
								GROUP BY YEAR
								) AS TEMP_PRECIPITATION_YEARLY_SUMMARY) * 100) AS PERCENT_OF_AVG
FROM FOCO_WEATHER_DATA
GROUP BY YEAR,LOCATION
UNION
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	SUM(PRECIPITATION) AS TOTAL_PRECIPITATION,
	(SUM(PRECIPITATION) / (SELECT AVG(TOTAL_PRECIPITATION) 
							FROM
								(SELECT EXTRACT(YEAR FROM date) AS YEAR,
								 SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
								FROM LONGS_PEAK_WEATHER_DATA
								WHERE EXTRACT(YEAR FROM date) <> 2023
								GROUP BY YEAR
								) AS TEMP_PRECIPITATION_YEARLY_SUMMARY) * 100) AS PERCENT_OF_AVG
FROM LONGS_PEAK_WEATHER_DATA
GROUP BY YEAR,LOCATION
ORDER BY LOCATION,YEAR;

-- Calculate the correlation between precipitation and humidity

SELECT 
	LOCATION,
	CORR(PRECIPITATION,HUMID_2M) AS CORRELATION
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION ;

-- Add a column for cardinal_wind_direction_10m

ALTER TABLE COMBINED_WEATHER_DATA ADD COLUMN IF NOT EXISTS INTERCARDINAL_WIND_DIRECTION_10M text;

UPDATE COMBINED_WEATHER_DATA
SET INTERCARDINAL_WIND_DIRECTION_10M = CASE
WHEN WIND_DIRECTION_10M BETWEEN 0 AND 22.5 THEN 'N'
WHEN WIND_DIRECTION_10M BETWEEN 22.5 AND 67.5 THEN 'NE'
WHEN WIND_DIRECTION_10M BETWEEN 67.5 AND 112.5 THEN 'E'
WHEN WIND_DIRECTION_10M BETWEEN 112.5 AND 157.5 THEN 'SE'
WHEN WIND_DIRECTION_10M BETWEEN 157.5 AND 202.5 THEN 'S'
WHEN WIND_DIRECTION_10M BETWEEN 202.5 AND 247.5 THEN 'SW'
WHEN WIND_DIRECTION_10M BETWEEN 247.5 AND 292.5 THEN 'W'
WHEN WIND_DIRECTION_10M BETWEEN 292.5 AND 337.5 THEN 'NW'
WHEN WIND_DIRECTION_10M BETWEEN 337.5 AND 360 THEN 'N'
END;

-- Add a column for cardinal_wind_direction_2m

ALTER TABLE COMBINED_WEATHER_DATA ADD COLUMN IF NOT EXISTS INTERCARDINAL_WIND_DIRECTION_2M text;

UPDATE COMBINED_WEATHER_DATA
SET INTERCARDINAL_WIND_DIRECTION_2M = CASE
WHEN WIND_DIRECTION_2M BETWEEN 0 AND 22.5 THEN 'N'
WHEN WIND_DIRECTION_2M BETWEEN 22.5 AND 67.5 THEN 'NE'
WHEN WIND_DIRECTION_2M BETWEEN 67.5 AND 112.5 THEN 'E'
WHEN WIND_DIRECTION_2M BETWEEN 112.5 AND 157.5 THEN 'SE'
WHEN WIND_DIRECTION_2M BETWEEN 157.5 AND 202.5 THEN 'S'
WHEN WIND_DIRECTION_2M BETWEEN 202.5 AND 247.5 THEN 'SW'
WHEN WIND_DIRECTION_2M BETWEEN 247.5 AND 292.5 THEN 'W'
WHEN WIND_DIRECTION_2M BETWEEN 292.5 AND 337.5 THEN 'NW'
WHEN WIND_DIRECTION_2M BETWEEN 337.5 AND 360 THEN 'N'
END;

-- Add a column for cardinal_wind_direction_10m

ALTER TABLE FOCO_WEATHER_DATA ADD COLUMN IF NOT EXISTS INTERCARDINAL_WIND_DIRECTION_10M text;

UPDATE FOCO_WEATHER_DATA
SET INTERCARDINAL_WIND_DIRECTION_10M = CASE
WHEN WIND_DIRECTION_10M BETWEEN 0 AND 22.5 THEN 'N'
WHEN WIND_DIRECTION_10M BETWEEN 22.5 AND 67.5 THEN 'NE'
WHEN WIND_DIRECTION_10M BETWEEN 67.5 AND 112.5 THEN 'E'
WHEN WIND_DIRECTION_10M BETWEEN 112.5 AND 157.5 THEN 'SE'
WHEN WIND_DIRECTION_10M BETWEEN 157.5 AND 202.5 THEN 'S'
WHEN WIND_DIRECTION_10M BETWEEN 202.5 AND 247.5 THEN 'SW'
WHEN WIND_DIRECTION_10M BETWEEN 247.5 AND 292.5 THEN 'W'
WHEN WIND_DIRECTION_10M BETWEEN 292.5 AND 337.5 THEN 'NW'
WHEN WIND_DIRECTION_10M BETWEEN 337.5 AND 360 THEN 'N'
END;

-- Add a column for cardinal_wind_direction_2m

ALTER TABLE FOCO_WEATHER_DATA ADD COLUMN IF NOT EXISTS INTERCARDINAL_WIND_DIRECTION_2M text;

UPDATE FOCO_WEATHER_DATA
SET INTERCARDINAL_WIND_DIRECTION_2M = CASE
WHEN WIND_DIRECTION_2M BETWEEN 0 AND 22.5 THEN 'N'
WHEN WIND_DIRECTION_2M BETWEEN 22.5 AND 67.5 THEN 'NE'
WHEN WIND_DIRECTION_2M BETWEEN 67.5 AND 112.5 THEN 'E'
WHEN WIND_DIRECTION_2M BETWEEN 112.5 AND 157.5 THEN 'SE'
WHEN WIND_DIRECTION_2M BETWEEN 157.5 AND 202.5 THEN 'S'
WHEN WIND_DIRECTION_2M BETWEEN 202.5 AND 247.5 THEN 'SW'
WHEN WIND_DIRECTION_2M BETWEEN 247.5 AND 292.5 THEN 'W'
WHEN WIND_DIRECTION_2M BETWEEN 292.5 AND 337.5 THEN 'NW'
WHEN WIND_DIRECTION_2M BETWEEN 337.5 AND 360 THEN 'N'
END;

-- Add a column for cardinal_wind_direction_10m

ALTER TABLE LONGS_PEAK_WEATHER_DATA ADD COLUMN IF NOT EXISTS INTERCARDINAL_WIND_DIRECTION_10M text;

UPDATE LONGS_PEAK_WEATHER_DATA
SET INTERCARDINAL_WIND_DIRECTION_10M = CASE
WHEN WIND_DIRECTION_10M BETWEEN 0 AND 22.5 THEN 'N'
WHEN WIND_DIRECTION_10M BETWEEN 22.5 AND 67.5 THEN 'NE'
WHEN WIND_DIRECTION_10M BETWEEN 67.5 AND 112.5 THEN 'E'
WHEN WIND_DIRECTION_10M BETWEEN 112.5 AND 157.5 THEN 'SE'
WHEN WIND_DIRECTION_10M BETWEEN 157.5 AND 202.5 THEN 'S'
WHEN WIND_DIRECTION_10M BETWEEN 202.5 AND 247.5 THEN 'SW'
WHEN WIND_DIRECTION_10M BETWEEN 247.5 AND 292.5 THEN 'W'
WHEN WIND_DIRECTION_10M BETWEEN 292.5 AND 337.5 THEN 'NW'
WHEN WIND_DIRECTION_10M BETWEEN 337.5 AND 360 THEN 'N'
END;

-- Add a column for cardinal_wind_direction_2m

ALTER TABLE LONGS_PEAK_WEATHER_DATA ADD COLUMN IF NOT EXISTS INTERCARDINAL_WIND_DIRECTION_2M text;

UPDATE LONGS_PEAK_WEATHER_DATA
SET INTERCARDINAL_WIND_DIRECTION_2M = CASE
WHEN WIND_DIRECTION_2M BETWEEN 0 AND 22.5 THEN 'N'
WHEN WIND_DIRECTION_2M BETWEEN 22.5 AND 67.5 THEN 'NE'
WHEN WIND_DIRECTION_2M BETWEEN 67.5 AND 112.5 THEN 'E'
WHEN WIND_DIRECTION_2M BETWEEN 112.5 AND 157.5 THEN 'SE'
WHEN WIND_DIRECTION_2M BETWEEN 157.5 AND 202.5 THEN 'S'
WHEN WIND_DIRECTION_2M BETWEEN 202.5 AND 247.5 THEN 'SW'
WHEN WIND_DIRECTION_2M BETWEEN 247.5 AND 292.5 THEN 'W'
WHEN WIND_DIRECTION_2M BETWEEN 292.5 AND 337.5 THEN 'NW'
WHEN WIND_DIRECTION_2M BETWEEN 337.5 AND 360 THEN 'N'
END;

--Find the 50 days with the highest wind speeds and identify any patterns in wind direction

CREATE VIEW MAX_WIND_SPEED_AND_DIRECTION AS
SELECT *
FROM
	(SELECT
	 	LOCATION, 
	 	date, 
	 	WIND_SPEED_10M_MAX,
		WIND_SPEED_2M_MAX,
		INTERCARDINAL_WIND_DIRECTION_2M,
		INTERCARDINAL_WIND_DIRECTION_10M,
		WIND_DIRECTION_2M,
		WIND_DIRECTION_10M
	FROM FOCO_WEATHER_DATA
	ORDER BY WIND_SPEED_10M_MAX DESC
	LIMIT 50) AS FOCO_TOP_50
UNION
SELECT *
FROM
	(SELECT 
	 	LOCATION, 
	 	date, 
	 	WIND_SPEED_10M_MAX,
		WIND_SPEED_2M_MAX,
		INTERCARDINAL_WIND_DIRECTION_2M,
		INTERCARDINAL_WIND_DIRECTION_10M,
		WIND_DIRECTION_2M,
		WIND_DIRECTION_10M
	FROM LONGS_PEAK_WEATHER_DATA
	ORDER BY WIND_SPEED_10M_MAX DESC
	LIMIT 50) AS LONGS_PEAK_TOP_50
ORDER BY LOCATION,
WIND_SPEED_10M_MAX DESC ;

--The most common wind direction for strong winds is West
-- Calculate the correlation between wind directions in 2m and 10m

SELECT 
	LOCATION,
	CORR(WIND_DIRECTION_2M,
	WIND_DIRECTION_10M) AS CORRELATION
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION;

-- Calculate the mean and standard deviation of the temperature column

SELECT 
	LOCATION,
	AVG(TEMP) AS AVG_TEMP,
	STDDEV(TEMP) AS STDEV_TEMP
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION;

--The standard deviation is too high, I want to try and devide the year into warm season and hot season
--Add season column base on astronomical definition

ALTER TABLE COMBINED_WEATHER_DATA ADD COLUMN IF NOT EXISTS SEASON text;

UPDATE COMBINED_WEATHER_DATA
SET SEASON = CASE
WHEN date >= (TO_DATE(EXTRACT(YEAR FROM date) || '-03-20','YYYY-MM-DD')) 
	AND date < (TO_DATE(EXTRACT(YEAR FROM date) || '-06-20','YYYY-MM-DD')) THEN 'Spring'
WHEN date >= (TO_DATE(EXTRACT(YEAR FROM date) || '-06-20','YYYY-MM-DD'))
	AND date < (TO_DATE(EXTRACT(YEAR FROM date) || '-09-22','YYYY-MM-DD')) THEN 'Summer'
WHEN date >= (TO_DATE(EXTRACT(YEAR FROM date) || '-09-22','YYYY-MM-DD'))
	AND date < (TO_DATE(EXTRACT(YEAR FROM date) || '-12-21','YYYY-MM-DD')) THEN 'Fall'
ELSE 'Winter'
END;

-- Calculate the mean and standard deviation of the temperature column, per seaseon

CREATE VIEW AVG_STDDEV_TEMP_SEASON AS
SELECT 
	LOCATION,
	SEASON,
	AVG(TEMP) AS AVG_TEMP,
	STDDEV(TEMP) AS STDEV_TEMP
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,SEASON
ORDER BY 
	LOCATION,
	CASE
		WHEN SEASON = 'Winter' THEN 1
		WHEN SEASON = 'Spring' THEN 2
		WHEN SEASON = 'Summer' THEN 3
		WHEN SEASON = 'Fall' THEN 4
		ELSE 5
		END;

-- Calculate the mean and standard deviation of the temperature column, per year and seaseon

CREATE VIEW AVG_STDDEV_TEMP_YEAR_SEASON AS
SELECT 
	LOCATION,
	SEASON,
	EXTRACT(YEAR FROM date) AS YEAR,
	AVG(TEMP) AS AVG_TEMP,
	STDDEV(TEMP) AS STDEV_TEMP,
	SUM(PRECIPITATION) AS TOT_SEASON_PRECIPITATION,
	MAX(WIND_SPEED_10M_MAX) AS MAX_WIND_SPEAD_10M
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,SEASON,YEAR
ORDER BY 
	LOCATION,
	CASE
		WHEN SEASON = 'Winter' THEN 1
		WHEN SEASON = 'Spring' THEN 2
		WHEN SEASON = 'Summer' THEN 3
		WHEN SEASON = 'Fall' THEN 4
		ELSE 5
		END, 
	YEAR;

-- Calculate the seasonly_precipitation

CREATE VIEW AVG_SEASONLY_PRECIPITATION AS
SELECT 
	LOCATION,
	SEASON,
	AVG(TOT_PRECIPITATION) AS SEASONLY_PRECIPITATION
FROM (
	SELECT
	  	LOCATION,
	  	SEASON,
		EXTRACT(YEAR FROM date) AS YEAR,
		SUM(PRECIPITATION) AS TOT_PRECIPITATION
	FROM COMBINED_WEATHER_DATA
	GROUP BY LOCATION,YEAR,SEASON
	ORDER BY LOCATION,SEASON) AS A
GROUP BY LOCATION,SEASON
ORDER BY LOCATION,SEASONLY_PRECIPITATION DESC;

-- Create a histogram of the temperature column to visualize the distribution of daily avg,min and max temps

CREATE VIEW HIST_AVG_TEMP AS
SELECT 
	LOCATION,
	FLOOR(TEMP*10) / 10 AS DAILY_TEMP_RANGE,
	COUNT(*) AS NUM_ROWS
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,FLOOR(TEMP*10) / 10
ORDER BY LOCATION,DAILY_TEMP_RANGE;


CREATE VIEW HIST_AVG_MIN_TEMP AS
SELECT 
	LOCATION,
	FLOOR(TEMP_MIN * 10) / 10 AS DAILY_MIN_TEMP_RANGE,
	COUNT(*) AS NUM_ROWS
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,FLOOR(TEMP_MIN * 10) / 10
ORDER BY LOCATION,DAILY_MIN_TEMP_RANGE;


CREATE VIEW HIST_AVG_MAX_TEMP AS
SELECT
	LOCATION,
	FLOOR(TEMP_MAX * 10) / 10 AS DAILY_MAX_TEMP_RANGE,
	COUNT(*) AS NUM_ROWS
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,FLOOR(TEMP_MAX * 10) / 10
ORDER BY LOCATION,DAILY_MAX_TEMP_RANGE;


-- Find the avg temp of each month
CREATE VIEW AVG_MONTHLY_TEMP AS
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	EXTRACT(MONTH FROM date) AS MONTH,
	AVG(TEMP) AS AVG_TEMP
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR,MONTH
ORDER BY LOCATION,YEAR,MONTH

-- Find the avg temp of each season
CREATE VIEW AVG_SEASON_TEMP AS
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	SEASON,
	AVG(TEMP) AS AVG_TEMP
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR,SEASON
ORDER BY LOCATION,SEASON,YEAR

-- Find the avg temp of each season
CREATE VIEW AVG_SEASON_TEMP AS
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	SEASON,
	AVG(TEMP) AS AVG_TEMP
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR,SEASON
ORDER BY LOCATION,SEASON,YEAR


-- Find the total precipitation of each month
CREATE VIEW SEASEON_PRECIPITATION AS
SELECT 
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	SEASON,
	SUM(PRECIPITATION) AS TOTAL_PRECIPITATION
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION,YEAR,SEASON
ORDER BY LOCATION,SEASON,YEAR;

-- Find the lowest and highest temps of each year
CREATE VIEW HIGH_LOW_YEARLY_TEMPS AS
SELECT
	LOCATION,
	EXTRACT(YEAR FROM date) AS YEAR,
	MAX(TEMP_MAX),
	MIN(TEMP_MIN)
FROM COMBINED_WEATHER_DATA
GROUP BY LOCATION, YEAR
ORDER BY LOCATION, YEAR


