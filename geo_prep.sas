/*El presente codigo genera una tabla de poligonos de algunos departamentos y municipios de colombia*/
/*En la segunda parte trae información de robos de autos ocurridos en los ultimos 5 años
	tomados de la plataforma de datos abiertos:
	https://www.datos.gov.co/Seguridad-y-Defensa/Recuperaci-n-Veh-culos-Polic-a-Nacional/dhy3-732k*/


 
/*parte 1, tomamos la tabla de poligonos*/

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


/* Poligonos a nivel departamento, nos basamos en data de libreria maps de SAS*/



data poligono_dept;
set maps.colombia;
secuencia = _n_;
run;

filename dane_d url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/datageo/Codigos_Dane_SAS_DEPT.csv";
/*proc import intenta predecir el formato y tipo de variable adecuado de cada archivo
	en archivos planos, para mayor control de la importación se puede usar infile en data steps.*/
proc import datafile=dane_d dbms=csv  out=dane replace;
delimiter=';';
run;

proc sql;
create table poli_dept as select 
t1.*,
t2.Nombredane,
t2.codigodane
from poligono_dept as t1 left join dane as t2 on (t1.id = t2.id_sas);
quit;

data poli_dept2(drop=codigodane);
set poli_dept(drop= x y);
id_dane_dept = catx("-","CO",put(codigodane,z2.));
run;
proc casutil;
load data=poli_dept2 outcaslib="casuser" casout="poli_dept" promote;
run;
proc casutil;
DROPTABLE casdata="poli_dept";
run;



/* datos*/

data robos_prep;
set robos_raw;
format mes date9.;
id_dane_mun = catx("-","CO",put(codigo_dane/1000, z5.));
id_dane_dept = catx("-","CO",put(codigo_dane/1000000, z2.));
fecha = mdy(month(fecha_hecho),01,year(fecha_hecho));
run;


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

cas auto;

proc casutil;
load data=robos_va outcaslib="casuser" casout="robos_va" promote;
run;




/*
proc casutil;
droptable casdata="robos_va" incaslib="casuser";
run;
*/
