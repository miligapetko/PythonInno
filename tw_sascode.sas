/* Import CSV file */
proc import datafile = "/workspaces/myfolder/PythonInno/Bank_Score.csv"
            out = dataset1 /* Specify the SAS dataset name */
            dbms = csv     /* Specify the type of file */
            replace;       /* Replace the dataset if it exists */
run;