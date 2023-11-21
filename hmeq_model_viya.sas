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


proc mdsummary data = mycas.&indata.;
  var _numeric_;
  output out=mycas.hmeq_summary;
run;
proc print data=mycas.hmeq_summary;
run;
