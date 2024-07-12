title 'SAS Workbench demonstration';
title;

/******************************************************************************

Step 1: Importing our Data

 ******************************************************************************/

/* Import CSV file */
proc import datafile = "/workspaces/myfolder/PythonInno/bank.csv"
            out = bank
            dbms = csv
            replace;
            guessingrows=30;
run;

/******************************************************************************

Step 2: Exploratory Data Analysis (EDA)

 ******************************************************************************/

/* View the structure and metadata of the dataset */
ods select Variables;
proc contents data=bank;
run;
ods select default;

/* List first 10 rows */
title "First 10 rows of dataset";
proc print data=bank (obs=10);
run;
title;

/* Calculate summary statistics */
proc means data=bank;
run;

*Note that there are missing data in Age and AvgSale3Yr_DP;

/* Finding data imbalance */
proc freq data=bank;
    tables Status / out=freq_status;
run;

proc sgplot data=freq_status;
    vbar Status / response=Count stat=sum;
    xaxis label='Status';
    yaxis label='Frequency';
    title 'Frequency Distribution of Status';
run;

/* Calculate the frequency of each unique value in MnthsLastPur */
proc freq data=bank noprint;
    tables MnthsLastPur / out=freq_mlp;
run;

proc sgplot data=freq_mlp;
    vbar MnthsLastPur / response=Count stat=sum;
    xaxis label='Months Since Last Purchase';
    yaxis label='Frequency';
    title 'Frequency Distribution of Months Since Last Purchase';
run;

/* Compute the correlation matrix */
/* NOT COMPLETE YET!!!!!!!!!!!!! */
proc corr data=bank noprob nosimple;
    var _numeric_;
run;


/* Graph for Customer Value Groups by Activity Status */
proc sgplot data=bank;
    vbar Customer_Value /  
        group=Activity_Status 
        nostatlabel
        groupdisplay=cluster;
    xaxis label='Customer Value';
    yaxis label='Count';
    title 'Customer Value Groups by Activity Status';
run;

/* Graph for Proportionate AvgSaleLife per Customer by Activity Status */
proc means data=bank noprint;
    class Activity_Status;
    var AvgSaleLife;
    output out=sum_count
        mean=TotalSum
        n=Count;
run;

data avg_sale_life_per_customer;
    set sum_count;
    AvgSaleLifePerCustomer = TotalSum / Count;
run;

proc sgplot data=avg_sale_life_per_customer;
    vbar Activity_Status / response=AvgSaleLifePerCustomer;
    xaxis label='Activity Status';
    yaxis label='AvgSaleLife per Customer';
    title 'Proportionate AvgSaleLife per Customer by Activity Status';
run;


/******************************************************************************

Step 3: Data Wrangling

 ******************************************************************************/

 /* Imputation */
 /* Step 1: Calculate the mean for the numeric columns Age and AvgSale3Yr_DP */
proc means data=bank noprint;
   var Age AvgSale3Yr_DP;
   output out=means_result mean=mean_Age mean_AvgSale3Yr_DP;
run;

/* Step 2: Impute missing values with the calculated means */
data bank_modified;
   set bank;
   if _N_ = 1 then set means_result;  /* Reads means_result dataset once */
   
   if missing(Age) then Age = mean_Age;
   if missing(AvgSale3Yr_DP) then AvgSale3Yr_DP = mean_AvgSale3Yr_DP;
run;

/* Label Encoding */
/* Step 1: Define formats for encoding labels */
proc format;
    value $activityfmt
        'High' = '1'
        'Average' = '2'
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


/* Train/Test Split */
/* Split the dataset into training (80%) and testing (20%) */
proc surveyselect data=bank_modified 
                  out=train_test_split 
                  samprate=0.80 
                  outall 
                  seed=42;
run;

/* Create separate datasets for training and testing */
data train test;
    set train_test_split;
    if Selected then output train; /* Selected = 1 for training set */
    else output test; /* Selected = 0 for testing set */
run;

proc print data=bank_modified (obs=20);
run;


/******************************************************************************

Step 4: Modelling

 ******************************************************************************/

 /* Gradient Boosting */
 proc gradboost data=train ntrees=100;
    input Age Homeval Inc Pr AvgSale3Yr AvgSaleLife	AvgSale3Yr_DP LastProdAmt
        CntPur3Yr CntPurLife CntPur3Yr_DP CntPurLife_DP	CntTotPromo	MnthsLastPur
        Cnt1Yr_DP CustTenure / level=nominal;
    input Activity_Status Customer_Value Home_Flag / level=interval;
    target Status / level=interval;
    seed=42;
 run;