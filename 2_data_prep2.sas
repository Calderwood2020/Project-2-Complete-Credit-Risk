options compress=yes; 
options YEARCUTOFF=1970;
libname lib "/folders/myfolders/codes";
proc contents data=lib.loan_data_2007_2014_train; run; 

/* 1. rank ordering */
%let file = loan_data_2007_2014_train;
%macro rank0(var); 
proc rank data=lib.&file. groups=50 out=temp; 
var &var.; ranks f_&var.; run; 
proc sql; create table &var. as select f_&var., 
avg(&var.) as avg_var, min(&var.) as min_var, max(&var.) as max_var, 
count(good_bad) as cnt, sum(good_bad) as cnt_good, avg(good_bad) as avg_good
from temp group by f_&var.; quit; 
data &var.; set &var.; cnt_bad = cnt - cnt_good; run; 
proc sql; create table &var. as select f_&var., avg_var, min_var, max_var, cnt,
cnt_good / sum(cnt_good) as good, cnt_bad / sum(cnt_bad) as bad
from &var.; quit; 
data &var.; set &var.; WOE = log(good/bad); IV = (good-bad)*WOE; run; 
proc sql; create table &var. as select f_&var., avg_var, min_var, max_var, cnt,
WOE, sum(IV) as IV from &var.; quit; 
proc sort data=&var.; by avg_var; run; 
%mend; 

%rank0(mnths_issue_d);
%rank0(int_rate);
%rank0(annual_inc);
%rank0(mths_since_last_delinq);

%macro rg (file);
data lib.&file.; set lib.&file.; 
/* 2. mnths_issue_d */
format f_mnths_issue_d $20.; 
if mnths_issue_d <= 37 then f_mnths_issue_d = '0-37'; 
else if mnths_issue_d <= 39 then f_mnths_issue_d = '38-39'; 
else if mnths_issue_d <= 41 then f_mnths_issue_d = '40-41'; 
else if mnths_issue_d <= 48 then f_mnths_issue_d = '42-48'; 
else if mnths_issue_d <= 52 then f_mnths_issue_d = '49-52'; 
else if mnths_issue_d <= 64 then f_mnths_issue_d = '53-64'; 
else if mnths_issue_d <= 85 then f_mnths_issue_d = '65-85'; 
else f_mnths_issue_d = '86+'; 

/* 3. int_rate */
format f_int_rate $20.; 
if int_rate <= 9.548 then f_int_rate = '0-9.548'; 
else if int_rate <= 12.025 then f_int_rate = '9.548-12.025'; 
else if int_rate <= 15.740 then f_int_rate = '12.025-15.740'; 
else if int_rate <= 20.281 then f_int_rate = '15.740-20.281';  
else f_int_rate = '20.281+'; 

/* 4. annual_inc */
format f_annual_inc $20.; 
if annual_inc <=20000 then f_annual_inc = '0-20K'; 
else if annual_inc <=30000 then f_annual_inc = '20-30K'; 
else if annual_inc <=40000 then f_annual_inc = '30-40K'; 
else if annual_inc <=50000 then f_annual_inc = '40-50K'; 
else if annual_inc <=60000 then f_annual_inc = '50-60K'; 
else if annual_inc <=70000 then f_annual_inc = '60-70K'; 
else if annual_inc <=80000 then f_annual_inc = '70-80K'; 
else if annual_inc <=90000 then f_annual_inc = '80-90K'; 
else if annual_inc <=100000 then f_annual_inc = '90-100K'; 
else if annual_inc <=120000 then f_annual_inc = '100-120K'; 
else if annual_inc <=140000 then f_annual_inc = '120-140K'; 
else f_annual_inc = '140+K'; 

/* 5. mths_since_last_delinq */
format f_mths_since_last_delinq $20.; 
if mths_since_last_delinq = . then f_mths_since_last_delinq = 'MISSING'; 
else if mths_since_last_delinq <= 3 then f_mths_since_last_delinq = '0-3'; 
else if mths_since_last_delinq <= 30 then f_mths_since_last_delinq = '4-30'; 
else if mths_since_last_delinq <= 56 then f_mths_since_last_delinq = '31-56';  
else f_mths_since_last_delinq = '57+'; 

/* 6. dti */
format f_dti $20.;
if dti <= 1.4 then f_dti = '0-1.4';
else if dti <= 3.5 then f_dti = '1.4-3.5';
else if dti <= 7.7 then f_dti = '3.5-7.7';
else if dti <= 10.5 then f_dti = '7.7-10.5';
else if dti <= 16.1 then f_dti = '10.5-16.1';
else if dti <= 20.3 then f_dti = '16.1-20.3';
else if dti <= 21.7 then f_dti = '20.3-21.7';
else if dti <= 22.4 then f_dti = '21.7-22.4';
else if dti <= 35 then f_dti = '22.4-35';
else f_dti = '35+';

/* 7. mths_since_last_record */
format f_mths_since_last_record $20.;
if mths_since_last_record = . then f_mths_since_last_record = 'MISSING';
else if mths_since_last_record <= 2 then f_mths_since_last_record = '0-2';
else if mths_since_last_record <= 20 then f_mths_since_last_record = '2-20';
else if mths_since_last_record <= 31 then f_mths_since_last_record = '20-31';
else if mths_since_last_record <= 80 then f_mths_since_last_record = '31-80';
else if mths_since_last_record <= 86 then f_mths_since_last_record = '80-86';
else f_mths_since_last_record = '86+';

/* 8. mnths_earliest_cr_line */
format f_mnths_earliest_cr_line $20.;
if mnths_earliest_cr_line < 141 then f_mnths_earliest_cr_line = '0-140';
else if mnths_earliest_cr_line < 165 then f_mnths_earliest_cr_line = '141-164';
else if mnths_earliest_cr_line < 248 then f_mnths_earliest_cr_line = '165-247';
else if mnths_earliest_cr_line < 271 then f_mnths_earliest_cr_line = '248-270';
else if mnths_earliest_cr_line < 353 then f_mnths_earliest_cr_line = '271-352';
else f_mnths_earliest_cr_line = '353+';

/* 9. delinq_2yrs */
format f_delinq_2yrs $20.;
if delinq_2yrs = 0 then f_delinq_2yrs = '0';
else if delinq_2yrs <= 3 then f_delinq_2yrs = '1-3';
else f_delinq_2yrs = '4+';

/* 10. delinq_2yrs */
format f_inq_last_6mths $20.;
if inq_last_6mths = 0 then f_inq_last_6mths = '0';
else if inq_last_6mths <= 2 then f_inq_last_6mths = '1-2';
else if inq_last_6mths <= 6 then f_inq_last_6mths = '3-6';
else f_inq_last_6mths = '7+';

/* 11. total_rev_hi_lim */
format f_total_rev_hi_lim $20.;
if total_rev_hi_lim <= 5000 then f_total_rev_hi_lim = '0-5K';
else if total_rev_hi_lim <= 10000 then f_total_rev_hi_lim = '5-10K';
else if total_rev_hi_lim <= 20000 then f_total_rev_hi_lim = '10-20K';
else if total_rev_hi_lim <= 30000 then f_total_rev_hi_lim = '20-30K';
else if total_rev_hi_lim <= 40000 then f_total_rev_hi_lim = '30-40K';
else if total_rev_hi_lim <= 55000 then f_total_rev_hi_lim = '40-55K';
else if total_rev_hi_lim <= 95000 then f_total_rev_hi_lim = '55-95K';
else f_total_rev_hi_lim = '95K+';

/* 12. acc_now_delinq */
if acc_now_delinq = 0 then f_acc_now_delinq = '0';
else f_acc_now_delinq = '1';

/* 13. open_acc */
format f_open_acc $20.;
if open_acc = 0 then f_open_acc = '0';
else if open_acc <= 3 then f_open_acc = '1-3';
else if open_acc <= 12 then f_open_acc = '4-12';
else if open_acc <= 17 then f_open_acc = '13-17';
else if open_acc <= 22 then f_open_acc = '18-22';
else if open_acc <= 25 then f_open_acc = '23-25';
else if open_acc <= 30 then f_open_acc = '26-30';
else f_open_acc = '31+';

/* 14. pub_rec */
format f_pub_rec $20.;
if pub_rec <= 2 then f_pub_rec = '0-2';
else if pub_rec <= 4 then f_pub_rec = '3-4';
else f_pub_rec = '5+';

/* 15. total_acc */
format f_total_acc $20.; 
if total_acc <= 27 then f_total_acc = '0-27';
else if total_acc <= 51 then f_total_acc = '28-51';
else f_total_acc = '52';
run;

%mend; 
%rg(loan_data_2007_2014_train);
%rg(loan_data_2007_2014_test);
%rg(loan_data_2015_train); 
%rg(loan_data_2015_test); 

/* 16. discrete */
%let file = loan_data_2007_2014_train;
%macro woe_disc(var);
proc sql; create table &var. as select &var., count(good_bad) as cnt, 
sum(good_bad) as cnt_good, avg(good_bad) as avg_good
from lib.&file. group by &var.; quit; 
data &var.; set &var.; cnt_bad = cnt - cnt_good; run; 
proc sql; create table &var. as select &var., cnt,
cnt_good / sum(cnt_good) as good, cnt_bad / sum(cnt_bad) as bad
from &var.; quit; 
data &var.; set &var.; WOE = log(good/bad); IV = (good-bad)*WOE; run; 
proc sql; create table &var. as select &var., cnt, WOE,
sum(IV) as IV from &var.; quit; 
proc sort data=&var.; by descending WOE; run; 
%mend;

/* %woe_disc(f_mnths_issue_d); */
/* %woe_disc(f_int_rate); */
/* %woe_disc(f_annual_inc); */
/* %woe_disc(f_mths_since_last_delinq); */
/* %woe_disc(f_dti); */
/* %woe_disc(f_mths_since_last_record); */
/* %woe_disc(f_mnths_earliest_cr_line); */
/* %woe_disc(f_delinq_2yrs); */
/* %woe_disc(f_inq_last_6mths); */
/* %woe_disc(f_total_rev_hi_lim); */
/* %woe_disc(f_acc_now_delinq); */
/* %woe_disc(f_open_acc); */
/* %woe_disc(f_pub_rec); */
/* %woe_disc(f_total_acc); */
