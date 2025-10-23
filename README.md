
- Shortcut keys!!!
- Rename in scope
- ctrl,shift,c - comment out
- https://www.dataquest.io/blog/rstudio-tips-tricks-shortcuts/#:~:text=Another%20way%20to%20access%20RStudio,%2B%20%2D%20on%20Linux%20and%20Windows.


https://www.markhw.com/blog/logos

🗓️ Updated Two-Day Schedule (v3 – Emphasizing Inspect → Summarize → Clean → Assert)

Day 1 – From Raw Data to Clean, Reproducible Datasets
Time	Topic	Key Learning Goals	Notes / Integration

✓ 9:00 – 9:30	Welcome & RStudio Setup	Workshop overview. Create an RStudio Project. Explore panes, scripts, and the working directory.
Make RStudio feel like home.

# Script organisation and fun shortcut keys?
 

9:30 – 10:15	Organizing Projects & Data Management Planning	
- spreadsheets -  & data dictionaries
- what if my data isn't tidy?
- project structure and folders (fs)
- library(fs)   # https://fs.r-lib.org/.  fs is a cross-platform, uniform interface to file system operations via R. 
dir_create("data")
dir_create("data_output")
dir_create("fig_output")
- Participants create a simple project template (data/, scripts/, outputs/).
- Reproducibility mindset. (.data, styler, commenting and shortcut keys?)


10:15 – 10:45	Loading and Inspecting Data	Load a CSV (or Excel) file with readr::read_csv() / readxl::read_excel(). Use glimpse(), head(), nrow(), ncol(), summary() to explore.	Goal: make sure data successfully load and participants feel oriented.

Read excel options?
Read delim
readr vs baser - speed and tibbles vs dataframe

Basic inspection of data: counts by groups and times. distinct counts? n_distinct?


### Mostly written below but needs reorganising and checking!!!

10:45 – 11:00	☕ Break		

✓  11:00 – 11:45	First Steps with tidyverse: Simple Summaries	Introduce filter(), select(), count(), summarise(), group_by(). 

??? Calculate means, SDs, counts.	Keep it lightweight and exploratory; visual reward via ggplot2::geom_point() or geom_bar().

11:45 – 12:30	General Data Cleaning I – Structure & Consistency	

??? Review column types (str(), as.numeric(), etc.), rename columns (janitor::clean_names()), 

✓  Factors! reorder variables.

12:30 – 1:30	🍽️ Lunch		

1:30 – 2:30	General Data Cleaning II 

– Duplicates - n and n_distinct? duplicated, get_dupes
Missing Values, 
Strings, 
Dates	
Identify and handle duplicates (distinct()), 
missing values (drop_na(), replace_na()), 
text standardization (str_to_lower()), 
parse dates (lubridate)..

??? Possibility - clean a messy dataset???

2:30 – 2:45	☕ Break		

2:45 – 3:15	Assertions and Automated Checks	✅ Introduce assertr. Teach the idea of embedding expectations after cleaning.
Key functions: verify(), assert(), insist().
Example: r data %>% verify(nrow(.) > 0) %>% assert(in_set(c("control","treatment")), group) %>% insist(within_bounds(0,100), percent_yield)	Show what happens when assertions fail; emphasize reproducibility.

3:15 – 4:15	Introduction to ggplot2 - 

Themes, fonts and accessibility + my earlier stuff 5023B

# https://www.cararthompson.com/talks/nhsr2022-ggplot-themes/

https://www.cararthompson.com/talks/on-brand-accessibility/

https://albert-rapp.de/posts/ggplot2-tips/12_a_few_gg_packages/12_a_few_gg_packages.html

4:15 – 4:45	Mini-practice

4:45 – 5:00	Wrap-Up & Discussion	Reflect on workflow: “Set assignment"

Day 2 – Modeling, Interpretation, and Reproducibility

Time	Topic	Key Learning Goals	Notes / Integration
9:00 – 9:15	Recap of Day 1	Review tidy workflow and QC.	

9:15 – 10:15	Introduction to Statistical Models	Linear model logic, fit with lm(), visualize predictions.	Show that modeling depends on verified, clean data.
# SD and SE?

10:15 – 10:30	☕ Break		

10:30-1100 Visualizing Model Predictions	broom + ggplot2 for fitted vs. observed.
stat_summary()

11-11.45	GLMs for Binary Data
# Why cant we use t-tests?

11.45-12.30 	GLMs for Count Data

12:30 – 13:30	🍽️ Lunch

13.30 - 14.15 Random Effects (Conceptual)	Explain why batch/plate/subject vary.	Visual demonstration.


14:15 – 15.00	Power and Sample Size via Simulation	Intuitive demonstration of power.	
Errors and simulation of p-values?

3:00 – 3:15	☕ Break		

3:15 – 16.00	Equivalence Testing (Optional)	Conceptual overview.	

16.00-16.30 Reproducible Reporting with Quarto	Build a report combining code, plots, assertions, and results.
Include a chunk showing QC with assertr.


4:30 – 5:00	Wrap-Up & Next Steps	Reflection, feedback, resources.	
