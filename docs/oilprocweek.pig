/*
Pig file to input, process, and combine the input data for the gas price prediction model
5/20/2016
Martin John Madsen

*/

--We have eight data sets to load in
--The first data set needs to be changed to a weekly average
--We will join all the data sets by the calulated week and year

input1 = LOAD '$Input1' USING PigStorage(',') 
	as (labela:chararray, labelb:chararray, labelc:chararray, datestr:chararray, freq, value1:float, unit);
input2 = LOAD '$Input2' USING PigStorage(',') 
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value2:int, unit);
input3 = LOAD '$Input3' USING PigStorage(',') --input3 = LOAD 'input_3.txt' using PigStorage(',')
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value3:float, unit);
input4 = LOAD '$Input4' USING PigStorage(',') 
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value4:int, unit);
input5 = LOAD '$Input5' USING PigStorage(',') 
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value5:float, unit);
input7 = LOAD '$Input7' USING PigStorage(',') 
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value7:int, unit);
input8 = LOAD '$Input8' USING PigStorage(',') 
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value8:int, unit);

--Now we need to pull in the price data to get it organized in a similar manner
input0 = LOAD '$Input0' using PigStorage(',')
	as (labela:chararray, labelb:chararray, datestr:chararray, freq, value0:float, unit);

--fix the date column	
input1a = foreach input1 
	generate ToDate(datestr,'yyyyMMdd')
    as (date1:DateTime),value1;
input2a = foreach input2 
	generate ToDate(datestr,'yyyyMMdd')
    as (date2:DateTime),value2;
input3a = foreach input3 
	generate ToDate(datestr,'yyyyMMdd')
    as (date3:DateTime),value3;
input4a = foreach input4 
	generate ToDate(datestr,'yyyyMMdd')
    as (date4:DateTime),value4;
input5a = foreach input5 
	generate ToDate(datestr,'yyyyMMdd')
    as (date5:DateTime),value5;
input7a = foreach input7 
	generate ToDate(datestr,'yyyyMMdd')
    as (date7:DateTime),value7;
input8a = foreach input8 
	generate ToDate(datestr,'yyyyMMdd')
    as (date8:DateTime),value8;
--The prices we are trying to predict actually happen a week after the rest of the variables.
--In order to match them up, we will subtract three days from the oil price date when computing the week
--This will give us the match we want

input0a = foreach input0 
	generate SubtractDuration( ToDate(datestr,'yyyyMMdd'), 'P3D') as (date0:DateTime),
	ToDate(datestr,'yyyyMMdd') as (date0real:DateTime),
	value0;
	
--Now get the week
input1b = foreach input1a generate
	GetYear(date1) as year,
	GetWeek(date1) as week,
	date1,
	value1;
input2b = foreach input2a generate
	GetYear(date2) as year,
	GetWeek(date2) as week,
	date2,
	value2;
input3b = foreach input3a generate
	GetYear(date3) as year,
	GetWeek(date3) as week,
	date3,
	value3;
input4b = foreach input4a generate
	GetYear(date4) as year,
	GetWeek(date4) as week,
	date4,
	value4;
input5b = foreach input5a generate
	GetYear(date5) as year,
	GetWeek(date5) as week,
	date5,
	value5;
input7b = foreach input7a generate
	GetYear(date7) as year,
	GetWeek(date7) as week,
	date7,
	value7;
input8b = foreach input8a generate
	GetYear(date8) as year,
	GetWeek(date8) as week,
	date8,
	value8;	
input0b = foreach input0a generate
	GetYear(date0) as year,
	GetWeek(date0) as week,
	date0real as date0,
	value0;	

	
--Now group the spot prices by week
input1c = foreach (group input1b by (year, week) )
	{
	inner_row = ORDER input1b.date1 BY date1 DESC;
	first_row = LIMIT inner_row 1;
	generate
	flatten ( group ) as (year, week),
	flatten ( first_row ) as date1,
	AVG(input1b.value1) as meanval1;
	}

--update our key to a single field yeardate for future joining
input1d = foreach input1c generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date1,
	week,
	meanval1;
input2d = foreach input2b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date2,
	value2;
input3d = foreach input3b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date3,
	value3;
input4d = foreach input4b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date4,
	value4;
input5d = foreach input5b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date5,
	value5;
input7d = foreach input7b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date7,
	value7;
input8d = foreach input8b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date8,
	value8;
input0d = foreach input0b generate
	CONCAT ( (chararray) year , (chararray) week ) as yearweek,
	date0,
	value0;
	
input12 = join input1d by yearweek, input2d by yearweek;
input12a = foreach input12 generate input1d::yearweek as yearweek,date1,week,meanval1,value2;
input123 = join input12a by yearweek, input3d by yearweek;
input123a = foreach input123 generate input12a::yearweek as yearweek ,date1,week,meanval1,value2,value3;
input1234 = join input123a by yearweek, input4d by yearweek;
input1234a = foreach input1234 generate input123a::yearweek as yearweek ,date1,week,meanval1,value2,value3,value4;
input12345 = join input1234a by yearweek, input5d by yearweek;
input12345a = foreach input12345 generate input1234a::yearweek as yearweek ,date1,week,meanval1,value2,value3,value4,value5;
input123457 = join input12345a by yearweek, input7d by yearweek;
input123457a = foreach input123457 generate input12345a::yearweek as yearweek ,date1,week,meanval1,value2,value3,value4,value5,value7;
input1234578 = join input123457a by yearweek, input8d by yearweek;
input1234578a = foreach input1234578 generate input123457a::yearweek as yearweek ,date1,week,meanval1,value2,value3,value4,value5,value7,value8;


--Now we join the output column to everything before splitting the training/testing data
alldata = join input1234578a by yearweek, input0d by yearweek;

testdiv = filter alldata by date1 > ToDate('2015-9-1');
traindiv = filter alldata by date1 <= ToDate('2015-9-1');

testdata = order testdiv by date1 ASC;
traindata = order traindiv by date1 ASC;

trainfeatures = foreach traindata generate date1, week, meanval1, value2, value3, value4, value5, value7, value8;
testfeatures = foreach testdata generate date1, week, meanval1, value2, value3, value4, value5, value7, value8;

trainvalues = foreach traindata generate date1, date0, value0;
testvalues = foreach testdata generate date1, date0, value0;

STORE trainfeatures into '$Output1' USING PigStorage (',');
STORE testfeatures into '$Output2' USING PigStorage (',');
STORE trainvalues into '$Output3' USING PigStorage (',');
STORE testvalues into '$Output4' USING PigStorage (',');
