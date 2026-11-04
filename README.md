# Olist Late Delivery Analysis


## Project Overview
This project analyzes about 96,000 delivered orders from Olist, a Brazilian e-commerce marketplace, to understand where late deliveries come from, what they cost in customer reviews, and which fix would avoid the most late orders. The analysis follows an order from purchase to delivery, comparing the actual delivery date with the date promised to the customer, and then looks at how lateness varies by destination state, seller-to-customer route, and delivery time bucket. Review scores and a simple savings scenario are used to measure the impact of late delivery.

**Live dashboard:** https://public.tableau.com/app/profile/ethan.ly5072/viz/OlistLateDeliveryAnalysis_17937653336460/Dashboard1

## Tools Used
SQL (DuckDB), Excel, Tableau Public

## Dataset
[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), covering orders from 2016 to 2018. It contains nine related tables: orders, order items, payments, reviews, customers, sellers, products, geolocation, and product category translations.

Key fields include purchase, delivery, and estimated delivery dates, customer and seller state, item price and freight value, product category, and review scores and comments. After filtering to delivered orders there are 96,470 orders. The raw CSVs are not included in this repo and can be downloaded from Kaggle.

### State Codes
All codes are Brazilian states. A lane is seller state to customer state, so "SP to RJ" means a seller in São Paulo shipping to a customer in Rio de Janeiro.

AC Acre, AL Alagoas, AM Amazonas, AP Amapá, BA Bahia, CE Ceará, DF Distrito Federal, ES Espírito Santo, GO Goiás, MA Maranhão, MG Minas Gerais, MS Mato Grosso do Sul, MT Mato Grosso, PA Pará, PB Paraíba, PE Pernambuco, PI Piauí, PR Paraná, RJ Rio de Janeiro, RN Rio Grande do Norte, RO Rondônia, RR Roraima, RS Rio Grande do Sul, SC Santa Catarina, SE Sergipe, SP São Paulo, TO Tocantins

## Project Goals
- Measure how often orders are delivered late, and where
- Test whether late delivery lowers review scores, and by how much
- Identify which sellers and seller-to-customer routes (lanes) drive the most lateness
- Compare actual delivery time with the promised delivery time
- Look at freight cost relative to item price
- Review what customers say in written reviews about their orders
- Estimate what fixing the worst lane would be worth

## Data Analysis

### Data Preparation
SQL was used to load the nine tables into DuckDB and run data quality checks: order statuses, duplicate orders, missing delivery dates, and orders with multiple reviews or sellers. A single clean table was then built with one row per delivered order, combining customer and seller state, price and freight, average review score, delivery days, and a late flag. Building it this way avoids double counting when an order has several items, sellers, or reviews.

### Late Delivery Analysis
An order is counted as late when it was delivered after its estimated delivery date. Late rates were calculated overall and by destination state, product category, and same-state versus cross-state shipping.

### Review Impact
Review scores were compared across on-time orders and orders that were 1-3, 4-7, and 8 or more days late, using both the average score and the share of 1 and 2 star reviews.

### Seller and Lane Analysis
Seller performance was summarized in a scorecard, along with how concentrated late orders are among sellers. Lanes (seller state to customer state) were compared by order volume and late rate, with small lanes filtered out of the key views so low-volume noise does not dominate.

### Promised vs Actual Delivery
Average promised and actual delivery days were compared by state, and median and 90th percentile delivery times were compared against the promise to see whether lateness comes from the typical order or from the slow tail.

### Freight and Review Text
Freight cost was compared with item price by product category, destination state, and same-state versus cross-state shipping. Written reviews were grouped into themes with keyword rules (such as delivery delay, order not received, damaged, wrong or missing item).

### Scenario Model
An Excel model uses XLOOKUP over a lane table to estimate the value of bringing a lane's late rate down to that of a comparable lane, with mild, medium, and ambitious scenarios.

## Dashboard Features
**Late Delivery Overview**
Built a Tableau dashboard with headline numbers (96,470 orders analyzed, 6.8% delivered late, average review of 4.29 on time versus 2.27 late) and four charts: late rate by destination state, average review by how late an order was, late rate by seller-to-customer lane, and promised versus actual delivery days by state.

**What This Means**
Added a short summary box and a footnote that explain the main findings and the limits of the data.

## Key Insights
- **6.8% of delivered orders (6,534) arrived after the estimated date.**
- **Late delivery goes with much worse reviews.** Average review is 4.29 for on-time orders versus 3.29 (1-3 days late), 2.11 (4-7 days late), and 1.70 (8+ days late). The share of 1 and 2 star reviews rises from 9.2% on time to 79.2% at 8+ days late.
- **Lateness is a lane problem.** The worst high-volume lanes are mostly São Paulo sellers shipping to the North and Northeast (for example SP to MA at 19.1% and SP to PI at 16.4%) and to Rio (SP to RJ at 14.1%, PR to RJ at 12.1%). Same-state shipping is much better (SP to SP is about 4.6%).
- **Rio de Janeiro stands out.** It is close to São Paulo, where most sellers are, yet it has a 12.1% late rate across 12,350 orders, about 23% of all late orders. Distance alone does not explain it.
- **Average delivery beats the promise in every state.** Late orders come from a slow tail, so averages hide the problem.
- **A targeted fix is worth modeling.** In the medium scenario, bringing the SP to RJ lane (8,157 orders, 14.1% late) down to the level of a comparable lane (SP to MG, about 5.3%) avoids roughly 722 late orders (11% of all late orders) and about 384 bad reviews, based on the observed 62.4% versus 9.2% bad-review rates for late versus on-time orders.

## Recommendation
Focus first on the lanes into Rio and the Northeast, where the most late orders can be avoided, and set more realistic promised dates for the slowest lanes. Prioritize the 8+ day delays, which do the most damage to reviews.

## Limitations
- Results show association, not proof of cause. Review scores depend on more than delivery time.
- The data covers one marketplace from 2016 to 2018 and has no conversion or repeat-purchase data, so the model estimates review impact only, not revenue.
- Orders with several sellers are attributed to one seller.
- Review keyword rules were not hand-validated beyond fixing one error, so text findings are directional.
- States with very few orders (such as RR, AP, and AC) have unstable rates.
- Savings figures come from a simple scenario model, not a forecast.

## Project Takeaways
I used SQL, Excel, and Tableau to analyze delivery performance and build a dashboard. The project helped me practice building a clean analysis table that avoids double counting, comparing segments by rate and volume instead of raw counts, and turning a finding into a simple savings estimate. It also gave me experience checking my own work, such as fixing a keyword rule that was overcounting delays, and being clear about what the data can and cannot show.

## Repo Contents
| File | What it does |
|---|---|
| `01_load_and_checks.sql` | Loads the nine CSVs into DuckDB and checks row counts |
| `02_checks.sql` | Data quality checks: statuses, duplicates, missing dates, multiple reviews and sellers |
| `03_orders_enriched.sql` | Builds one clean row per delivered order with state, price, freight, review, and late flag |
| `04_findings.sql` | Analysis queries: late rates, lanes, reviews, sellers, freight, promised vs actual |
| `05_exports.sql` | Builds scorecards and exports CSVs for Tableau |
| `savings_model.xlsx` | Lane table and scenario model |
