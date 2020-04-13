options compress=yes; 
options YEARCUTOFF=1970;
libname lib "/folders/myfolders/codes";
proc contents data=lib.loan_data_2007_2014_train; run; 

%macro lgd_ead(file);
/* 1. charge-off population  */
data temp; set lib.&file.;
if loan_status in ('Charged Off','Does not meet the credit policy. Status:Charged Off'); 
if mths_since_last_delinq eq . then mths_since_last_delinq = 0;
if mths_since_last_record = . then mths_since_last_record = 0; run;

/* 2. dependent for LGD */
data temp; set temp; 
recovery_rate = recoveries / funded_amnt; 
if recovery_rate > 1 then recovery_rate = 1;
if recovery_rate < 0 then recovery_rate = 0; 
if recovery_rate eq 0 then recovery_rate_0_1 = 0; else recovery_rate_0_1 = 1; run; 

/* 3. dependent for EAD */
data lib.&file._le; set temp; 
ccf = (funded_amnt - total_rec_prncp)/funded_amnt; 
if ccf > 1 then ccf = 1;
if ccf < 0 then ccf = 0; run; 

/* 4. distribution of dependent */
proc means data=lib.&file._le n min p5 p10 q1 median q3 p90 p95 max; 
var recovery_rate ccf; run; 
%mend;

%lgd_ead(loan_data_2007_2014_train);
%lgd_ead(loan_data_2007_2014_test);
%lgd_ead(loan_data_2015_train); 
%lgd_ead(loan_data_2015_test); 
