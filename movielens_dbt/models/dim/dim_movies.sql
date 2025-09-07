WITH dim_movies AS (
    SELECT * FROM {{ ref('src_movies') }}
)

SELECT
    movie_id,
    INITCAP(TRIM(title)) AS movie_title,
    SPLIT(genres, '|') AS genre_array,
    genres
FROM dim_movies
