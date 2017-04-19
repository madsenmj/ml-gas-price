# Gas Price Prediction Model

This project is a demonstration of a couple of different tools:

- R
- Microsoft Azure Data Factory
- Microsoft Azure ML
- Microsoft PowerBI
- Hadoop Pig

The final project presentation is a [PowerPoint presentation](Oil_Price_Demo.pptx) and a corresponding [YouTube Video](https://youtu.be/cvPfYq-O7Fc).

# Workflow

Create Azure Blob Storage

Storage Account Name: mmadsenads
Keys found in "settings -> Access Keys"

Created a blob container: gaspriceprod  (manually mirrored on the Allegient OneDrive account under gaspriceprod)

Uploaded the pig script: "oilproc.pig" to the blob container (see script at the end of this document)

Create Azure Data Factory

Created the factory Name: mmadsenadf

Under "Author and deploy" created the following items:

Linked Services:
AzureStorageLinkedService (connects to the Azure Blob storage created above)
EIATableLinkedService [from 0-8] (connects to a website with a table of data to pull the data from that table)
GasPriceAzureMLLinkedService (connects to the trained Azure ML model web service)
HDInsightOnDemandLinkedService (creates an HDInsight on-demand cluster for running a pig script)

Datasets
EIATableDataset [from 0-8] (inputs the web tables)
EIABlobDataset [from 0-8] (outputs the tables as text files, comma-separated to ABS)
EIAPigInput (input the pig script)
EIAPigOutput (output the results of the pig script)
EIAAzureMLResultBlob (creates a prediction of data based on the Azure ML model)

Pipelines
EIAtoBlobPipeline (get the data from the web tables and save it on the ABS)
EIAPigPipeline (run the pig script to process the data)
EIAPredictivePipeline (run the AML model against the data to make predictions

Execute Data Factory Jobs
From the "Diagram" on ADF, choose the output end point for one of the jobs by double-clicking. By selecting the "Recently updated slices" in the "Monitoring" tile, I manually run the job (clicking "Run" in the "Data Slice" blade that appears to the right.

Run the first two pipelines to create the training data set before creating the trained model.

Build Training Model
The Azure Machine Learning studio model consists of the following steps:
	1. Import Data (from the ABS container - import the training features and the training values as separate import steps)
	2. Edit Metadata (the columns are given names and the data type is updated based on the column information that was used in the pig script) - one Edit Metadata is needed for each data type to fix all of them
	3. Join Data (the training features and values are joined by the Date column, which they both have, as an inner join)
	4. Select Columns in Dataset (After the join, there are extra duplicate columns. This cleans those columns out)
	[[During initial testing, I inserted a "split data" node here to split the data into training and testing. This was removed to do the final training experiment]]
	5. Use a Boosted Decision Tree Regression (single parameter, 20 leaves per tree, 10 data points per leaf, learning rate of 0.2 and 200 trees)
	6. Train Model
	[[During initial testing, I inserted two more nodes: a "Score Model" node and an "Evaluate Model" node to check the model's performance on the split data. These were both removed to do the final training experiment.]]
	
Create Predictive Experiment
The default predictive experiment is not quite correct. I deleted the "Web service input" node and re-configured the "Import Data" node to have a web service parameter for the input file name. The input file is then passed to that node as a file name by the ADF pipeline.

After editing the metadata, I created a second "Select Columns in Dataset" node to pull the Date column to be joined with the data again after scoring it.

The input features are scored with a "Score Model" node, then the Date is joined to the scored data with a "Add columns" node (with the date on the left).

The output from this is then sent to the Web service output

Predict Data
I now run the final pipeline to predict the values of the final test features. This gives me four final files of data stored on the ABS:

trainvalues.txt/part-r-00000
testvalues.txt/part-r-00000
20150201trainpredictionresult.csv
20150201predictionresult.csv

The output from the pipeline creates the last two .csv files from the first two. (I manually changed the pipeline input and output files to create each output file separately, as it currently is configured, it only creates the data from the testfeatures.txt/part-r-00000 input file.)

Visualize Data
The last step is to create a report in Power BI to visualize the data. This involves a number of steps.

Power BI Queries:
	• Input the data from the Azure Blob storage (using the URL for each file)
	• Adjust the data types and column names for each column
	• Added a new column for each file: for the training data sets, added a column with the same entry "Model Training" and for the test data sets, the column with the same entry "Training Inputs"
	• Appended the Query "Test Values" to the Query "Train Values", then sorted the rows by date and added an index column
	• Appended the Query "Test Features" to the Query "Train Features", then sorted by date and added an index column
	• Merged the two appended tables together using the Index column as the merge index, a left outer join
	• Sort the rows by date and take care of any row re-naming that needs to be done
	

The next step is to create the Measures that I need to work with:
	• Get the price of the last day filtered on the page: the calculate gets the entry from the GasPrice column based on the filter where we are looking for the Index that matches the Max of the Index column. Since the Index column is in chronological order, this works to give us the last date. Probably not the most elegant solution, but it works.
		○ CurrentPrice = FORMAT(CALCULATE(LASTNONBLANK('AllData'[Values.GasPrice],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index])-1)),"$#.##")
	• PredictDate = FORMAT( CALCULATE(LASTNONBLANK('AllData'[Values.RealDate],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))), "MM/DD/YYYY")
	• EndDate2 = FORMAT(CALCULATE(LASTNONBLANK('AllData'[Date],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))),"MM/DD/YYYY")
	• RealPrice = (CALCULATE(LASTNONBLANK('AllData'[Values.GasPrice],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))))
	• PredictDate = FORMAT( CALCULATE(LASTNONBLANK('AllData'[Values.RealDate],1), FILTER(ALL('AllData'),'AllData'[Index]=MAX('AllData'[Index]))), "MM/DD/YYYY")

The last step is to make the graphs and format the page so that it is user-friendly and displays the information we want.
