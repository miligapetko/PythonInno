data work.ds_testgrades;
	infile datalines dlm=',';
	input name $ percentage;
	datalines;
Maria, 60
John, 95
Will, .
Tess, 87
Donald, 40
Emma, 72
;
run;
 
proc format;
	value percentage_fmt
		0 - 59 = "F"
		60 - 69 = "D"
		70 - 79 = "C"
		80 - 89 = "B"
		90 - 100 = "A"
		other = "NO SCORE";
run;
 
data work.ds_testgrades_fmt;
	set work.ds_testgrades;
 
	letter_grade = put(percentage, percentage_fmt.);
run;

proc contents data=work.ds_testgrades_fmt;
run;

proc print data=work.ds_testgrades_fmt;
run;