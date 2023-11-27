/*modelación del consumo de combustible en la ciudad, (millas por galón) a partir de
	caracteristicas del coche*/

cas model_sesion;
caslib _all_ assign;

proc casutil;
	load data=sashelp.cars casout="cars" outcaslib="casuser" replace;
run;

proc regselect data=CASUSER.CARS;
	partition fraction(test=0.3 seed=1234);
	class Type;
	model MPG_City=Type Cylinders Horsepower / stb clb tol;
	output out=casuser.cars_m1_scored p=predicted lcl=lcl ucl=ucl lclm=lclm uclm=uclm 
		r=residual student=student press=press rstudent=rstudent stdr=stdr stdi=stdi 
		stdp=stdp role=_PartInd_ copyvars=(_all_);

run;


/*
gráfico de residuos frente a valores ajustados,
 es una herramienta útil en el análisis de regresión para examinar la relación entre los residuos del modelo y los valores ajustados (predichos) por el modelo. 
Esta gráfica es valiosa para detectar patrones sistemáticos en los residuos, 
lo que podría indicar violaciones de los supuestos del modelo.*/

ods graphics / reset width=6.4in height=4.8in imagemap;


proc sgplot data=CASUSER.CARS_M1_SCORED;
	title height=14pt "gráfico de residuos frente a valores ajustados";
	footnote2 justify=left height=12pt "Se espera un patron lineal y los residuos constantes, 
		adicional parece aumentar en valores altos de la variable target, signo de NO homocedasticidad";
	reg x=predicted y=residual / nomarkers;
	scatter x=predicted y=residual / markerattrs=(size=4) transparency=0.25;
	xaxis grid;
	yaxis grid;
run;


ods graphics / reset;
title;
footnote2;

title1 "Grafico QQ";
title2 "Comparar la distribución de los residuales contra la curva normal";

footnote1 "En la medida en que los cuantiles teóricos no se corresponden con los valores de los residuos encontrados, particularmente cuando hablamos de residuos positivos altos (parte
derecha/arriba de la gráfica) entonces muy probablemente nuestor modelo no cumpla el supuesto de normalidad";

proc univariate data=CASUSER.CARS_M1_SCORED noprint;
   qqplot residual / normal(mu=0 sigma=1)
                        ;
run;
