title 'SAS Workbench demonstration';
title;

/******************************************************************************

Step 1: Importing our Data

 ******************************************************************************/

/****** Import file ******/
proc import datafile = "/workspaces/myfolder/PythonInno/bank.csv"
            out = bank dbms = csv replace;
            guessingrows=30;
run;

/******************************************************************************

Step 2: Exploratory Data Analysis (EDA)

 ******************************************************************************/

/* View the structure and metadata of the dataset */
footnote italic '*Note that Activity_Status and Customer_Value are Char types- might have to encode.';
ods select Variables;
proc contents data=bank;
run;
ods select default;
footnote;

/* Print first 10 rows */
title "First 10 rows of dataset";
proc print data=bank (obs=10);
run;
title;

/* Calculate summary statistics */
title "Summary statistics of Bank";
footnote italic '*Note that there are missing data in Age and AvgSale3Yr_DP.';
proc means data=bank;
run;
footnote;
title;

/* Finding data imbalance */
proc freq data=bank;
    tables Status / out=freq_status;
run;

footnote italic '*Note that data is heavily imbalanced.';
proc sgplot data=freq_status;
    vbar Status / response=Count stat=sum;
    xaxis label='Status';
    yaxis label='Frequency';
    title 'Frequency Distribution of Status';
run;
footnote;

/* Calculate the frequency of each unique value in MnthsLastPur */
proc freq data=bank noprint;
    tables MnthsLastPur / out=freq_mlp;
run;

footnote italic '*Note that most customers wait 15-21 months before purchasing again.'
proc sgplot data=freq_mlp;
    vbar MnthsLastPur / response=Count stat=sum;
    xaxis label='Months Since Last Purchase';
    yaxis label='Frequency';
    title 'Frequency Distribution of Months Since Last Purchase';
run;
footnote;


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

footnote italic "We find that the cutsomer value groups help represent how these 
cutsomers contribute to the firm's sales. Those with high activity 
(buy more often), tend to spend less in their lifetime than those who have an 
average or low activityty status.";
proc sgplot data=avg_sale_life_per_customer;
    vbar Activity_Status / response=AvgSaleLifePerCustomer;
    xaxis label='Activity Status';
    yaxis label='AvgSaleLife per Customer';
    title 'Proportionate AvgSaleLife per Customer by Activity Status';
run;
footnote;

/******************************************************************************

Step 3: Data Wrangling

 ******************************************************************************/

 /****** Imputation ******/
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

/****** Label Encoding ******/
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

data bank_modified;
    set bank_modified;
    format Activity_Status $activityfmt. Customer_Value $custfmt.;
run;


/****** Train/Test Split ******/
title2 'Create training and test data sets with the PARTITION procedure';
proc partition data=bank_modified seed=42
   partind samppct=80;
   output out=bank_modified_part;
run;
title2;

data bank_train(drop=_partind_);
   set bank_modified_part(where=(_partind_=1));
run;

data bank_test(drop=_partind_);
   set bank_modified_part(where=(_partind_~=1));
run;

/* Check if ok
proc print data=bank_train (obs=10);
run; */

/* ***** Keep only the Status variable in bank_test *****
data bank_test_status_only;
    set bank_test(keep=Status);
run;

proc print data=bank_test_status_only (obs=10);
run; */

/****** Export bank_test to CSV ******/
proc export data=bank_test
            outfile="/workspaces/myfolder/PythonInno/bank_test.csv"
            dbms=csv
            replace;
run;


/******************************************************************************

Step 4: Modelling

 ******************************************************************************/


/******************************************************************************

 EXAMPLE:     RANDOM FOREST
 DATA:        bank_train, bank_test
 DESCRIPTION: This data set contains banking data for customers. The goal is to
              to analyze if individual customer purchased an insurance product.
 PURPOSE:     This example shows how to build a regression forest model using
              the FOREST procedure without the need to use a separate cloud-
              based server. It also demonstrates the use of analytic stores as a
              mechanism for saving models and scoring them.

 ******************************************************************************/



 /****** Training a Random Forest Model ******/
title2 'Random Forest on bank_train data';
proc forest data=bank_train ntrees=100 seed=42;
    target Status / level=nominal;
    input Activity_Status Customer_Value Home_Flag / level=nominal;
    input Age Homeval Inc Pr AvgSale3Yr AvgSaleLife	AvgSale3Yr_DP LastProdAmt
        CntPur3Yr CntPurLife CntPur3Yr_DP CntPurLife_DP	CntTotPromo	MnthsLastPur
        Cnt1Yr_DP CustTenure / level=interval;
        id AccountID; /* saves id variable against each prediction- for later matching */
    savestate rstore=foreststore; /*saves the state of proc forest */
run;
title2;

/****** use the ASTORE to score the test data and save the result ******/
title2 'ASTORE describe and scoring';
proc astore;
    describe rstore=foreststore;
    score data=bank_test rstore=foreststore
          out=bank_scoreout;
run;
title2;

/****** Comparing predictions against actual values ******/
title2 'Model Predictions for first 10 Observations';
proc print data=bank_scoreout(obs=10);
run;
title2;


title2 'Actual Values of first 10 obeservations';
proc print data=bank_test (obs=10);
run;
title2;

/****** Saving model as ASTORE file ******/
title2 'Saving the astore into a file';
proc astore;
    download rstore=foreststore store="/workspaces/myfolder/PythonInno/foreststore.sasast";
run;
title2;


/****** Replicating model and Re-Scoring ******/
title2 'Reloading the astore and scoring it';
proc astore;
    upload rstore=foreststore2 store="/workspaces/myfolder/PythonInno/foreststore.sasast";
    describe rstore=foreststore2;
    score data=bank_test rstore=foreststore2 out=bank_scoreout2;
run;
title2;


title2 'Model Predictions for first 5 Observations- re-score';
proc print data=bank_scoreout2(obs=5);
run;
title2;


/******************************************************************************

 The example showed how we can perform SAS® Viya® analytic processes without a
 separate cloud-based server. It also demonstrated the use of saving analytic
 stores into files that can be used by any other product that supports them.
 As a result, a user can use SAS® Viya® Workbench to quickly try out ideas by
 building and testing models, which can then be saved for use in other
 environments as needed.

 ******************************************************************************/



/******************************************************************************

 EXAMPLE:     GRADIENT BOOSTING
 DATA:        bank_train, bank_test
 DESCRIPTION: This data set contains banking data for customers. The goal is to
              to analyze if individual customer purchased an insurance product.
 PURPOSE:     This example shows how to build a gradient boosing model using
              the GRADBOOST procedure without the need to use a separate cloud-
              based server. It also demonstrates the ability for the model to be
              deployed to Model Manager on SAS Viya, ensuring enterprise level
              deployment and model governance is achieved.

 ******************************************************************************/


 /* Gradient Boosting */
proc gradboost data=bank_train ntrees=100;
    target Status / level=nominal;
    input Activity_Status Customer_Value Home_Flag / level=nominal;
    input Age Homeval Inc Pr AvgSale3Yr AvgSaleLife	AvgSale3Yr_DP LastProdAmt
        CntPur3Yr CntPurLife CntPur3Yr_DP CntPurLife_DP	CntTotPromo	MnthsLastPur
        Cnt1Yr_DP CustTenure / level=interval;
        id AccountID; /* saves id variable against each prediction- for later matching */
    savestate rstore=gbstore; /*saves the state of proc forest */
 run;

 /****** use the ASTORE to score the test data and save the result ******/
title2 'ASTORE describe and scoring';
proc astore;
    describe rstore=gbstore;
    score data=bank_test rstore=gbstore
          out=bank_scoreout;
run;
title2;

/****** Comparing predictions against actual values ******/
title2 'Model Predictions for first 10 Observations';
proc print data=bank_scoreout(obs=10);
run;
title2;


title2 'Actual Values of first 10 obeservations';
proc print data=bank_test (obs=10);
run;
title2;

/****** Saving model as ASTORE file ******/
title2 'Saving the astore into a file';
proc astore;
    download rstore=gbstore store="/workspaces/myfolder/PythonInno/gbstore.sasast";
run;
title2;


/****** Authentication ******/
/* get token */
%macro myTokenName() / secure;
"Bearer eyJqa3UiOiJodHRwczovL2xvY2FsaG9zdC9TQVNMb2dvbi90b2tlbl9rZXlzIiwia2lkIjoibGVnYWN5LXRva2VuLWtleSIsInR5cCI6IkpXVCIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIxYTYzOTMzMi0xMDc2LTQ4ZTAtOTNmZC02OGFlMmNlNmEzYzYiLCJzZXNzaW9uX3NpZyI6IjI1YzIyOTE2LWI4ZTQtNDJiNS1iY2RhLWIzMDEwYzlmOGI3YyIsInVzZXJfbmFtZSI6IlR6dS1XZWkuVHNhaUBzYXMuY29tIiwib3JpZ2luIjoiYXp1cmUiLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0L1NBU0xvZ29uL29hdXRoL3Rva2VuIiwiYXV0aG9yaXRpZXMiOlsiU0FTQWRtaW5pc3RyYXRvcnMiLCJDQVNIb3N0QWNjb3VudFJlcXVpcmVkIiwiRGF0YUJ1aWxkZXJzIl0sImNsaWVudF9pZCI6InNhcy5jbGkiLCJhdWQiOlsic2NpbSIsImNsaWVudHMiLCJ1YWEiLCJvcGVuaWQiLCJzYXMuY2xpIl0sImV4dF9pZCI6ImF2c1ZMdVZ1alF3NnRDa1Y0bU45ZTBXMWFiYlRlMDUzYWlIWDBrMDNsZFkiLCJ6aWQiOiJ1YWEiLCJncmFudF90eXBlIjoiaW1wbGljaXQiLCJ1c2VyX2lkIjoiMWE2MzkzMzItMTA3Ni00OGUwLTkzZmQtNjhhZTJjZTZhM2M2IiwiYXpwIjoic2FzLmNsaSIsInNjb3BlIjpbImNsaWVudHMucmVhZCIsImNsaWVudHMuc2VjcmV0IiwidWFhLnJlc291cmNlIiwiU0FTQWRtaW5pc3RyYXRvcnMiLCJvcGVuaWQiLCJjbGllbnRzLndyaXRlIiwidWFhLmFkbWluIiwiY2xpZW50cy5hZG1pbiIsInNjaW0ud3JpdGUiLCJzY2ltLnJlYWQiLCJ1YWEudXNlciJdLCJhdXRoX3RpbWUiOjE3MjExMDI3NzUsImV4cCI6MTcyMTEzODc3NSwiaWF0IjoxNzIxMTAyNzc1LCJqdGkiOiI1OTExNzgyZWYwZjk0MzBhOGRlYTE2NjI5OGQzZjkzZiIsImVtYWlsIjoiVHp1LVdlaS5Uc2FpQHNhcy5jb20iLCJyZXZfc2lnIjoiZDJmY2RhNjMiLCJjaWQiOiJzYXMuY2xpIn0.ieWbKk_3y6Y5zTCgbna98XrIAxvEVaPRfWLpoxtv7xag5xpsx_h9O8E2sZAj1EoEhZpJ7NutqTcmtGeiA8OS0ik5k7p-f2sXS-CMhCZKXiYEwZT22OEBpgSYJPzCOU1aK1re6HkhqwxHaX7vVXRzZux7FbnzOCR1al-FmgaIF7R1GJjvkp-4vsnZGliV8BpXrCku5OQ7WCjp66FILLbj_gRnxbwkGX_V3n2_aIhvvkE--wnoUnf1R4atq6P8zeqIMuaG6SNu7qanB5FSYyk6ye_uRLF7EwQQJ8xzqe_ciqiSNqXGI8whCZOjRdkXYQ-MR_R3NbgAkruh9XSS3SW5TA"
%mend;


/****** Registering the Model ******/
*  create a new MM project and register the model ;
proc registermodel 
      name = "Bank GB"
      description = "Bank Gradient Boosting Astore Model"
      data = bank_train
      algorithm = GRADBOOST
      function = CLASSIFICATION
      server = "https://apgtps2demo.gtp.unx.sas.com"
      oauthtoken = "myTokenName"
      replace;
    project name="InnoSyd2024";
    astoremodel store = "/workspaces/myfolder/PythonInno/gbstore.sasast";
    target Status / level=binary event="1";
    assessment;
run;



*  register to an existing MM project ;
proc registermodel 
      name = "Bank RF"
      description = "Bank Random Forest Astore Model"
      data = bank_train
      algorithm = FOREST
      function = CLASSIFICATION
      server = "https://apgtps2demo.gtp.unx.sas.com"
      oauthtoken = "myTokenName"
      replace;
    project name="InnoSyd2024";
    astoremodel store = "/workspaces/myfolder/PythonInno/foreststore.sasast";
    target Status / level=binary event="1";
    assessment;
run;