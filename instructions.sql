MOVIELENS.RAW
-- Snowflake user creation
-- Step 1: Use an admin role
USE ROLE ACCOUNTADMIN;

-- Step 2: Create the `transform` role and assign it to ACCOUNTADMIN
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Step 3: Create a default warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Step 4: Create the `dbt` user and assign to the transform role
CREATE USER IF NOT EXISTS dbt
  PASSWORD='dbtPassword123'
  LOGIN_NAME='dbt'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE=TRANSFORM
  DEFAULT_NAMESPACE='MOVIELENS.RAW'
  COMMENT='DBT user used for data transformation';
ALTER USER dbt SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM TO USER dbt;

-- Step 5: Create a database and schema for the MovieLens project
CREATE DATABASE IF NOT EXISTS MOVIELENS;
CREATE SCHEMA IF NOT EXISTS MOVIELENS.RAW;

-- Step 6: Grant permissions to the `transform` role
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE MOVIELENS TO ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE MOVIELENS TO ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE MOVIELENS TO ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;

CREATE STAGE netflixstage
  URL='s3://netflix-dataset-elt'
  CREDENTIALS=(AWS_KEY_ID='' AWS_SECRET_KEY='');

-- Set defaults
USE WAREHOUSE COMPUTE_WH;
USE DATABASE MOVIELENS;
USE SCHEMA RAW;

-----------------------------------------------------------------------------
-- Load raw_movies
CREATE OR REPLACE TABLE raw_movies (
  movieId INTEGER,
  title STRING,
  genres STRING
);

COPY INTO raw_movies
FROM '@netflixstage/movies.csv'
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-----------------------------------------------------------------------------
-- Load raw_ratings
CREATE OR REPLACE TABLE raw_ratings (
  userId INTEGER,
  movieId INTEGER,
  rating FLOAT,
  timestamp BIGINT
);

COPY INTO raw_ratings
FROM '@netflixstage/ratings.csv'
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-----------------------------------------------------------------------------
-- Load raw_tags
CREATE OR REPLACE TABLE raw_tags (
  userId INTEGER,
  movieId INTEGER,
  tag STRING,
  timestamp BIGINT
);

COPY INTO raw_tags
FROM '@netflixstage/tags.csv'
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"')
ON_ERROR = 'CONTINUE';

-----------------------------------------------------------------------------
-- Load raw_genome_scores
CREATE OR REPLACE TABLE raw_genome_scores (
  movieId INTEGER,
  tagId INTEGER,
  relevance FLOAT
);

COPY INTO raw_genome_scores
FROM '@netflixstage/genome-scores.csv'
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-----------------------------------------------------------------------------
-- Load raw_genome_tags
CREATE OR REPLACE TABLE raw_genome_tags (
  tagId INTEGER,
  tag STRING
);

COPY INTO raw_genome_tags
FROM '@netflixstage/genome-tags.csv'
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-----------------------------------------------------------------------------
-- Load raw_links
CREATE OR REPLACE TABLE raw_links (
  movieId INTEGER,
  imdbId INTEGER,
  tmdbId INTEGER
);

COPY INTO raw_links
FROM '@netflixstage/links.csv' 
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');
-----------------------------------------------------------------------------

SELECT * FROM MOVIELENS.L3_DEV.FCT_RATINGS
ORDER BY RATING_TIMESTAMP DESC
LIMIT 5;

SELECT * FROM MOVIELENS.L2_Stage.SRC_RATINGS
ORDER BY RATING_TIMESTAMP DESC 
LIMIT 5;

INSERT INTO MOVIELENS.L2_Stage.SRC_RATINGS
VALUES (87587, 7151, 4.0, '2015-03-31 23:40:02.000 -0700');

-----------------------------------------------------------------------------
-- snapshot ==> surrogate key
SELECT * FROM MOVIELENS.SNAPSHPTS.SNAP_TAGS
WHERE user_id = 18
ORDER BY user_id, dbt_valid_from;

UPDATE MOVIELENS.L2_STAGE.SRC_TAGS
SET tag = 'Mark Waters Returns',
    tag_timestamp = CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ)
WHERE user_id = 18;

SELECT * FROM MOVIELENS.L2_STAGE.SRC_TAGS
WHERE user_id = 18;

  
