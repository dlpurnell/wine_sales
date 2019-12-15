

%let PATH 		= C:\Users\dowedd\Desktop\SYNC_WINE;
%let NAME 		= P411;
%let LIB 		= &NAME..;
%let INFILE 	= &LIB.WINE;

%let TEMPFILE 	= TEMPFILE;
%let FIXFILE	= FIXFILE;
%let VARLIST	= VARLIST;


libname &NAME. "&PATH.\DATA";


proc print data=&INFILE.(obs=10);
run;



proc univariate data=&INFILE. noprint;
histogram TARGET;
run;




data &TEMPFILE.;
set &INFILE.;
TARGET_FLAG = ( TARGET > 0 );
TARGET_AMT = TARGET - 1;
if TARGET_FLAG = 0 then TARGET_AMT = .;

IMP_STARS				= STARS;
IMP_Density				= Density;
IMP_Sulphates			= Sulphates;
IMP_Alcohol				= Alcohol;
IMP_LabelAppeal			= LabelAppeal;
IMP_TotalSulfurDioxide	= TotalSulfurDioxide;
M_STARS					= 0;

if missing(STARS)				then do;	IMP_STARS		= 2;			M_STARS = 1; 	end;
if missing(Density)				then IMP_Density 			= 0.9942027;
if missing(Sulphates)			then IMP_Sulphates			= 0.5271118;
if missing(Alcohol)				then IMP_Alcohol			= 10.4892363;
if missing(LabelAppeal)			then IMP_LabelAppeal		= -0.009066;
if missing(TotalSulfurDioxide)	then IMP_TotalSulfurDioxide	= 120.7142326;


*IMP_TotalSulfurDioxide = sign( IMP_TotalSulfurDioxide ) * sqrt( abs(IMP_TotalSulfurDioxide)+1 );
*IMP_TotalSulfurDioxide = sign( IMP_TotalSulfurDioxide ) * log( abs(IMP_TotalSulfurDioxide)+1 );

if IMP_TotalSulfurDioxide	< -330 then IMP_TotalSulfurDioxide = -330;
if IMP_TotalSulfurDioxide	> 630  then IMP_TotalSulfurDioxide = 630;




keep
	TARGET_FLAG
	TARGET_AMT
	TARGET
	;

keep	TARGET
		TARGET_FLAG
		TARGET_AMT
		IMP_STARS
		IMP_Density
		IMP_Sulphates
		IMP_Alcohol
		IMP_LabelAppeal
		IMP_TotalSulfurDioxide
		M_STARS
		;
run;

proc print data=&TEMPFILE.(obs=20);
*var TARGET TARGET_FLAG TARGET_AMT;
run;


proc freq data=&TEMPFILE.;
table TARGET_FLAG /missing;
run;

proc univariate data=&TEMPFILE. noprint;
histogram TARGET TARGET_AMT;
run;



proc means data=&TEMPFILE. nmiss mean median min max;
var
		IMP_STARS
		IMP_Density
		IMP_Sulphates
		IMP_Alcohol
		IMP_LabelAppeal
		IMP_TotalSulfurDioxide
		M_STARS
	;
run;

proc means data=&TEMPFILE. nmiss mean median min max;
class TARGET_FLAG; 
var
		IMP_STARS
		IMP_Density
		IMP_Sulphates
		IMP_Alcohol
		IMP_LabelAppeal
		IMP_TotalSulfurDioxide
		M_STARS
	;
run;

proc freq data=&TEMPFILE.;
table IMP_STARS*TARGET_FLAG /missing;
run;


proc univariate data=&TEMPFILE. noprint;
histogram IMP_TotalSulfurDioxide;
run;







data &FIXFILE.;
set &TEMPFILE.;
run;


proc print data=&FIXFILE.(obs=10);
run;


proc univariate data=&FIXFILE. noprint;
histogram TARGET;
run;






proc reg data=&FIXFILE.;
model TARGET = 	
				IMP_STARS
				IMP_Density
				IMP_Sulphates
				IMP_Alcohol
				IMP_LabelAppeal
				IMP_TotalSulfurDioxide
				M_STARS
				/selection = stepwise;
	output out=&FIXFILE. p=X_REGRESSION;
run;
quit;



data SCOREFILE;
set &FIXFILE.;

P_REGRESSION =	3.06747 								+
				IMP_STARS 				*(0.81011) 		+
				IMP_Density 			*(-1.23532) 	+
				IMP_Sulphates 			*(-0.03851) 	+
				IMP_Alcohol 			*(0.01437) 		+
				IMP_LabelAppeal 		*(0.44668) 		+
				IMP_TotalSulfurDioxide 	*(0.00031312) 	+
				M_STARS 				*(-2.36139)
				;

run;



proc print data=SCOREFILE(obs=10);
var TARGET X_REGRESSION P_REGRESSION;
run;





















data &FIXFILE.;
set &TEMPFILE.;
run;


proc genmod data=&FIXFILE.;
model TARGET = 	
				IMP_STARS
				IMP_Density
				IMP_Sulphates
				IMP_Alcohol
				IMP_LabelAppeal
				IMP_TotalSulfurDioxide
				M_STARS
				/link=log dist=nb
				;
output out=&FIXFILE. p=X_GENMOD_NB;
run;


proc print data=&FIXFILE.(obs=10);
run;


data SCOREFILE;
set &FIXFILE.;


P_REGRESSION =	3.06747 								+
				IMP_STARS 				*(0.81011) 		+
				IMP_Density 			*(-1.23532) 	+
				IMP_Sulphates 			*(-0.03851) 	+
				IMP_Alcohol 			*(0.01437) 		+
				IMP_LabelAppeal 		*(0.44668) 		+
				IMP_TotalSulfurDioxide 	*(0.00031312) 	+
				M_STARS 				*(-2.36139)
				;


P_GENMOD_NB = 	
				1.2383 								+
				IMP_STARS 				*(0.1980)	+
				IMP_Density 			*(-0.4374)	+
				IMP_Sulphates 			*(-0.0134)	+
				IMP_Alcohol 			*(0.0046)	+
				IMP_LabelAppeal 		*(0.1536)	+
				IMP_TotalSulfurDioxide 	*(0.0001)	+
				M_STARS 				*(-1.0665)
				;
P_GENMOD_NB = exp(P_GENMOD_NB);
run;


proc print data=SCOREFILE(obs=10);
var TARGET X_GENMOD_NB P_GENMOD_NB P_REGRESSION;
run;














data &FIXFILE.;
set &TEMPFILE.;
run;


proc logistic data=&FIXFILE.;
model TARGET_FLAG(ref="0") = 	
				IMP_STARS
				IMP_LabelAppeal
				M_STARS
				;
output out=&FIXFILE. p=X_LOGIT_PROB;
run;


proc print data=&FIXFILE.(obs=10);
var TARGET_FLAG X_LOGIT_PROB;
run;




proc genmod data=&FIXFILE.;
model TARGET_AMT = 	
				IMP_STARS
				IMP_Density
				IMP_LabelAppeal
				M_STARS
				/link=log dist=nb
				;
output out=&FIXFILE. p=X_GENMOD_HURDLE;
run;











data SCOREFILE;
set &FIXFILE.;


P_REGRESSION =	3.06747 								+
				IMP_STARS 				*(0.81011) 		+
				IMP_Density 			*(-1.23532) 	+
				IMP_Sulphates 			*(-0.03851) 	+
				IMP_Alcohol 			*(0.01437) 		+
				IMP_LabelAppeal 		*(0.44668) 		+
				IMP_TotalSulfurDioxide 	*(0.00031312) 	+
				M_STARS 				*(-2.36139)
				;


P_GENMOD_NB = 	
				1.2383 								+
				IMP_STARS 				*(0.1980)	+
				IMP_Density 			*(-0.4374)	+
				IMP_Sulphates 			*(-0.0134)	+
				IMP_Alcohol 			*(0.0046)	+
				IMP_LabelAppeal 		*(0.1536)	+
				IMP_TotalSulfurDioxide 	*(0.0001)	+
				M_STARS 				*(-1.0665)
				;
P_GENMOD_NB = exp(P_GENMOD_NB);










P_LOGIT_PROB = -1.2899								+
				IMP_STARS 			*(2.5806	)	+
				IMP_LabelAppeal 	*(-0.4906	)	+
				M_STARS 			*(-4.4074	)	
				;
if P_LOGIT_PROB > 1000 then P_LOGIT_PROB = 1000;
if P_LOGIT_PROB < -1000 then P_LOGIT_PROB = -1000;
P_LOGIT_PROB = exp(P_LOGIT_PROB) / (1+exp(P_LOGIT_PROB));



P_GENMOD_HURDLE = 	
				1.1869 								+
				IMP_STARS  			*(0.1253 	)	+
				IMP_Density  		*(-0.4289 	)	+
				IMP_LabelAppeal  	*(0.2940 	)	+
				M_STARS  			*(-0.2135 	)
				;
P_GENMOD_HURDLE = exp(P_GENMOD_HURDLE);


P_HURDLE = P_LOGIT_PROB * (P_GENMOD_HURDLE+1);


P_ENSEMBLE = (P_REGRESSION + P_GENMOD_NB + P_HURDLE)/3;


P_REGRESSION 	= round(P_REGRESSION	, 1);
P_GENMOD_NB 	= round(P_GENMOD_NB		, 1);
P_HURDLE 		= round(P_HURDLE		, 1);
P_ENSEMBLE		= round(P_ENSEMBLE		, 1);


run;



proc print data=SCOREFILE(obs=25);
var TARGET P_REGRESSION P_GENMOD_NB P_HURDLE P_ENSEMBLE ;
run;


proc means data=SCOREFILE sum;
var TARGET P_REGRESSION P_GENMOD_NB P_HURDLE P_ENSEMBLE ;
run;
