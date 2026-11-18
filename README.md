# SokoMart Kenya Advanced SQL — Day 1 and Day 2 Submission

Prepared by: Clarence Gatama  
Cohort: Cohort 9  

## Overview

This README covers the Day 1 and Day 2 work for the SokoMart Kenya Advanced SQL project:

- Practice drills in [sql/00_practice_drills.sql](sql/00_practice_drills.sql)
- Section A: CTEs and subqueries in [sql/section_a_ctes_subqueries.sql](sql/section_a_ctes_subqueries.sql)
- Section B: Window functions in [sql/section_b_window_functions.sql](sql/section_b_window_functions.sql)

Day 1 focused on database setup and analysis using CTEs, correlated subqueries, and anti-join logic. Day 2 uses window functions to rank customers and products, compare monthly growth, track individual customer order changes, and calculate running revenue totals.


## Day 1 results summary

| Item | Result / notes | Screenshot |
|---|---|---|
| Q1 | 3,145 rows returned for customers above the 2025 average spend | [q01-big-spenders-2025.png](screenshots/q01-big-spenders-2025.png) |
| Q2 | 104 premium products above their category average | [q02-premium-priced-products.png](screenshots/q02-premium-priced-products.png) |
| Q3 | 10 rows for monthly 2026 revenue, cost and gross profit | [q03-2026-monthly-p&l.png](screenshots/q03-2026-monthly-p%26l.png) |
| Q4 | 346 rows for Nakuru customers buying across at least 3 categories | [q04-nakuru-cross-category-customers.png](screenshots/q04-nakuru-cross-category-customers.png) |
| Q5 | 8 products were never ordered | [q05-products-not-ordered.png](screenshots/q05-products-not-ordered.png) |

## Day 2 results summary — Section B: Window functions

| Item | Result / notes | Screenshot |
|---|---|---|
| Q6 | 42 rows showing the top 3 customers ranked within each county | [q06-county-leaderboards.png](screenshots/q06-county-leaderboards.png) |
| Q7 | 15 rows showing the top 3 products in each of 5 categories for 2025 | [q07-best-sellers-2025.png](screenshots/q07-best-sellers-2025.png) |
| Q8 | 22 monthly rows showing revenue and month-over-month comparison | [q08-month-over-month-growth.png](screenshots/q08-month-over-month-growth.png) |
| Q9 | 393 Nyeri customer orders compared with each customer's previous completed order | [q09-nyeri-customer-order-comparison.png](screenshots/q09-nyeri-customer-order-comparison.png) |
| Q10 | 22 yearly-monthly rows showing revenue and running revenue totals | [q10-yearly-monthly-running-revenue-total.png](screenshots/q10-yearly-monthly-running-revenue-total.png) |

## Business insights from Day 1

- High-value customers are concentrated, with 3,145 customers above the 2025 average spend; this suggests that a relatively small segment drives most revenue (Q1).
- Premium pricing is not evenly spread across categories: 104 products sit above their category average, indicating opportunities for category-specific pricing decisions (Q2).
- The monthly profit view in Q3 shows that gross profit changes materially by month, so SokoMart should align promotions and inventory planning with the strongest profit periods (Q3).
- There are 346 Nakuru customers who bought from at least 3 categories, making cross-category bundles a practical retention and sales opportunity (Q4).
- Q5 identifies 8 products that were never ordered: Beauty has 5, Fashion 5, Groceries 4, Electronics 3, and Home Appliances 1. This points to slow-moving stock and assortment-planning reviews, especially in Beauty and Fashion.

## Business insights from Day 2

- Q6 returns 42 county leaderboard entries because each county can contribute up to 3 ranked customers. SokoMart can use this result to design county-level loyalty or retention campaigns.
- Q7 identifies 15 leading products, 3 from each of 5 categories, for 2025. These products should receive priority in stocking, promotion, and online merchandising decisions.
- Q8 provides month-over-month comparisons across 22 months. This gives SokoMart a long enough period to identify recurring high-growth and low-growth months rather than evaluating only one month at a time.
- Q9 analyses 393 completed Nyeri orders against the customer's previous order. The up, down, or same classifications can help the business identify changes in customer basket behavior and target customers whose order values are declining.
- Q10 produces 22 monthly running-revenue results. The within-year YTD calculation is useful for sales reviews, while the all-time running total provides a cumulative view of completed-order revenue over the dataset.

