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
 
### Linked Services

- AzureStorageLinkedService.json: connects to the Azure Blob storage created above
- EIATableLinkedService.json: Retrieves the daily Crude Oil Spot Price from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.RWTC.D)
- EIATableLinkedService0.json: Retrieves weekly Gas Prices from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.EMM_EPM0U_PTE_NUS_DPG.W)
- EIATableLinkedService2.json: Retrieve weekly Stock of Finished Gas from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WGFSTUS1.W)
- EIATableLinkedService3.json: Retrieve weekly Days supply of gas from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.W_EPM0_VSD_NUS_DAYS.W)
- EIATableLinkedService4.json: Retrieve weekly Gas Imports from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WGTIMUS2.W)
- EIATableLinkedService5.json: Retrieve weekly Refinery Utilization from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WPULEUS3.W)
- EIATableLinkedService7.json: Retrieve weekly Crude Oil Exports from [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WCREXUS2.W)
- EIATableLinkedService8.json: Retrieve weekly Crude Oil Imports [www.eia.gov](http://www.eia.gov/opendata/qb.cfm?sdid=PET.WCRIMUS2.W)
- GasPriceAzureMLLinkedService.json: Connects to the trained Azure ML model web service
- HDInsightOnDemandLinkedService.json: Create an HDInsightOnDemand service to run the Hadoop PIG script which processes and joins the data prior to making predictions.
 
### Datasets
- EIATableDataset.json, EIATableDataset0.json, EIATableDataset1.json, EIATableDataset2.json, EIATableDataset3.json, EIATableDataset4.json, EIATableDataset5.json, EIATableDataset7.json, EIATableDataset8.json: These datasets provide the inputs from the blob storage to the pipelines.
- EIABlobDataset.json, EIABlobDataset0.json, EIABlobDataset1.json, EIABlobDataset2.json, EIABlobDataset3.json, EIABlobDataset4.json, EIABlobDataset5.json, EIABlobDataset7.json, EIABlobDataset8.json: These datasets are the outputs from the pipeline to blob storage.
- EIAPigInput.json: Input the pig script
- EIAPigOutput.json: Output the results of the pig script
- EIAAzureMLResultBlob.json: Creates a prediction of data based on the Azure ML model.
 
### Pipelines
- EIAtoBlobPipeline.json: Get the data from the web tables and save it in the Azure Blob storage container.
- EIAPigPipeline.json:  Run the pig script to process the data.
- EIAPredictivePipeline.json: Run the AML model against the data to make predictions.
 
### Pipeline Update:
- EIAPipeline.json: Changes the frequency to weekly. Also integreates the other two pipelines into a single script.
 
## Execute Data Factory Jobs
From the "Diagram" on ADF, choose the output end point for one of the jobs by double-clicking. By selecting the "Recently updated slices" in the "Monitoring" tile, I manually run the job (clicking "Run" in the "Data Slice" blade that appears to the right.
 
Run the first two pipelines to create the training data set before creating the trained model.

After running a single time, use the EIAPipeline to run the entire script weekly.
