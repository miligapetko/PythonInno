/* 

Step 2: Importing our Data

 */

/* Import CSV file */
proc import datafile = "/workspaces/myfolder/PythonInno/bank.csv"
            out = bank /* Specify the SAS dataset name */
            dbms = csv     /* Specify the type of file */
            replace;       /* Replace the dataset if it exists */
run;

/* Modify the length of the character column Activity_Status */
/* NOT COMPLETE YET!!!!!!!!!!!!! */
data bank;
    length Activity_Status $ 7; /* Set the length of Activity_Status to 7 characters */
    set bank;                   /* Read in the original dataset */
run; *this code doesn't help;



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
/* NOT COMPLETE YET!!!!!!!!!!!!! */
/* Compute the correlation matrix */
proc corr data=bank;
    var _numeric_;
run;


/* Graph for Customer Value Groups by Activity Status */
/* NOT COMPLETE YET!!!!!!!!!!!!! */


/* Graph for Proportionate AvgSaleLife per Customer by Activity Status */
/* NOT COMPLETE YET!!!!!!!!!!!!! */



/* 

Step 4: Data Wrangling

 */


 /* Imputation */
 /* Step 1: Calculate the mean for the numeric columns Age and AvgSale3Yr_DP */
proc means data=bank noprint;
   var Age AvgSale3Yr_DP;
   output out=means_result mean=mean_Age mean_AvgSale3Yr_DP;
run;

/* Step 2: Impute missing values with the calculated means */
data bank_modified;
   set bank;
   /* Retrieve the means from the means_result dataset */
   if _N_ = 1 then set means_result;
   
   /* Impute missing values */
   if missing(Age) then Age = mean_Age;
   if missing(AvgSale3Yr_DP) then AvgSale3Yr_DP = mean_AvgSale3Yr_DP;
run;

/* Label Encoding */
/* Step 1: Define formats for encoding labels */
proc format;
    value $activityfmt
        'High' = '1'
        'Aver' = '2' /*need to format correctly at start*/
        'Low' = '3';
        
    value $custfmt
        'A' = '1'
        'B' = '2'
        'C' = '3'
        'D' = '4'
        'E' = '5';
run;

/* Step 2: Apply formats to the dataset */
data bank_modified;
    set bank_modified; /* Read in the original dataset */
    
    /* Apply formats to encode labels */
    format Activity_Status $activityfmt. Customer_Value $custfmt.;
run;
