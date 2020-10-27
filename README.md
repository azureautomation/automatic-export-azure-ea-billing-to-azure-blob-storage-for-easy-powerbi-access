Automatic export Azure EA Billing to Azure Blob Storage for easy PowerBi access
===============================================================================

            

 


##################################################################################################


This Azure Automation Runbook is based on the work done by Christer Ljung and Tom Hollander


https://blogs.msdn.microsoft.com/tomholl/2016/03/08/analysing-enterprise-azure-spend-by-tags/


http://www.redbaronofazure.com/?p=631


##################################################################################################


 


**Description**


This script automatically pulls the latest billing information from the Azure EA API and dumps it in a Azure Blob Storage container, which allows PowerBi to consume the information in the CSV file. This allow a very easy and automated approach for visualization
 of the Azure billing information. The script also extract both Azure Tags and Ressources Groups as well.


Enjoy.


**Release notes**


1.0.1 - Added force overwrite for existing CSV files


**Input needed:**


  *  Azure Enterprise Agreement API Key 
  *  Azure Enteprise Agreement Number 
  *  Azure Storage Account Key 
  *  Azure Storage Account Name 
  *  Azure Storage Account Container 

 


![Image](https://github.com/azureautomation/automatic-export-azure-ea-billing-to-azure-blob-storage-for-easy-powerbi-access/raw/master/2017_02_21_14_27_59_.png)


![Image](https://github.com/azureautomation/automatic-export-azure-ea-billing-to-azure-blob-storage-for-easy-powerbi-access/raw/master/2017_02_21_14_27_59-1.png)


![Image](https://github.com/azureautomation/automatic-export-azure-ea-billing-to-azure-blob-storage-for-easy-powerbi-access/raw/master/2017_02_21_14_27_59-2.png)


 


 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
