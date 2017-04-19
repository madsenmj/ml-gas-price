# Gas Price Prediction Model

This project is a demonstration of a couple of different tools:

- R
- Microsoft Azure Data Factory
- Microsoft Azure ML
- Microsoft PowerBI
- Hadoop Pig

The final project presentation is a [PowerPoint presentation](Oil_Price_Demo.pptx) and a corresponding [YouTube Video](https://youtu.be/cvPfYq-O7Fc).

# Data Exploration

Preliminary data exploration is done in R. The [R ipython notebook goes through the data exploration.](/src/PricePredictor.ipynb)

# Train Azure ML Model

## Build Azure Training Model

![AzureML Image](/docs/AzureMLsetup.png)

The Azure Machine Learning studio model consists of the following steps:

1. Import Data Node: imports the training features and the training values as separate import steps from the Azure Blob Storage container.
2. Edit Metadata Node: The columns are given names and the data type is updated based on the column information that was used in the pig script. One Edit Metadata is needed for each data type to fix all of them
3. Join Data Node (Preliminary training, not shown): The training features and values are joined by the Date column, which they both have, as an inner join.
4. Select Columns in Dataset Node: After the join, there are extra duplicate columns. This cleans those columns out. Note: During initial testing, I inserted a "split data" node here to split the data into training and testing. This was removed to do the final training experiment.
5. Use a Boosted Decision Tree Regression Node: Use a single parameter, 20 leaves per tree, 10 data points per leaf, learning rate of 0.2 and 200 trees.
6. Train Model Node: During initial testing, I inserted two more nodes: a "Score Model" node and an "Evaluate Model" node to check the model's performance on the split data. These were both removed to do the final training experiment.


## Create Predictive Experiment
The default predictive experiment is not quite correct. I deleted the "Web service input" node and re-configured the "Import Data" node to have a web service parameter for the input file name. The input file is then passed to that node as a file name by the Azure Data Factory pipeline.

After editing the metadata, I created a second "Select Columns in Dataset" node to pull the Date column to be joined with the data again after scoring it.

The input features are scored with a "Score Model" node, then the Date is joined to the scored data with a "Add columns" node (with the date on the left).

The output from this is then sent to the Web service output.

## Predict Data
I now run the final pipeline to predict the values of the final test features. This gives me four final files of data stored in the [Azure Blob Storage container](/src/blobstoragecontainer):

- trainvalues.txt/part-r-00000
- testvalues.txt/part-r-00000
- 20150201trainpredictionresult.csv
- 20150201predictionresult.csv

The output from the pipeline creates the last two .csv files from the first two. (Note: I manually changed the pipeline input and output files to create each output file separately, as it currently is configured, it only creates the data from the testfeatures.txt/part-r-00000 input file.)

## Get Azure ML web service endpoint

I get the webservice endpoint and api key from the Azure ML web service portal. I need these to set up the automatic scoring in the Data Factory.

# Build the Azure Data Factory 

The instructions and scripts for building the [Azure Data Factory are here.](/src/AzureDataFactory/README.md)

# Visualize Data
The last component is to create a [report in Power BI](/src/PricePredictor.pbix) to visualize the data.

## Build the Power BI Queries

The PowerBI report is linked directly to the predictions stored in Azure Blob Storage. The query is build using the following steps.

1. Input the data from the Azure Blob storage (using the URL for each file)
2. Adjust the data types and column names for each column
3. Added a new column for each file: for the training data sets, added a column with the same entry "Model Training" and for the test data sets, the column with the same entry "Training Inputs"
4. Appended the Query "Test Values" to the Query "Train Values", then sorted the rows by date and added an index column
5. Appended the Query "Test Features" to the Query "Train Features", then sorted by date and added an index column
6. Merged the two appended tables together using the Index column as the merge index, a left outer join
7. Sort the rows by date and take care of any row re-naming that needs to be done	

The next step is to create the Measures to plot the data.
- Get the price of the last day filtered on the page: the calculate gets the entry from the GasPrice column based on the filter where we are looking for the Index that matches the Max of the Index column. Since the Index column is in chronological order, this works to give us the last date. Probably not the most elegant solution, but it works.
- `CurrentPrice = FORMAT(CALCULATE(LASTNONBLANK('AllData'[Values.GasPrice],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index])-1)),"$#.##")`
- `PredictDate = FORMAT( CALCULATE(LASTNONBLANK('AllData'[Values.RealDate],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))), "MM/DD/YYYY")`
- `EndDate2 = FORMAT(CALCULATE(LASTNONBLANK('AllData'[Date],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))),"MM/DD/YYYY")`
- `RealPrice = (CALCULATE(LASTNONBLANK('AllData'[Values.GasPrice],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))))`
- `PredictDate = FORMAT( CALCULATE(LASTNONBLANK('AllData'[Values.RealDate],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))), "MM/DD/YYYY")`

The last step is to make the graphs and format the page so that it is user-friendly and displays the information we want.
