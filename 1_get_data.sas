options compress=yes; 
options YEARCUTOFF=1970; 
libname lib "/folders/myfolders/codes";

%macro rg (file);
/* 1. import dataset */
proc import datafile="/folders/myfolders/codes/&file..csv"
dbms=csv out=lib.&file. replace; GUESSINGROWS=45000; run;
/* proc contents data=lib.&file.; run;  */

/* 2. emp_length */
/* proc freq data=lib.&file.; table emp_length; run;  */
data lib.&file. (drop=emp_length); set lib.&file.; 
emp_length1 = compress(emp_length);
emp_length1 = translate(emp_length1,'','+years');
emp_length1 = translate(emp_length1,'','years');
emp_length1 = translate(emp_length1,'','year');
if emp_length1 in ('<1','') then emp_length1 = '0'; run;
data lib.&file. (drop=emp_length1); set lib.&file.;
emp_length = input(emp_length1,best32.); run;
proc freq data=lib.&file.; table emp_length; run; 

/* 3. term */
/* proc freq data=lib.&file.; table term; run;  */
data lib.&file. (drop=term); set lib.&file.; 
term1 = compress(term);
term1 = translate(term1,'','months'); run;
data lib.&file. (drop=term1); set lib.&file.;
term = input(term1,best32.); run;
proc freq data=lib.&file.; table term; run; 

/* 4. earliest_cr_line */
data lib.&file. (drop=earliest_cr_line); set lib.&file.; 
mnths_earliest_cr_line = intck('month',earliest_cr_line,'01DEC2017'd); run;
proc means data=lib.&file.; var mnths_earliest_cr_line; run;
data lib.&file.; set lib.&file.; 
if mnths_earliest_cr_line < 0 then mnths_earliest_cr_line = 575; run; 
proc means data=lib.&file.; var mnths_earliest_cr_line; run;

/* 5. issue_d */
data lib.&file. (drop=issue_d); set lib.&file.; 
mnths_issue_d = intck('month',issue_d,'01DEC2017'd); run;
proc means data=lib.&file.; var mnths_issue_d; run;

/* 6. discrete */
%macro discrete (var);
proc freq data=lib.&file.; table &var.; run;
%mend;
%discrete(addr_state);
%discrete(grade);
%discrete(home_ownership);
%discrete(initial_list_status);
%discrete(loan_status);
%discrete(purpose);
%discrete(sub_grade);
%discrete(verification_status);

/* 7. total_rev_hi_lim */
data lib.&file. (drop=total_rev_hi_lim1); set lib.&file. (rename=(total_rev_hi_lim = total_rev_hi_lim1)); 
total_rev_hi_lim = input(total_rev_hi_lim1, best32.); run; 
data lib.&file.; set lib.&file.; 
if total_rev_hi_lim = . then total_rev_hi_lim = funded_amnt; run; 
proc sql; select count(total_rev_hi_lim) as cnt 
from lib.&file. where total_rev_hi_lim ne .; quit;

/* 8. annual_inc - 4 missing in 2007_2014 & 0 missing in 2015*/
data lib.&file.; set lib.&file.; if annual_inc = . then annual_inc = 73277.38; run; 
proc means data=lib.&file.; var annual_inc; run;

/* 9. replace with zero */
%macro replace0 (var);
data lib.&file.; set lib.&file.; if &var. = . then &var. = 0; run; 
proc means data=lib.&file.; var &var.; run;
%mend; 
%replace0(acc_now_delinq);
%replace0(delinq_2yrs);
%replace0(mnths_earliest_cr_line);
%replace0(emp_length);
%replace0(inq_last_6mths);
%replace0(open_acc);
%replace0(pub_rec);
%replace0(total_acc);

%mend; 
%rg(loan_data_2007_2014);
%rg(loan_data_2015); 

