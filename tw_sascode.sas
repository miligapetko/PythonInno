/* 

Step 2: Importing our Data

 */

/* Import CSV file */
proc import datafile = "/workspaces/myfolder/PythonInno/bank.csv"
            out = bank /* Specify the SAS dataset name */
            dbms = csv     /* Specify the type of file */
            replace;       /* Replace the dataset if it exists */
run;

/* 

Step 3: Exploratory Data Analysis (EDA)

 */

/* View the structure and metadata of the dataset */
ods select Variables; *tell ODS to ONLY deliver the variable attribute table;
proc contents data=bank;
run;
ods select default; *reset back to default;

*Note that will need to do some parsing and formatting;

/* List first 10 rows */
title "First 10 rows of dataset";
proc print data=bank (obs=10);
run;
title; *null title statement to reset;

/* Calculate summary statistics */
proc means data=bank;
run;

*Note that there are missing data in Age and AvgSale3Yr_DP;

/* Examine distribution of data, discover outliers */
proc univariate data=bank;
run;

/* Finding data imbalance */
/* Step 1: Generate the frequency table */
proc freq data=bank;
    tables Status / out=freq_status;
run;

/* Step 2: Create a bar chart from the frequency dataset */
proc sgplot data=freq_status;
    vbar Status / response=Count stat=sum;
    xaxis label='Status';
    yaxis label='Frequency';
    title 'Frequency Distribution of Status';
run;



*# Calculate the frequency of each unique value in MnthsLastPur;
/* Step 1: Generate the frequency table */
proc freq data=bank noprint;
    tables MnthsLastPur / out=freq_mlp;
run;

/* Step 2: Create a bar chart from the frequency dataset */
proc sgplot data=freq_mlp;
    vbar MnthsLastPur / response=Count stat=sum;
    xaxis label='Months Since Last Purchase';
    yaxis label='Frequency';
    title 'Frequency Distribution of Months Since Last Purchase';
run;


/* Correlation matrix */
/* Compute the correlation matrix */
proc corr data=bank;
    var _numeric_;
run;
