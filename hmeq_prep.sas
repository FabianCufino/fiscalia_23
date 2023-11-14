cas auto;

filename file url "https://raw.githubusercontent.com/Vitalii36/kaggle_HMEQ_dataset/master/Data/datasets.csv" termstr=crlf;
proc import datafile= file
out=HMEQ
replace
dbms=csv;
run;



caslib _all_ assign;
proc casutil;
	load data=work.hmeq outcaslib="casuser"
	casout="HMEQ" promote;
run;


Proc casutil;
 drop table 
