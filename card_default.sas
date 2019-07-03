PROC SQL;
   CREATE TABLE DEFAULT_CREDIT AS 
   SELECT t1.ID, 
          t1.LIMIT_BAL, 
          t1.SEX, 
          t1.EDUCATION, 
          t1.MARRIAGE, 
          t1.AGE, 
          t1.PAY_0, 
          t1.PAY_2, 
          t1.PAY_3, 
          t1.PAY_4, 
          t1.PAY_5, 
          t1.PAY_6, 
          t1.BILL_AMT1, 
          t1.BILL_AMT2, 
          t1.BILL_AMT3, 
          t1.BILL_AMT4, 
          t1.BILL_AMT5, 
          t1.BILL_AMT6, 
          t1.PAY_AMT1, 
          t1.PAY_AMT2, 
          t1.PAY_AMT3, 
          t1.PAY_AMT4, 
          t1.PAY_AMT5, 
          t1.PAY_AMT6, 
          t1.'default payment next month'n
      FROM WORK.'DEFAULT _OF _CREDIT _CARD _CLIEN'n t1;
QUIT;

proc sql;
select * from DEFAULT_CREDIT where BILL_AMT1<> 0 and BILL_AMT2 <> 0 and BILL_AMT3 <> 0 and BILL_AMT4 <> 0 and BILL_AMT5 <> 0 and BILL_AMT6 <> 0;
quit;


proc sql;

select id, pay_0,pay_2,pay_3,pay_4,pay_5,pay_6
from DEFAULT_CREDIT;
quit;



%macro len(x);

data one;
set default_credit;
count_dpd=0;
%do i=0 %to &x;
if Pay_&i >0 then count_dpd = count_dpd+1; 
else count_dpd= count_dpd+0;
drop pay_1;
%end;
run;

%mend;
%len(6);

%macro len(x);

data one;
set default_credit;
count_overlimit=0;
count_dpd=0;
%do i=0 %to &x;
if bill_amt&i >limit_bal then count_overlimit = count_overlimit+1; 
else count_overlimit= count_overlimit+0;
drop bill_amt0;
if Pay_&i >0 then count_dpd = count_dpd+1; 
else count_dpd= count_dpd+0;
drop pay_1;
%end;
run;

%mend;
%len(6);



data two;
set one;
drop Pay_1;
run;


%macro per(y);
data three;
set one;
%do j=1 %to &y;
%let k=&j+1;
percent_&j= (((pay_amt&j )*100)/bill_amt&k);
%end;
run;
%mend;
%per(6)

proc sort data=one out=two;
by pay_0;
run;

ods graphics off;
ods select Plots SSPlots;
proc univariate data=two plot;
   by pay_0;
   var bill_amt1;
run;

proc freq data=one;
table education marriage sex age;
run;
data two;
set one;
if education = 0 or education = 1 then edu_1 = 1;
else edu_1= 0;
if education = 2 then edu_2 = 1;
else edu_2= 0;
if education = 3 then edu_3 = 1;
else edu_3= 0;
if education >3 then edu_4 = 1;
else edu_4= 0;
if marriage = 0 or marriage = 1 then Marriage_1 = 1;
else Marriage_1 = 0;
if marriage = 2 then Marriage_2 = 1;
else Marriage_2 = 0;
if marriage = 3 then Marriage_3 = 1;
else Marriage_3 = 0;
if age <= 25 then age_25=1;
else age_25=0;
if  age>25 and age <= 50 then age_50=1;
else age_50=0;
if age>50 and age <= 60 then age_60 =1;
else age_60= 0;
if age>60 then age_60=1;
else age_60=0;
if sex=1 then sex_1= 1;
else sex_1=0;
if sex=2 then sex_2=1;
else sex_2=0;
run;








proc sort data=one;
by age;
proc means data=one;
by age;
run;
%macro c(f);
proc gplot data=one;
%do h=1 %to &f;
plot bill_amt&h*age;
%end;
run;
%mend;
%c(6)
%macro c(f);
proc gplot data=one;
%do h=1 %to &f;
plot bill_amt&h*limit_bal;
%end;
run;
%mend;
%c(6)
%macro c(f);
proc sql;
select * from one
%do h=1 %to &f;
where bill_amt&h > limit_bal;
%end;
quit;
%mend;
%c(6)

proc standard data=two mean=0 std=1 out=five;
var bill_amt1-bill_amt6 pay_amt1-pay_amt6 limit_bal;
run;

 

proc surveyselect data=five method=srs out= samp1 samprate=0.7 outall;
run;

data train validate ;
set samp1;
if selected =0 then output  validate ;
else output train;
drop Selected;
run;

ods graphics on;
proc logistic data=train descending plots=all outmodel=dmm;
model 'default payment next month'n = ID LIMIT_BAL SEX_1 Edu_1-Edu_4 MARRIAGE_1 - MARRIAGE_3  AGE_25 age_50 age_60 PAY_0	PAY_2 PAY_3	PAY_4 PAY_5	PAY_6 
BILL_AMT1 BILL_AMT2	BILL_AMT3 BILL_AMT4	BILL_AMT5 BILL_AMT6	PAY_AMT1 PAY_AMT2 PAY_AMT3 PAY_AMT4 PAY_AMT5	
PAY_AMT6 count_overlimit count_dpd / selection=stepwise ctable lackfit;
score out=dmp;
run;
ods graphics off;

ods graphics on;
proc logistic data=train descending plots=all outmodel=dmm;
model 'default payment next month'n = LIMIT_BAL SEX_1 Edu_4 MARRIAGE_2 age_50 PAY_0	PAY_2 PAY_3	PAY_4 PAY_5	PAY_6 
BILL_AMT1 BILL_AMT2	BILL_AMT3 BILL_AMT4	BILL_AMT5 BILL_AMT6	PAY_AMT1 PAY_AMT2 PAY_AMT3 PAY_AMT4 PAY_AMT5	
PAY_AMT6  count_dpd / selection=stepwise ctable lackfit;
score out=dmp;
run;
ods graphics off;

ods graphics on;
proc logistic data=validate descending plots=all outmodel=dmm;
model 'default payment next month'n = LIMIT_BAL SEX_1 Edu_4 MARRIAGE_2 age_50 PAY_0	PAY_2 PAY_3	PAY_4 PAY_5	PAY_6 
BILL_AMT1 BILL_AMT2	BILL_AMT3 BILL_AMT4	BILL_AMT5 BILL_AMT6	PAY_AMT1 PAY_AMT2 PAY_AMT3 PAY_AMT4 PAY_AMT5	
PAY_AMT6  count_dpd /ctable lackfit;
score out=dmp;
run;
ods graphics off;