/* inicio de sesion cas*/
cas casauto;
caslib _all_ assign;
/* generamos alias de libreria CAS por defecto CASUSER*/
libname mycas cas;

filename hmeq url 'https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/data/hmeq.csv'; 

/* definimos macrovariables transversales*/
%let indata = hmeq;
%let target          = bad;
%let class_inputs    = reason job;
%let class_vars      = &target &class_inputs;
%let interval_inputs = clage clno debtinc loan mortdue value yoj ninq derog delinq;
%let all_inputs      = &interval_inputs &class_inputs;


proc import file=hmeq out=mycas.hmeq dbms=csv replace;
run;

/* notese que el procedimiento mdsummary en viya es similar 
	en sintaxis como en proposito al procedimiento summary de 9.4*/
proc mdsummary data = mycas.&indata.;
  var _numeric_;
  output out=mycas.hmeq_summary;
run;
proc print data=mycas.hmeq_summary;
run;


ods graphics;
proc sgplot data = mycas.hmeq_summary;
  vbar _column_ / response=_nmiss_;
run;

/*procedimiento para imputación*/
proc varimpute data=mycas.&indata.;
  input clage       / ctech = mean;
  input delinq      / ctech = median;
  input ninq        / ctech = value cvalues=2;
  input debtinc yoj / ctech = value cvalues=35.0, 7;
  output out=mycas.hmeq_impute COPYVARS=(_all_);
run;

/* Algunos modelos pueden generar la partición dentro de su algoritmo,
	para desarrollo y comparación de varios modelos, puede ser eficiente
		computacionalmente, generar la particion al principio
			del proceso de modelado*/

%let part_data = hmeq_part;

ods noproctitle;

/* generamos particiones, por el momento train y test*/
proc partition data=MYCAS.HMEQ partind samppct=70;
	by BAD;
	output out=mycas.hmeq_partition;
run;


/* validamos la variable indicadora de la partición*/
	/* _PartInd_  = 0: Test, 1 = Train, 2 = Validation*/
proc freqtab data=mycas.hmeq_partition;
table _partind_;
run;


/* Modelos de arbol*/
ods noproctitle;
proc treesplit data=MYCAS.HMEQ_PARTITION maxdepth=10 numbin=20 maxbranch=2 
		minleafsize=6 plots=all;
	partition role=_PartInd_ (test='0' train='1');
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	target BAD / level=nominal;
	grow igr;
	prune costcomplexity;
	/* nota seleccionar el path desde ruta home, o cualquier ruta de server*/
	code comment file="/home/fabian.cufino@bitechco.com.co/tree1_score.sas";

	score out=MYCAS.hmeq_tree1_score copyvars=(BAD LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB) ;
	ods output VariableImportance=WORK.hmeq_tree1_var_imp Modelinfo=work.hmeq_tree1_ModelInfo 
				TreePerformance = work.hmeq_tree1_performance;
run;


/* arbol 2*/ 
/* Usa algunas opciones para el tuneo de parametros*/

proc treesplit data=MYCAS.HMEQ_PARTITION;
	partition role=_PartInd_ (test='0' train='1');
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	target BAD / level=nominal;
	prune costcomplexity(leaves=25);
	code comment file="/home/fabian.cufino@bitechco.com.co/tree2_score.sas";
	autotune tuningparameters=(maxdepth(init=5 ub=8) numbin(exclude) 
		criterion(values=entropy igr gini) ) searchmethod=random samplesize=30 
		objective=misc maxtime=%sysevalf(65*60);
	ods output VariableImportance=WORK.hmeq_tree2_var_imp Modelinfo=work.hmeq_tree2_ModelInfo 
				TreePerformance = work.hmeq_tree2_performance;
run;

