options compress=yes; 
options YEARCUTOFF=1970;
libname lib "/folders/myfolders/codes";

%macro rg (file);
/* 1. good_bad */
data lib.&file.; set lib.&file.; if loan_status in ('Charged Off',
'Default', 'Does not meet the credit policy. Status:Charged Off', 
'Late (31-120 days)') then good_bad = 0; else good_bad = 1; run; 
proc freq data=lib.&file.; table good_bad; run; 

/* 2. splitting */
%macro split(var);
data temp&var.; set lib.&file.; where good_bad = &var.; run;
data temp&var.; set temp&var.; row_num = _n_; run; 
data test&var.; set temp&var.; where mod(row_num,5) eq &var.; run;   
data train&var.; set temp&var.; where mod(row_num,5) ne &var.; run;  
%mend; 
%split(0);
%split(1);
data lib.&file._train; set train0 train1; run; 
data lib.&file._test; set test0 test1; run; 

/* 3. home_ownership */
data lib.&file._train; set lib.&file._train; 
if home_ownership in ('ANY','OTHER','NONE','RENT') then home_ownership = 'RENT'; run; 
data lib.&file._test; set lib.&file._test; 
if home_ownership in ('ANY','OTHER','NONE','RENT') then home_ownership = 'RENT'; run;

/* 4. purpose */
data lib.&file._train; set lib.&file._train; 
if purpose in ('educational','small_business','wedding','renewable_energy','moving','house') then purpose = 'ED_SB_WD_RE_MO_HO'; 
if purpose in ('other','medical','vacation') then purpose = 'OTH_MED_VAC'; 
if purpose in ('major_purchase','car','home_improvement') then purpose = 'MP_CAR_HI'; run; 
data lib.&file._test; set lib.&file._test; 
if purpose in ('educational','small_business','wedding','renewable_energy','moving','house') then purpose = 'ED_SB_WD_RE_MO_HO'; 
if purpose in ('other','medical','vacation') then purpose = 'OTH_MED_VAC'; 
if purpose in ('major_purchase','car','home_improvement') then purpose = 'MP_CAR_HI'; run; 

/* 5. addr_state */
data lib.&file._train; format addr_state $20.; set lib.&file._train; 
if addr_state in ('ND','NE','IA','NV','FL','HI','AL') then addr_state = 'ND_NE_IA_NV_FL_HI_AL';
if addr_state in ('NM','VA') then addr_state = 'NM_VA';
if addr_state in ('OK','TN','MO','LA','MD','NC') then addr_state = 'OK_TN_MO_LA_MD_NC';
if addr_state in ('UT','KY','AZ','NJ') then addr_state = 'UT_KY_AZ_NJ';
if addr_state in ('AR','MI','PA','OH','MN') then addr_state = 'AR_MI_PA_OH_MN';
if addr_state in ('RI','MA','DE','SD','IN') then addr_state = 'RI_MA_DE_SD_IN';
if addr_state in ('GA','WA','OR') then addr_state = 'GA_WA_OR';
if addr_state in ('WI','MT') then addr_state = 'WI_MT';
if addr_state in ('IL','CT') then addr_state = 'IL_CT';
if addr_state in ('KS','SC','CO','VT','AK','MS') then addr_state = 'KS_SC_CO_VT_AK_MS';
if addr_state in ('WV','NH','WY','DC','ME','ID') then addr_state = 'WV_NH_WY_DC_ME_ID'; run; 
data lib.&file._test; format addr_state $20.; set lib.&file._test; 
if addr_state in ('ND','NE','IA','NV','FL','HI','AL') then addr_state = 'ND_NE_IA_NV_FL_HI_AL';
if addr_state in ('NM','VA') then addr_state = 'NM_VA';
if addr_state in ('OK','TN','MO','LA','MD','NC') then addr_state = 'OK_TN_MO_LA_MD_NC';
if addr_state in ('UT','KY','AZ','NJ') then addr_state = 'UT_KY_AZ_NJ';
if addr_state in ('AR','MI','PA','OH','MN') then addr_state = 'AR_MI_PA_OH_MN';
if addr_state in ('RI','MA','DE','SD','IN') then addr_state = 'RI_MA_DE_SD_IN';
if addr_state in ('GA','WA','OR') then addr_state = 'GA_WA_OR';
if addr_state in ('WI','MT') then addr_state = 'WI_MT';
if addr_state in ('IL','CT') then addr_state = 'IL_CT';
if addr_state in ('KS','SC','CO','VT','AK','MS') then addr_state = 'KS_SC_CO_VT_AK_MS';
if addr_state in ('WV','NH','WY','DC','ME','ID') then addr_state = 'WV_NH_WY_DC_ME_ID'; run; 

/* 6. term */
data lib.&file._train (drop=term1); set lib.&file._train (rename=(term = term1)); 
format term $10.; term = put(term1, $10.); run; 
data lib.&file._test (drop=term1); set lib.&file._test (rename=(term = term1)); 
format term $10.; term = put(term1, $10.); run; 

/* 7. emp_length */
data lib.&file._train (drop=emp_length1); 
set lib.&file._train (rename=(emp_length = emp_length1)); 
format emp_length $10.; if emp_length1 = 0 then emp_length = '0'; 
else if emp_length1 = 1 then emp_length = '1';
else if emp_length1 <=4 then emp_length = '2-4';
else if emp_length1 <=6 then emp_length = '5-6';
else if emp_length1 <=9 then emp_length = '7-9';
else emp_length = '10'; run; 
data lib.&file._test (drop=emp_length1); 
set lib.&file._test (rename=(emp_length = emp_length1)); 
format emp_length $10.; if emp_length1 = 0 then emp_length = '0'; 
else if emp_length1 = 1 then emp_length = '1';
else if emp_length1 <=4 then emp_length = '2-4';
else if emp_length1 <=6 then emp_length = '5-6';
else if emp_length1 <=9 then emp_length = '7-9';
else emp_length = '10'; run; 

%mend; 
%rg(loan_data_2007_2014);
%rg(loan_data_2015); 

%let file = loan_data_2007_2014_train;

/* 8. discrete */
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

%woe_disc(grade);
%woe_disc(home_ownership);
%woe_disc(verification_status);
%woe_disc(initial_list_status);
%woe_disc(purpose);
%woe_disc(addr_state);
%woe_disc(term);
%woe_disc(emp_length);
