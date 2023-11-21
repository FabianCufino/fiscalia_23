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
proc treesplit data=MYCAS.HMEQ_PARTITION maxdepth=11 numbin=19 maxbranch=3 
		minleafsize=6;
	partition role=_PartInd_ (test='0' train='1');
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	target BAD / level=nominal;
	grow igr;
	prune none;
	score out=MYCAS.hmeq_tree1_score copyvars=(BAD LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB);
	ods output VariableImportance=WORK.hmeq_tree_var_imp;
run;


