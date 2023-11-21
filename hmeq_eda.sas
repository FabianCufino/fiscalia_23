/* Codigo SAS 9.4*/

filename file url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/data/hmeq.csv" termstr=crlf;


proc contents data= work.hmeq out=hmeq_metadata;

data hmeq_metadata_num (keep= name);
set hmeq_metadata (where= ( type= 1) );
run;


proc import datafile= file
out=HMEQ
replace
dbms=csv;
run;


ods graphics / reset width=6.4in height=4.8in imagemap;


/* analisis exploratorio*/ 

proc summary data=HMEQ MEAN MEDIAN MAX MIN MISSING N;
vars 


/* analisis univariado*/

/*Frecuencia "BAD"*/
proc sgplot data=WORK.HMEQ;
	title height=14pt "Frecuencia variable ""BAD""";
	vbar BAD / fillattrs=(color=CX33A3FF transparency=0.5) datalabel 
		fillType=gradient dataskin=sheen;
	yaxis grid;
run;


/*relación entre el valor del inmueble y monto adeudado*/
proc sgplot data=WORK.HMEQ;
	title height=14pt "Relación entre Valor del inmueble (Value) y monto adeudado de hipoteca(MortDue)";
	reg x=MORTDUE y=VALUE / nomarkers;
	scatter x=MORTDUE y=VALUE / markerattrs=(size=4);
	xaxis grid;
	yaxis grid;
run;


/* Box plot monto solicitud del prestamo (LOAN) x razón*/
proc sgplot data=WORK.HMEQ;
	title height=11pt "Box plot monto solicitud del prestamo (LOAN) x razón";
	footnote2 justify=left height=12pt "diamante = promedio";
	vbox LOAN / category=REASON boxwidth=0.3 fillattrs=(color=CX2C8AD6 
		transparency=0.25) capshape=line;
	yaxis grid;
run;

