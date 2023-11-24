filename poli url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/datageo/Colombia_Poligonos_limitado.csv";


/*proc import intenta predecir el formato y tipo de variable adecuado de cada archivo
	en archivos planos, para mayor control de la importación se puede usar infile en data steps.*/

proc import datafile=poli dbms=csv  out=poligonos replace;
delimiter=';';
run;


cas casauto;
caslib _all_ assign;

data poligonos2;
set poligonos;
run;


proc casutil;
load data=work.poligonos2 outcaslib="casuser" casdata="col_pol" promote;
run;

/*parte 2, cargamos alguna información geografica*/
filename robos 	url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/datageo/Recuperaci_n_Veh_culos_Polic_a_Nacional.csv";


/*importamos informacion externa*/
/*proc import intenta predecir el formato y tipo de variable adecuado de cada archivo
	en archivos planos, para mayor control de la importación se puede usar infile en data steps.*/
/* Tener en cuenta nombramiento de variables en sas, no espacios, no numeros al inicio, no caracteres extraños, max 32 caracteres*/


data nombre_tabla;
    infile robos dlm=';' dsd firstobs=2; /* Cambiado el delimitador a punto y coma */

    /* Define las variables y sus formatos/informatos si es necesario */
    input
        DEPARTAMENTO : $50.
        MUNICIPIO : $50.
        CODIGO_DANE
        CLASE_BIEN : $50.
        FECHA_HECHO : ddmmyy8. /* Ajusta el formato de fecha según el formato real en tus datos */
        CANTIDAD;

    format FECHA_HECHO date9.; /* Ajusta el formato de fecha según el formato real en tus datos */

    /* Puedes realizar más manipulaciones de datos si es necesario */
run;



/* datos*/

data robos_prep;
set robos;
id_dane = catx("-","CO",put(codigo_dane/1000, z5.));
mes = mdy(month(fecha_hecho),01,year(fecha_hecho));

run;


proc sql;
create table robos_va as select
	﻿DEPARTAMENTO,
	municipio,
	clase_bien,
	mes,
	sum(cantidad) as q_robos
from robos_prep
group by ﻿DEPARTAMENTO, municipio, clase_bien, mes;
quit;

proc casutil;
load data=robos_va outcaslib="casuser" casdata="robos_va" promote;
run;
