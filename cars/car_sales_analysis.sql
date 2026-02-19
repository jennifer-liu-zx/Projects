-- Initialise database

DROP TABLE IF EXISTS car_sales;
CREATE TABLE car_sales (
	car_id VARCHAR(12),
	date_of_sale DATE,
	customer_name VARCHAR(16),
	gender VARCHAR(6),
	annual_income INT,
	dealer_name VARCHAR(47),
	company VARCHAR(10),
	model VARCHAR(14),
	engine VARCHAR(27),
	transmission VARCHAR(6),
	colour VARCHAR(10),
	price INT,
	dealer_no VARCHAR(10),
	body_style VARCHAR(9),
	phone VARCHAR(7),
	dealer_region VARCHAR(10)
)

SELECT * FROM car_sales LIMIT 5;

-- Data quality verification

--- Missing data?  No missing data.

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN car_id IS NULL          THEN 1 ELSE 0 END) AS null_car_id,
    SUM(CASE WHEN date_of_sale IS NULL    THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN customer_name IS NULL   THEN 1 ELSE 0 END) AS null_customer_name,
    SUM(CASE WHEN annual_income IS NULL   THEN 1 ELSE 0 END) AS null_annual_income,
    SUM(CASE WHEN dealer_name IS NULL     THEN 1 ELSE 0 END) AS null_dealer_name,
    SUM(CASE WHEN dealer_region IS NULL   THEN 1 ELSE 0 END) AS null_dealer_region,
    SUM(CASE WHEN price IS NULL           THEN 1 ELSE 0 END) AS null_price
FROM car_sales;

-- Duplicates? No duplicates.

SELECT
    car_id,
    date_of_sale,
    customer_name,
    gender,
    annual_income,
    dealer_name,
    dealer_no,
    company,
    model,
    engine,
    transmission,
    colour,
    price,
    body_style,
    phone,
    dealer_region,
    COUNT(*) AS row_count
FROM car_sales
GROUP BY
    car_id, date_of_sale, customer_name, gender, annual_income,
    dealer_name, dealer_no, company, model, engine, transmission,
    colour, price, body_style, phone, dealer_region
HAVING COUNT(*) > 1;

-- Consistency of dealer regions

SELECT
    dealer_no,
    COUNT(DISTINCT dealer_name)  AS distinct_names,
    COUNT(DISTINCT dealer_region) AS distinct_regions
FROM car_sales
GROUP BY dealer_no
HAVING COUNT(DISTINCT dealer_name) > 1
    OR COUNT(DISTINCT dealer_region) > 1;
	
SELECT DISTINCT
	dealer_no,
	dealer_name,
	dealer_region
FROM car_sales
WHERE dealer_no IN (
    SELECT
        dealer_no
    FROM car_sales
    GROUP BY dealer_no
    HAVING COUNT(DISTINCT dealer_name) > 1
        OR COUNT(DISTINCT dealer_region) > 1
)
ORDER BY dealer_no, dealer_name, dealer_region;

SELECT COUNT(DISTINCT dealer_no)
FROM car_sales;

-- There are only 7 dealer numbesrs, so ithere should be no error, but we cannot use dealer_no to uniquely identify each dealer. Using dealer _name and dealer_region would be better.

-- First and last dates

SELECT MIN(date_of_sale) AS first_sale, MAX(date_of_sale) as last_sale
FROM car_sales;

-- Other interesting stats?

SELECT
	company AS "Company",
	COUNT(DISTINCT model) AS "Number of models"
FROM car_sales
GROUP BY company
ORDER BY COUNT(DISTINCT model) DESC;

SELECT
    AVG(price)  AS avg_price,
    MIN(price)  AS min_price,
    MAX(price)  AS max_price,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS p25_price,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS median_price,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS p75_price
FROM car_sales;

SELECT
    AVG(annual_income) AS avg_income,
    MIN(annual_income) AS min_income,
    MAX(annual_income) AS max_income,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income) AS median_income
FROM car_sales;

SELECT
    body_style,
    COUNT(*) AS units,
    COUNT(*)::numeric / SUM(COUNT(*)) OVER () AS share_of_total
FROM car_sales
GROUP BY body_style
ORDER BY units DESC;

SELECT
    engine,
    transmission,
    COUNT(*) AS units,
    COUNT(*)::numeric / SUM(COUNT(*)) OVER () AS share_of_total
FROM car_sales
GROUP BY engine, transmission
ORDER BY units DESC;


-- Business Questions

-- 1. What are the top performing companies in terms of revenue and volume?

SELECT 
	company AS "Company", 
	SUM(price) AS "Total revenue", 
	COUNT(price) AS "Units sold"
FROM car_sales
GROUP BY company
ORDER BY SUM(price) DESC
LIMIT 5;

-- Top 3 revenue are are Chevrolet, Ford, Dodge and Oldsmobile. American car companies are doing well.

SELECT 
	company AS "Company", 
	SUM(price) AS "Total revenue", 
	COUNT(price) AS "Units sold"
FROM car_sales
GROUP BY company
ORDER BY COUNT(*) DESC
LIMIT 5;

-- Top 3 revenue are are Chevrolet, Dodge and Ford. American car companies are doing well.
-- Mercedes Benz is also 5th on both measures. Surprisingly, as I expected Japanese companies to have higher volume.

-- 1b. Worst?

SELECT 
	company AS "Company", 
	SUM(price) AS "Total revenue", 
	COUNT(price) AS "Units sold"
FROM car_sales
GROUP BY company
ORDER BY SUM(price)
LIMIT 5;

-- Jaguar, Hyundai, Inifiniti, Jeep, Saab. 

SELECT 
	company AS "Company", 
	SUM(price) AS "Total revenue", 
	COUNT(price) AS "Units sold"
FROM car_sales
GROUP BY company
ORDER BY COUNT(*)
LIMIT 10;

-- Jaguar, Inifiniti, Saab, Hyundai, Porsche. Not that surprising since Porsche mostly sells sports cars which will not have high volumes. Actually, it's more surprising that there aren't more luxury brands (unless Jaguar is counted).

-- Overall, high degree of correlation between companies with high (low) revenue and high (low) units sold, meaning that low revenues could be driven by low volume.
-- Companies with more models in the dataset also tended to perform better than companies with fewer models.
-- This makes sense since sufficient units need to be sold to jsutify the availability of a new model.

-- 2. What are the top-performing models in terms of revenue and volume?

SELECT 
	company AS "Company", 
	model as "Model",
	SUM(price) AS "Total revenue", 
	COUNT(price) AS "Units sold"
FROM car_sales
GROUP BY company, model
ORDER BY SUM(price) DESC
LIMIT 5;

-- The Lexus L400, Volkswagen Jetta, Oldsmobile Sillhouette, Mitsubishi Motero Sport and Dodge Ram Pickup generated the highest revnue. All of them had > 350 units sold.

SELECT 
	company AS "Company", 
	model as "Model",
	SUM(price) AS "Total revenue", 
	COUNT(price) AS "Units sold"
FROM car_sales
GROUP BY company, model
ORDER BY COUNT(*) DESC
LIMIT 5;

-- The Lexus Mitsubushi Diamante, Oldsmobile Sillhouette, Chevrolet Prizm, Volkswagen Passat and Dodge Ram Pickup had the most units sold.
-- There is a high level of correlation between the best performing models in terms of revenue and volume.

-- 3. What is the average selling price by company and body style, and which combinations are premium vs budget?

WITH style_ranks AS (
	SELECT
		company,
		body_style,
		avg_price,
		price_rank_in_company / MAX(price_rank_in_company) OVER(
			PARTITION BY company
		) AS price_percentile_rank
	FROM (
		SELECT
			company,
			body_style,
			AVG(price) AS avg_price,
			RANK() OVER (
				PARTITION BY company
				ORDER BY AVG(price) DESC
			) AS price_rank_in_company
		FROM car_sales
		GROUP BY company, body_style
	) AS temp
)
SELECT
    body_style AS "Body style",
    AVG(price_percentile_rank) AS "Average rank across companies"
FROM style_ranks
GROUP BY body_style
ORDER BY AVG(price_percentile_rank);

-- 1) Hardtop, 2) sedan, 3) SUV, 4) passenger, 5) hatchback

SELECT company, model, body_style
FROM car_sales
WHERE body_style = 'Passenger';

SELECT company, model, body_style
FROM car_sales
WHERE body_style = 'Hardtop';

SELECT company, model, body_style
FROM car_sales
WHERE body_style = 'SUV';

-- Overall, not super indicative of which body styles should be counted as more popular. 

-- 4. Which companies are premium and which are budget?

SELECT
	company AS "Company",
	AVG(price) AS "Higher average price"
FROM car_sales
GROUP BY company
ORDER BY AVG(price) DESC;

-- It's not surprising that Cadillac, Saab, Buick and Lexus are on top. But I'm surprised that Porsche and Jeep rank so low, and all of these German brands are ranking lower than Toyota and Infiniti which are more budget options.

-- 5. How about the most expensive models?

SELECT
	company AS "Company",
	model AS "Model",
	AVG(price) AS "Average price"
FROM car_sales
GROUP BY company, model
ORDER BY AVG(price) DESC;

-- The models and the body styles are the main factors driving the differnece in prices. For example, Toyota's most expensive model is the Tacoma which is a pickup truck and definitely more expensive than say the Audi A4.
-- This reflects the consumption habits of US drivers.

-- 6. Which cars are stauts symbols, i.e. driven by the richest?

SELECT
	company AS "Company",
	model AS "Model",
	AVG(annual_income) AS "Annual income",
	AVG(price) AS "Average price"
FROM car_sales
GROUP BY company, model
ORDER BY AVG(annual_income) DESC;

-- Top 5: 1) Chrysler Sebring Conv., 2) Hyundai Accent, 3) Toyota Celica, 4) Saab 5-Sep, 5) Porsche Carrera Cabrio
-- Not the most expensive models. Usually not even the most expensive models from each company.

SELECT
	company AS "Company",
	AVG(annual_income) AS "Annual income",
	AVG(price) AS "Average price"
FROM car_sales
GROUP BY company
ORDER BY AVG(annual_income) DESC;

-- In terms of companies, the highest annual income seems highly related to the companies with the highest price.
-- This suggests that the pirce may be driven by the tastetes of peopel with higher purchasing power or that higher average prices turn the company into a status symbol sought after by those who can afford it.

-- 7. Instead of analysising in this way, let's take the top 10% and 20% in income and find the most popular cars among them.

WITH income_percentiles AS (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY annual_income) AS income_decile
    FROM car_sales
)
SELECT
    company AS "Company",
    model AS "Model",
    COUNT(*) AS "Units sold"
FROM income_percentiles
WHERE income_decile = 10
GROUP BY company, model
ORDER BY COUNT(*) DESC;

-- Top 5 models: 1) Volkswagen Passat, 2) Mitsubishi Diamante, 3) Oldsmobile Sillhouete, 4) Dodge Ram Pickup, 5) Volkswagen Jetta
-- Though these models did not appear very high in the average price list, they were seen very high in the total revnue list, suggesting that higher quantitiates of these purcharsed led to higher revenue, as opposed to price.

WITH income_percentiles AS (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY annual_income) AS income_decile
    FROM car_sales
)
SELECT
    company AS "Company",
    model AS "Model",
    COUNT(*) AS "Units sold"
FROM income_percentiles
WHERE income_decile >= 9
GROUP BY company, model
ORDER BY COUNT(*) DESC;

-- 8. Which dealer_regions attract the highest‑income customers on average?

SELECT
	dealer_region AS "Dealer Region",
	AVG(annual_income) AS "Avergae income",
	COUNT(DISTINCT dealer_no) AS "Number of dealers"
FROM car_sales
GROUP BY dealer_region
ORDER BY AVG(annual_income) DESC;

-- Ranking: 1) Pasco, 2) Aurora, 3) Janesville, 4) Greenville, 5) Middletown, 6) Austin, 7) Scottsdale
-- The difference in average income between the countries is quite small.
-- Same numebr of dealers in each region (7).

-- 9. Best-performing dealers?

SELECT 
	dealer_name AS "Dealer name",
    dealer_no AS "Dealer number", 
    dealer_region AS "Dealer region", 
	COUNT(*) AS "Units sold"
FROM car_sales
GROUP BY dealer_region, dealer_name, dealer_no
ORDER BY COUNT(*) DESC;

-- 1) Progressive Shippers Cooperative Association No (Janesville)
-- 2) Race Car Help (Austin)
-- 3) Star Enterprises (Pasco)
-- 4) Saab-Belle Dodge (Aurora)
-- 5) U-Haul Co (Austin)

SELECT 
	dealer_name AS "Dealer name",
    dealer_no AS "Dealer number", 
	dealer_region AS "Dealer region",
	SUM(price) AS "Total revenue"
FROM car_sales
GROUP BY dealer_region, dealer_name, dealer_no
ORDER BY SUM(price) DESC;

-- 1) Progressive Shippers Cooperative Association No (Janesville)
-- 2) Scrivener Performance Enginerring (Greenville)
-- 3) U-Haul Co (Austin)
-- 4) Saab-Belle Dodge (Aurora)
-- 5) Ryder Truck Rental and Leasing (Middletown)

-- Some overlap between the 2 measures. There's no outstanding region in this case.

-- 10. Variety of models and conentration in each region?

SELECT
    dealer_name AS "Dealer name",
    dealer_no AS "Dealer number",
    COUNT(DISTINCT model) AS "Distinct models sold",
    COUNT(*) AS "Units sold"
FROM car_sales
GROUP BY dealer_name, dealer_no
ORDER BY COUNT(DISTINCT model) DESC;

-- 1) Tri-State Mack Inc
-- 2) Scrivener Performance Engineering
-- 3) Star Enterprises Inc
-- 4) Progressive Shippers Cooperative Association No
-- 5) Race Car Help
-- 6) Ryder Truck Rental and Leasing
-- 7) Rabun Used Car Sales
-- 8) U-Haul CO
-- 9) Motor Vehicle Branch Office
-- 10) Suburban Ford

-- Quite a lot of verlap with the highest volume and highest revenue ones.
-- Suggetst that the best strategy for having higher revenue is to diversifying products sold instead of focusing on certain models only.

WITH dealer_model_counts AS (
    SELECT
        dealer_name,
        dealer_no,
        model,
        COUNT(*) AS model_sales
    FROM car_sales
    GROUP BY dealer_name, dealer_no, model
),
dealer_totals AS (
    SELECT
        dealer_name,
        dealer_no,
        SUM(model_sales) AS total_sales
    FROM dealer_model_counts
    GROUP BY dealer_name, dealer_no
),
dealer_model_share AS (
    SELECT
        dmc.dealer_name,
        dmc.dealer_no,
        dmc.model,
        dmc.model_sales,
        dt.total_sales,
        dmc.model_sales::decimal / dt.total_sales AS model_share,
        RANK() OVER (
            PARTITION BY dmc.dealer_name, dmc.dealer_no
            ORDER BY dmc.model_sales DESC
        ) AS model_rank_in_dealer
    FROM dealer_model_counts dmc
    JOIN dealer_totals dt
      ON dmc.dealer_name = dt.dealer_name
     AND dmc.dealer_no   = dt.dealer_no
)
SELECT
    dealer_name AS "Dealer name",
    dealer_no AS "Dealer number",
    COUNT(DISTINCT model) AS "Distincts models sold",
    SUM(CASE WHEN model_rank_in_dealer <= 3 THEN model_share ELSE 0 END)
        AS "Top 3 model share"
FROM dealer_model_share
GROUP BY dealer_name, dealer_no
ORDER BY "Top 3 model share" DESC;

-- The dealers who have high volume and revenue are all quite average in terms of the concentration of the top 3 models sold. 
-- This suggestst that concentration does not really matter.

-- 11. Which dealers have the greatest discounts by region? (Proportion of average price regionally)

WITH regional_model_avg AS (
    SELECT
        dealer_region,
        model,
        AVG(price) AS regional_avg_price
    FROM car_sales
    GROUP BY dealer_region, model
),
sales_with_discount AS (
    SELECT
        c.dealer_name,
        c.dealer_no,
        c.dealer_region,
        c.model,
        c.price,
        rma.regional_avg_price,
        (c.price - rma.regional_avg_price) / rma.regional_avg_price AS price_diff_prop
    FROM car_sales c
    JOIN regional_model_avg rma
      ON c.dealer_region = rma.dealer_region
     AND c.model         = rma.model
)
SELECT
    dealer_name AS "Dealer name",
    dealer_no AS "Dealer number",
    AVG(price_diff_prop) AS "Average discount vs region"
FROM sales_with_discount
GROUP BY dealer_name, dealer_no
ORDER BY "Average discount vs region";

-- 1) Nebo Chevrolet
-- 2) Buddy Storbeck's Diesel Service Inc
-- 3) Clay Johnson Auto Sales
-- 4) Race Car Help
-- 5) Chrysler Plymouth
-- 6) Tri-State Mack Inc
-- 7) McKinney Dodge Chrysler Jeep
-- 8) Saab-Belle Dodge
-- 9) Capitol KIA
-- 10) Scrivener Performance Engineering

-- Even though they offer great discounts, Race Car Help, Saab-Belle Dodge and Scrivener Performance Engineering have some of the highest revenue, meaning that these discounts are able to bring in the volume needed to overcome the lowered prices.

-- 12. Revenue share from each income quartile for each dealer.

WITH income_quantiles AS (
    SELECT
        dealer_name,
        dealer_no,
        price,
        NTILE(4) OVER (ORDER BY annual_income) AS income_quartile
    FROM car_sales
),
dealer_revenue AS (
    SELECT
        dealer_name,
        dealer_no,
        income_quartile,
        SUM(price) AS revenue_by_quartile
    FROM income_quantiles
    GROUP BY dealer_name, dealer_no, income_quartile
),
dealer_total AS (
    SELECT
        dealer_name,
        dealer_no,
        SUM(revenue_by_quartile) AS total_revenue
    FROM dealer_revenue
    GROUP BY dealer_name, dealer_no
)
SELECT
    dr.dealer_name AS "Dealer name",
    dr.dealer_no AS "Dealer number",
    dr.income_quartile AS "Income quartile",
    dr.revenue_by_quartile AS "Total revenue",
    dr.revenue_by_quartile::numeric / dt.total_revenue AS "Revenue share"
FROM dealer_revenue dr
JOIN dealer_total dt
  ON dr.dealer_name = dt.dealer_name
 AND dr.dealer_no   = dt.dealer_no
ORDER BY dr.dealer_name, dr.income_quartile;

-- Most revenue shares are between 20% and 30%.
-- Hatfield Volkswagen has 30% of revenue share from 2nd quartile (and 26% from 4th quartile). This could be a coincidence as there is no obvious neglect of other income groups.
-- Nebo Chevrolet has 19% of revenue share from 4th quartile. Its business is actually clearly concentrated in the lower income quartiles (28% in 1st, 30% in 2nd).
-- We note that these dealers do not appear in the list of dealers with highest volume or revenue. This suggestst that diversifying the target audience of sales is a btter strategy than focusing on certain types of customers, just like is the case for car models. Furthermore, these 2 strategies are liekly to be highly correlated.

-- 13. Growth rate of dealers from 2022 to 2023

WITH dealer_monthly AS (
    SELECT
        dealer_name,
        dealer_no,
        DATE_TRUNC('month', date_of_sale::date) AS month,
        SUM(price) AS revenue
    FROM car_sales
    WHERE date_of_sale::date BETWEEN DATE '2022-10-01' AND DATE '2023-09-30'
    GROUP BY dealer_name, dealer_no, DATE_TRUNC('month', date_of_sale::date)
),
dealer_halfyear AS (
    SELECT
        dealer_name,
        dealer_no,
        CASE
            WHEN month BETWEEN DATE '2022-10-01' AND DATE '2023-03-31'
                THEN 'H1'         -- 1 Oct 2022 – 31 Mar 2023
            ELSE 'H2'             -- 1 Apr 2023 – 30 Sep 2023
        END AS period,
        SUM(revenue) AS revenue
    FROM dealer_monthly
    GROUP BY dealer_name, dealer_no,
             CASE
                 WHEN month BETWEEN DATE '2022-10-01' AND DATE '2023-03-31'
                     THEN 'H1'
                 ELSE 'H2'
             END
),
dealer_pivot AS (
    SELECT
        dealer_name,
        dealer_no,
        SUM(CASE WHEN period = 'H1' THEN revenue ELSE 0 END) AS rev_h1,
        SUM(CASE WHEN period = 'H2' THEN revenue ELSE 0 END) AS rev_h2
    FROM dealer_halfyear
    GROUP BY dealer_name, dealer_no
)
SELECT
    dealer_name  AS "Dealer name",
    dealer_no    AS "Dealer number",
    rev_h1       AS "Revenue Oct 22–Mar 23",
    rev_h2       AS "Revenue Apr 23–Sep 23",
    rev_h2 - rev_h1 AS "Absolute growth",
    CASE
        WHEN rev_h1 = 0 THEN NULL
        ELSE (rev_h2 - rev_h1)::numeric / rev_h1
    END AS "Percentage growth"
FROM dealer_pivot
ORDER BY "Percentage growth" DESC NULLS LAST;


-- 1) Clay Johnson Auto Sales (40.9%), 2) Iceberg Rentals (40.6%), 3) Rabun Used Car Sales (35.4%), 4) Pitre Buick-Pontiac-Gmc of Scottsdale (35.2%)
-- Median growth rate is 16.9%. The slowest growing was Suburban Ford at -1.41%. Only this deler and Chrysler of Tri-Cities had negative growth.

-- 14. Growth rate of companies from the first 6 months to the last 6 months.

WITH company_yearly AS (
    SELECT
        company,
        EXTRACT(YEAR FROM date_of_sale::date)::int AS year,
        SUM(price) AS revenue
    FROM car_sales
    GROUP BY company, EXTRACT(YEAR FROM date_of_sale::date)
),
years_pivot AS (
    SELECT
        company,
        SUM(CASE WHEN year = 2022 THEN revenue ELSE 0 END) AS rev_2022,
        SUM(CASE WHEN year = 2023 THEN revenue ELSE 0 END) AS rev_2023
    FROM company_yearly
    GROUP BY company
)
SELECT
    company AS "Company",
    rev_2022 AS "Revenue in 2022",
    rev_2023 AS "Revenue in 2023",
    rev_2023 - rev_2022 AS "Absolute growth",
    CASE
        WHEN rev_2022 = 0 THEN NULL
        ELSE (rev_2023 - rev_2022)::numeric / rev_2022
    END AS "Percentage growth"
FROM years_pivot
ORDER BY "Percentage growth" DESC NULLS LAST;

-- 1) Infiniti, 2) Volvo, 3) BMW, 4) Cadillac, 5) Chevrolet
-- Infiniti, in particular, grew by 87% from 2022 to 2023, more than twice of Volve (40.0%).
-- Hyundai only grew by 0.5%, but all companies saw an increase in revenue from 2022 to 2023.

-- 15. Dealer market shares in each region

WITH region_dealer_counts AS (
    SELECT
        dealer_region,
        dealer_name,
        dealer_no,
        COUNT(*) AS units_sold
    FROM car_sales
    GROUP BY dealer_region, dealer_name, dealer_no
),
region_totals AS (
    SELECT
        dealer_region,
        SUM(units_sold) AS total_units
    FROM region_dealer_counts
    GROUP BY dealer_region
),
region_shares AS (
    SELECT
        rdc.dealer_region,
        rdc.dealer_name,
        rdc.dealer_no,
        rdc.units_sold,
        rdc.units_sold::numeric / rt.total_units AS market_share
    FROM region_dealer_counts rdc
    JOIN region_totals rt
      ON rdc.dealer_region = rt.dealer_region
)
SELECT
    dealer_region AS "Dealer region",
    SUM(market_share * market_share) AS "Herfindahl Index"
FROM region_shares
GROUP BY dealer_region
ORDER BY "Herfindahl Index" DESC;

-- Only Austin has a very littel competition (0.155), whereas the HI for the rest are very similar and between 0.183 and 0.185.

-- 16. Change in composition of engine and transmission in cars solds from 2022 to 2023.

WITH engine_trans_year AS (
    SELECT
        EXTRACT(YEAR FROM date_of_sale::date)::int AS year,
        engine,
        transmission,
        COUNT(*) AS units
    FROM car_sales
    GROUP BY
        EXTRACT(YEAR FROM date_of_sale::date)::int,
        engine,
        transmission
),
year_totals AS (
    SELECT
        year,
        SUM(units) AS total_units
    FROM engine_trans_year
    GROUP BY year
)
SELECT
    e.year,
    e.engine,
    e.transmission,
    e.units,
    e.units::numeric / yt.total_units AS share_of_year
FROM engine_trans_year e
JOIN year_totals yt
  ON e.year = yt.year
ORDER BY e.year, e.engine, e.transmission;

--  Share of Auto and Manual cars did not change much. The market share only shifted by 1% from Auto to Manual.
