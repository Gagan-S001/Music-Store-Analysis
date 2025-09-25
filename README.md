# 🎵 Music-Store-Analysis

📌 Project Overview
This project analyzes the Chinook database (a digital music store) to uncover insights about sales performance, customer behavior, churn rate, and market opportunities.
The goal is to provide data-driven recommendations for boosting sales and improving customer retention in the physical music market.

🗂 Dataset
The dataset is the Chinook sample database, which contains:
-- 11 tables (Albums, Artists, Customers, Employees, Genres, Invoices, InvoiceLines, MediaTypes, Playlists, Tracks, PlaylistTrack)
-- 37K+ records covering sales, customer details, and music catalog
-- Data across 59 countries

🎯 Key Objectives
-- Clean and validate sales & customer data for accuracy
-- Identify top-selling tracks, artists, and genres by country (with focus on USA vs. global markets)
-- Analyze customer demographics, purchasing diversity, and churn rate
-- Calculate regional revenue and highlight profitable markets
-- Recommend albums for promotion, cross-selling opportunities, and customer retention strategies

🛠 Tools & Technologies
-- SQL (queries, joins, window functions, aggregations)
-- Data Cleaning (COALESCE, handling NULLs, standardizing categories)

🔑 Analysis & Insights
1. Data Cleaning & Quality
-- Verified no duplicate records across primary keys
-- Replaced NULL values with placeholders (COALESCE) for consistency (e.g., company → 'NA')

2. Sales Performance
-- Rock and Alternative genres contributed the highest revenue in the USA
-- Top-selling artists and tracks identified → strong customer demand for specific genres/artists

3. Customer Behavior
-- Customers analyzed across 59 countries
-- Identified top 5 customers by spend per country
-- Calculated churn rate of ~18% (customers inactive for last 12 months)
-- Found customers purchasing from 3+ different genres, showing diverse listening preferences

4. Revenue & Regional Analysis
-- USA, Canada, Brazil, and Germany contributed the highest revenues
-- Regional breakdown of invoices and sales helped identify strong vs. weak markets

5. Strategic Recommendations
-- Promote top 3 high-revenue albums in U.S. campaigns
-- Leverage genre/artist/album affinities for product bundling & cross-selling
-- Use customer risk profiling (high/medium/low risk) to design targeted retention strategies


