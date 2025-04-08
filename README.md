# 🎬 Netflix Data Analysis Pyhton & SQL Server

This project explores and analyzes Netflix's dataset using Python and SQL Server. The main goal is to clean, transform, and derive insights from Netflix content data such as shows, movies, directors, countries, genres, and durations.

---

## 📌 Project Workflow

1. **Data Import (Python)**
   - Loaded the raw Netflix dataset using Python (Jupyter Notebook).
   - Performed basic data exploration and initial preparation.
   - Uploaded the cleaned data into SQL Server.

2. **Data Cleaning & Transformation (SQL Server)**
   - Removed duplicate entries.
   - Split multivalued columns like `director`, `cast`, `country`, and `listed_in` into separate normalized tables.
   - Handled missing/null values and formatted `date_added`.
   - Created a master table for refined and cleaned Netflix data.

3. **Data Analysis (SQL Server)**
   - Performed multiple analytical queries to answer business questions like:
     - Which director has the most titles?
     - Top countries producing Comedy movies.
     - Average duration of movies by genre.
     - Directors who made both Comedy and Horror movies.
     - Year-wise top directors by number of releases.

---

## 🛠️ Tools & Technologies

- **Python**: Data import and preprocessing
- **SQL Server**: Data storage, transformation, and analysis
- **SQL**: Data cleaning and advanced analytics

---


---

## 🔍 Key Insights

- Countries like the United States produce the most comedy content.
- Some directors have created both TV shows and movies, indicating genre versatility.
- The average duration of movies varies significantly across genres.
- Directors producing both Comedy and Horror are relatively rare but provide unique content diversity.

---

## 📊 Sample SQL Queries

```sql
-- Directors who have created both Comedy and Horror Movies
SELECT nd.director,
COUNT(DISTINCT CASE WHEN ng.genre = 'Comedies' THEN n.show_id END) AS no_of_comedy,
COUNT(DISTINCT CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id END) AS no_of_horror
FROM netflix n
JOIN netflix_directors nd ON n.show_id = nd.show_id
JOIN netflix_genre ng ON nd.show_id = ng.show_id
WHERE n.type = 'Movie' AND ng.genre IN ('Horror Movies','Comedies')
GROUP BY nd.director
HAVING COUNT(DISTINCT ng.genre)>=2;


