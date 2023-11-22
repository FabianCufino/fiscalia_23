cas auto;
caslib _all_ assign;

proc casutil;
load data=sashelp.cars casout="cars" outcaslib= "casuser";
run;

proc casutil;
promote casdata="cars" outcaslib="casuser";
run;

proc casutil;
save casdata="cars" OUTCASLIB="casuser";
run;


proc casutil;
droptable casdata="cars" incaslib="casuser";
run;

cas auto term;
