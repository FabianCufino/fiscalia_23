/*El presente codigo genera una tabla de poligonos de algunos departamentos y municipios de colombia*/
/*En la segunda parte trae información de robos de autos ocurridos en los ultimos 5 años
	tomados de la plataforma de datos abiertos:
	https://www.datos.gov.co/Seguridad-y-Defensa/Recuperaci-n-Veh-culos-Polic-a-Nacional/dhy3-732k*/

cas autogeo;
caslib _all_ assign;
 
/*parte 1, tomamos la tabla de poligonos*/

filename poli url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/datageo/Colombia_Poligonos_limitado.csv";


/*proc import intenta predecir el formato y tipo de variable adecuado de cada archivo
	en archivos planos, para mayor control de la importación se puede usar infile en data steps.*/

proc import datafile=poli dbms=csv  out=poligonos replace;
delimiter=';';
run;


proc casutil;
load data=work.poligonos outcaslib="casuser" casdata="col_pol" promote;
run;


		/*parte 2, cargamos alguna información geografica*/




/*importamos informacion externa*/
/*proc import intenta predecir el formato y tipo de variable adecuado de cada archivo
	en archivos planos, para mayor control de la importación se puede usar infile en data steps.*/
/* Tener en cuenta nombramiento de variables en sas, no espacios, no numeros al inicio, no caracteres extraños, max 32 caracteres*/

filename robos 	url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/datageo/Recuperaci_n_Veh_culos_Polic_a_Nacional.csv";


data robos_raw;
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


data robos_prep;
set robos_raw;
format mes date9.;
id_dane_mun = catx("-","CO",put(codigo_dane/1000, z5.));
id_dane_dept = catx("-","CO",put(codigo_dane/1000000, z2.));
fecha = mdy(1,1,year(fecha_hecho));
run;

/*agregamos por año*/
proc sql;
create table robos_va as select
	departamento,
	municipio,
	clase_bien,
	fecha format =date9.,
	id_dane_mun,
	id_dane_dept,
	sum(cantidad) as q_robos
from robos_prep
group by departamento, municipio, clase_bien, fecha, id_dane_mun,id_dane_dept;
quit;


proc casutil;
load data=robos_va outcaslib="casuser" casout="robos_va" promote;
run;

/*
proc casutil;
droptable casdata="robos_va" incaslib="casuser";
run;
*/

cas autogeo terminate;
