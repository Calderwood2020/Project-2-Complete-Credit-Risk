options compress=yes; 
options YEARCUTOFF=1970;
libname lib "/folders/myfolders/codes";
proc contents data=lib.loan_data_2007_2014_train; run; 

/* 1. train model */
proc logistic data=lib.loan_data_2007_2014_train desc outmodel=pd_model; 
class /*char*/ grade (ref='G')
home_ownership (ref='RENT')
verification_status (ref='Verified')
initial_list_status (ref='f')
purpose (ref='ED_SB_WD_RE_MO_HO')
addr_state (ref='ND_NE_IA_NV_FL_HI_AL')
term (ref='60')
emp_length (ref='0')
/*num*/ F_MNTHS_ISSUE_D (ref='65-85')
f_int_rate (ref='20.281+')
f_annual_inc (ref='0-20K')
f_mths_since_last_delinq (ref='0-3')
f_dti (ref='22.4-35')
f_mths_since_last_record (ref='0-2')
f_mnths_earliest_cr_line (ref='0-140')
f_inq_last_6mths (ref='7+')
f_acc_now_delinq (ref='0') / param=reference;

model good_bad = 
/*char*/ grade home_ownership verification_status initial_list_status 
purpose addr_state term emp_length
/*num*/ F_MNTHS_ISSUE_D f_int_rate f_annual_inc f_mths_since_last_delinq
f_dti f_mths_since_last_record f_mnths_earliest_cr_line
f_inq_last_6mths f_acc_now_delinq ; run;

/* 2. test model */
proc logistic inmodel=pd_model;
score data=lib.loan_data_2007_2014_test out=temp (keep=id good_bad p_1 p_0); run;

/* 3. confusion matrix */
%let cut_off = 0.2; 
data cm (keep=id good_bad pred); set temp;
if p_1 > &cut_off. then pred = 1; else pred = 0; run;
proc sql; select good_bad, pred, count(id) as cnt
from cm group by good_bad, pred order by good_bad, pred; quit;

/* 4. KS */
proc sort data=temp; by p_1; run; 
proc rank data=temp groups=10 out=ks; 
var p_1; ranks f_p_1; run; 
proc sql; select f_p_1, count(id) as pop, sum(p_1) as good, sum(p_0) as bad
from ks group by f_p_1; quit; 

/* 5. 2015 */
data lib.loan_data_2015; set lib.loan_data_2015_train lib.loan_data_2015_test; run;
proc contents data=lib.loan_data_2015; run; 

/* PSI */
%macro psi (file);
data temp; set lib.&file.; score=300;
if addr_state = 'NY' then score = score + 4;
if addr_state = 'NM_VA' then score = score + 4;
if addr_state = 'OK_TN_MO_LA_MD_NC' then score = score + 5;
if addr_state = 'CA' then score = score + 6;
if addr_state = 'UT_KY_AZ_NJ' then score = score + 6;
if addr_state = 'RI_MA_DE_SD_IN' then score = score + 8;
if addr_state = 'AR_MI_PA_OH_MN' then score = score + 11;
if addr_state = 'GA_WA_OR' then score = score + 15;
if addr_state = 'TX' then score = score + 19;
if addr_state = 'IL_CT' then score = score + 20;
if addr_state = 'WI_MT' then score = score + 22;
if addr_state = 'KS_SC_CO_VT_AK_MS' then score = score + 26;
if addr_state = 'WV_NH_WY_DC_ME_ID' then score = score + 36;
if emp_length = '7-9' then score = score + 6;
if emp_length = '5-6' then score = score + 7;
if emp_length = '1' then score = score + 9;
if emp_length = '2-4' then score = score + 10;
if emp_length = '10' then score = score + 10;
if f_acc_now_delinq = '1' then score = score + 7;
if f_annual_inc = '20-30K' then score = score + 1;
if f_annual_inc = '30-40K' then score = score + 5;
if f_annual_inc = '40-50K' then score = score + 6;
if f_annual_inc = '50-60K' then score = score + 9;
if f_annual_inc = '60-70K' then score = score + 18;
if f_annual_inc = '70-80K' then score = score + 23;
if f_annual_inc = '80-90K' then score = score + 30;
if f_annual_inc = '90-100K' then score = score + 30;
if f_annual_inc = '100-120K' then score = score + 36;
if f_annual_inc = '140+K' then score = score + 41;
if f_annual_inc = '120-140K' then score = score + 44;
if f_dti = '35+' then score = score + 1;
if f_dti = '21.7-22.4' then score = score + 3;
if f_dti = '20.3-21.7' then score = score + 7;
if f_dti = '16.1-20.3' then score = score + 8;
if f_dti = '10.5-16.1' then score = score + 15;
if f_dti = '0-1.4' then score = score + 19;
if f_dti = '7.7-10.5' then score = score + 21;
if f_dti = '1.4-3.5' then score = score + 25;
if f_dti = '3.5-7.7' then score = score + 26;
if f_inq_last_6mths = '3-6' then score = score + 28;
if f_inq_last_6mths = '1-2' then score = score + 42;
if f_inq_last_6mths = '0' then score = score + 55;
if f_int_rate = '15.740-20.281' then score = score + 9;
if f_int_rate = '12.025-15.740' then score = score + 25;
if f_int_rate = '9.548-12.025' then score = score + 46;
if f_int_rate = '0-9.548' then score = score + 73;
if f_mnths_earliest_cr_line = '165-247' then score = score + 2;
if f_mnths_earliest_cr_line = '248-270' then score = score + 4;
if f_mnths_earliest_cr_line = '141-164' then score = score + 4;
if f_mnths_earliest_cr_line = '271-352' then score = score + 7;
if f_mnths_earliest_cr_line = '353+' then score = score + 9;
if f_mnths_issue_d = '86+' then score = score + 7;
if f_mnths_issue_d = '53-64' then score = score + 20;
if f_mnths_issue_d = '49-52' then score = score + 39;
if f_mnths_issue_d = '42-48' then score = score + 51;
if f_mnths_issue_d = '40-41' then score = score + 67;
if f_mnths_issue_d = '38-39' then score = score + 75;
if f_mnths_issue_d = '0-37' then score = score + 92;
if f_mths_since_last_delinq = 'MISSING' then score = score + 7;
if f_mths_since_last_delinq = '57+' then score = score + 9;
if f_mths_since_last_delinq = '1-4' then score = score + 9;
if f_mths_since_last_delinq = '31-56' then score = score + 12;
if f_mths_since_last_record = '80-86' then score = score + 26;
if f_mths_since_last_record = '86+' then score = score + 27;
if f_mths_since_last_record = 'MISSING' then score = score + 33;
if f_mths_since_last_record = '20-31' then score = score + 38;
if f_mths_since_last_record = '2-30' then score = score + 42;
if f_mths_since_last_record = '31-80' then score = score + 49;
if grade = 'F' then score = score + 18;
if grade = 'E' then score = score + 31;
if grade = 'D' then score = score + 45;
if grade = 'C' then score = score + 58;
if grade = 'B' then score = score + 74;
if grade = 'A' then score = score + 89;
if home_ownership = 'OWN' then score = score + 5;
if home_ownership = 'MORTGAGE' then score = score + 8;
if initial_list_status = 'w' then score = score + 4;
if purpose = 'debt_consolidation' then score = score + 15;
if purpose = 'OTH_MED_VAC' then score = score + 16;
if purpose = 'MP_CAR_HI' then score = score + 20;
if purpose = 'credit_card' then score = score + 23;
if term = '36' then score = score + 6;
if verification_status = 'Source Verified' then score = score + 1;
if verification_status = 'Not Verified' then score = score + 6; 

if score <= 350 then score_bin = 'score <= 350';
else if score <= 400 then score_bin = 'score <= 400';
else if score <= 450 then score_bin = 'score <= 450';
else if score <= 500 then score_bin = 'score <= 500';
else if score <= 550 then score_bin = 'score <= 550';
else if score <= 600 then score_bin = 'score <= 600';
else if score <= 650 then score_bin = 'score <= 650';
else if score <= 700 then score_bin = 'score <= 700';
else if score <= 750 then score_bin = 'score <= 750';
else if score <= 800 then score_bin = 'score <= 800';
else score_bin = 'score <= 850';
run; 

proc sql; select score_bin, count(*) as cnt 
from temp group by score_bin; quit; 
%mend; 

%psi(loan_data_2007_2014_train); 
%psi(loan_data_2015); 

/* 6. all variable PSI */
data all_var; set _null_; run; 

%macro psi(var);
proc sql; create table train as select &var., count(*) as &var._sum 
from lib.loan_data_2007_2014_train group by &var.; quit; 
proc sql; create table test as select &var., count(*) as &var._sum 
from lib.loan_data_2015 group by &var.; quit; 
proc sql; create table temp as select a.&var., a.&var._sum as train, b.&var._sum as test 
from train as a left join test as b on a.&var. = b.&var.; quit; 
proc sql; create table temp as select *, sum(train) as sum_train, sum(test) as sum_test
from temp; quit; 
data temp (drop=sum_train sum_test); set temp; 
train = train / sum_train; 
test = test / sum_test; 
psi = (train - test) * log(train / test); run; 
proc sql; create table temp as select sum(psi) as psi from temp; quit;  
data temp; format var $100.; set temp; var = "&var."; run; 
data all_var; set all_var temp; run; 
%mend; 
%psi(addr_state);
%psi(emp_length);
%psi(f_acc_now_delinq);
%psi(f_annual_inc);
%psi(f_dti);
%psi(f_inq_last_6mths);
%psi(f_int_rate);
%psi(f_mnths_earliest_cr_line);
%psi(f_mnths_issue_d);
%psi(f_mths_since_last_delinq);
%psi(f_mths_since_last_record);
%psi(grade);
%psi(home_ownership);
%psi(initial_list_status);
%psi(purpose);
%psi(term);
%psi(verification_status);
