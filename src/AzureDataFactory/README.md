# Azure Data Factory Provisioning

## Requirements

- Create a Storage Account with name: blobstorageaccount
- Get the storage account keys found in "settings -> Access Keys"
- Create a blob storage container: blobstoragecontainer 
- Upload the pig script: ["oilproc.pig"](/src/blobstoragecontainer/oilproc.pig) to the blob container
- Upload the pig utility script ["piggybank.jar"](/src/blobstoragecontainer/piggybank.jar) to the blob container

I also create an AzureML trained model to make predictions on the data. I get the web service endpoint and API key from the AzureML portal.

## Provision Data Factory

Create the factory Name: azuredatafactory
 
Under "Author and deploy" create the following items:
 
Linked Services:

- [AzureStorageLinkedService](AzureStorageLinkedService.json): connects to the Azure Blob storage created above
- [EIATableLinkedService](EIATableLinkedService.json): Retrieves the daily Crude Oil Spot Price from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.RWTC.D)
- [EIATableLinkedService0](EIATableLinkedService0.json): Retrieves weekly Gas Prices from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.EMM_EPM0U_PTE_NUS_DPG.W)
- [EIATableLinkedService2](EIATableLinkedService2.json): Retrieve weekly Stock of Finished Gas from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WGFSTUS1.W)
- [EIATableLinkedService3](EIATableLinkedService3.json): Retrieve weekly Days supply of gas from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.W_EPM0_VSD_NUS_DAYS.W)
- [EIATableLinkedService4](EIATableLinkedService4.json): Retrieve weekly Gas Imports from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WGTIMUS2.W)
- [EIATableLinkedService5](EIATableLinkedService5.json): Retrieve weekly Refinery Utilization from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WPULEUS3.W)
- [EIATableLinkedService7](EIATableLinkedService7.json): Retrieve weekly Crude Oil Exports from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WCREXUS2.W)
- [EIATableLinkedService8](EIATableLinkedService8.json): Retrieve weekly Crude Oil Imports [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WCRIMUS2.W)
- [GasPriceAzureMLLinkedService](GasPriceAzureMLLinkedService.json) Connects to the trained Azure ML model web service
- [HDInsightOnDemandLinkedService](HDInsightOnDemandLinkedService.json) Create an HDInsightOnDemand service to run the Hadoop PIG script which processes and joins the data prior to making predictions.
 
 
 

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
