## Data ingestion with dlt

[Workshop Repository](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2025/workshops/dlt/README.md)

Video: https://www.youtube.com/live/pgJWP_xqO1g

[Google Colab notebook](https://colab.research.google.com/drive/1AjYx8gnTxUZ4_lytb_7UHDdJruDJlHUA#scrollTo=dJzV8K79CCf7)

## 📖 Course overview
This workshop is structured into three key parts:

1️⃣ **[Extracting Data](data_ingestion_workshop.md#extracting-data)** – Learn scalable data extraction techniques.  
2️⃣ **[Normalizing Data](data_ingestion_workshop.md#normalizing-data)** – Clean and structure data before loading.  
3️⃣ **[Loading & Incremental Updates](data_ingestion_workshop.md#loading-data)** – Efficiently load and update data.  

📌 **Find the full course file here**: [Course File](data_ingestion_workshop.md)  

---

### Data Pipelines

![alt text](https://github.com/DataTalksClub/data-engineering-zoomcamp/raw/main/cohorts/2025/workshops/dlt/img/pipes.jpg)

#### Difference between dlt and dbt


- dlt (Data Load Tool), is a tool for data ingestion. I takes care of the collection, ingestion and storage parts of a data pipeline.
- dbt (Data Build Tool), is a tool for data transformation. It will be used to consume data that has already passed all previous steps of preprocessing with the data pipeline.

#### Difference between Data Stores

- Data Lake: Raw data store, unprocessed data. Quick and easy access to data.
- Data Warehouse: Clean data, processed data. Slow access to data.
- Data Lakehouse: Hybrid of Data Lake and Data Warehouse. Raw data is stored in Files, while metadata is stored in a Data Warehouse.

### Supported Data Sources and Destinations

- [Data Sources](https://dlthub.com/docs/dlt-ecosystem/verified-sources/)

- [Data Destinations](https://dlthub.com/docs/dlt-ecosystem/destinations/)




### DLT UI

There is a streamlit app included, which can be used to view the data that has been ingested.

Docs: https://dlthub.com/docs/general-usage/dataset-access/streamlit

### DLT Use Cases

#### Extracting Data

[Example of extracting data](data_ingestion_workshop.md#example-of-extracting-data-with-dlt)

#### Normalizing Data

[Example of Normalizing Data](data_ingestion_workshop.md#normalizing-data-with-dlt)

How does dlt normalize data automatically?

It works with the concept of [schemas](https://dlthub.com/docs/general-usage/schema/), which describes the structure of the data.

#### Loading Data

[Example of Simple Loading Data](data_ingestion_workshop.md#example-loading-data-into-database-with-dlt)


[Example of Incremental Loading Data](data_ingestion_workshop.md#example-incremental-loading-with-dlt)

[Example of Loading Data into a Data Warehouse (BigQuery)](data_ingestion_workshop.md#example-loading-data-into-a-data-warehouse-bigquery)


[Example of Example: Loading data into a Data Lake (Parquet on Local FS or S3)](data_ingestion_workshop.md#example-loading-data-into-a-data-lake-parquet-on-local-fs-or-s3)