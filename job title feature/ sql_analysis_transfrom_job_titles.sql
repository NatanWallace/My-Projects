
CREATE TABLE IF NOT EXISTS transformed_job_titles (
    job_title VARCHAR(100),
    job_title_no_punc VARCHAR(100),
    job_title_no_punc_but_with_upper VARCHAR(100),
    extended_job_title VARCHAR(100),
    simple_job_title VARCHAR(100)
);

select * from transformed_job_titles limit 10

;
--show the simple titles
create view unique_simple_titles as
SELECT DISTINCT unnest(string_to_array(replace(string_agg(transformed_job_titles.simple_job_title, ','), ';', ','), ',')) as unique_titles
FROM transformed_job_titles;

--break the simple titles into seperate rows for the count
create view all_simple_titles as 
SELECT unnest(string_to_array(replace(string_agg(transformed_job_titles.simple_job_title, ','), ';', ','), ',')) as titles
FROM transformed_job_titles;


--count how many of each simple title
create view count_of_simple_titles as 
select titles, count(titles) as num_of_times
from  all_simple_titles
group by titles
order by num_of_times desc;

--count how many unique titles in each column, to see if the function helped
CREATE VIEW count_unique_titles AS
SELECT
  COUNT(DISTINCT job_title) AS job_title_ct,
  COUNT(DISTINCT job_title_no_punc) AS job_title_no_punc_ct,
  COUNT(DISTINCT job_title_no_punc_but_with_upper) AS job_title_no_punc_but_with_upper_ct,
  COUNT(DISTINCT extended_job_title) AS extended_job_title_ct,
  COUNT(DISTINCT simple_job_title) AS simple_job_title_ct,
  (SELECT COUNT(DISTINCT unique_titles) FROM unique_simple_titles) AS unique_simple_titles_ct 
FROM transformed_job_titles;

SELECT
  COUNT(*) FILTER (WHERE simple_job_title NOT IN ('no simple title','no title'))::float / 
  COUNT(extended_job_title) FILTER (WHERE extended_job_title IS NOT NULL) as division_result
FROM transformed_job_titles;


--Calculates the percentage of job titles that have a simplified version
CREATE VIEW how_many_have_a_simple_title AS
SELECT
  ct_of_row_with_simple_title,
  ct_of_rows_with_title,
  ct_of_row_with_simple_title::float / ct_of_rows_with_title AS ratio
FROM (
  SELECT
    COUNT(*) FILTER (WHERE simple_job_title NOT IN ('no simple title','no title')) AS ct_of_row_with_simple_title,
    COUNT(extended_job_title) FILTER (WHERE extended_job_title IS NOT NULL) AS ct_of_rows_with_title
  FROM transformed_job_titles
) AS subquery;


create view rows_affected_by_transformation as
SELECT
  (SELECT COUNT(*) FROM transformed_job_titles WHERE extended_job_title IS NOT NULL) AS count_rows_with_titles,
  (SELECT COUNT(*) FROM transformed_job_titles WHERE job_title_no_punc_but_with_upper <> job_title) AS rows_affected_by_cleaning_punc,
  (SELECT COUNT(*) FROM transformed_job_titles WHERE extended_job_title <> LOWER(job_title)) AS rows_affected_by_extending_titles,
  (SELECT COUNT(*) FROM transformed_job_titles WHERE simple_job_title NOT IN ('no simple title','no title') and simple_job_title <> LOWER(job_title) AND extended_job_title IS NOT NULL) AS rows_affected_by_making_simple_title;

--The last one was not good for the area plot visualization so i created this view:
create view rows_affected_by_transformation_for_area_plot as
SELECT 
  category, 
  count, 
  (SELECT COUNT(*) FROM transformed_job_titles WHERE extended_job_title IS NOT NULL) AS count_rows_with_titles
FROM (
  VALUES
    ('rows_affected_by_cleaning_punc', (SELECT COUNT(*) FROM transformed_job_titles WHERE job_title_no_punc_but_with_upper <> job_title)),
    ('rows_affected_by_extending_titles', (SELECT COUNT(*) FROM transformed_job_titles WHERE extended_job_title <> LOWER(job_title))),
    ('rows_affected_by_making_simple_title', (SELECT COUNT(*) FROM transformed_job_titles WHERE simple_job_title NOT IN ('no simple title','no title') AND simple_job_title <> LOWER(job_title) AND extended_job_title IS NOT NULL))
) AS t(category, count);




