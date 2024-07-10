/* Import CSV file */
proc import datafile = "/workspaces/myfolder/PythonInno/bank.csv"
            out = bank /* Specify the SAS dataset name */
            dbms = csv     /* Specify the type of file */
            replace;       /* Replace the dataset if it exists */
run;

/* View the structure and metadata of the dataset */
proc contents data = bank;
run;

*Note that will need to do some parsing and formatting;

/* List first 10 rows */
proc print data = bank (obs=10);
run;

/* Calculate summary statistics */
proc means data = bank;
run;

*Note that there are missing data in Age and AvgSale3Yr_DP;

/* Examine distribution of data, discover outliers */
proc univariate data = bank;
run;

/* Find frequency for categorical variables */
proc freq data = bank;
    tables Activity_Status Customer_Value Home_Flag Status;
run;

