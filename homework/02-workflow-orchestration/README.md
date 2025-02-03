## Module 2 Homework

ATTENTION: At the end of the submission form, you will be required to include a link to your GitHub repository or other public code-hosting site. This repository should contain your code for solving the homework. If your solution includes code that is not in file format, please include these directly in the README file of your repository.

> In case you don't get one option exactly, select the closest one 

For the homework, we'll be working with the _green_ taxi dataset located here:

`https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/green/download`

To get a `wget`-able link, use this prefix (note that the link itself gives 404):

`https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/`

### Assignment

So far in the course, we processed data for the year 2019 and 2020. Your task is to extend the existing flows to include data for the year 2021.

![homework datasets](https://raw.githubusercontent.com/DataTalksClub/data-engineering-zoomcamp/refs/heads/main/02-workflow-orchestration/images/homework.png)


As a hint, Kestra makes that process really easy:
1. You can leverage the backfill functionality in the [scheduled flow](../../../02-workflow-orchestration/flows/06_gcp_taxi_scheduled.yaml) to backfill the data for the year 2021. Just make sure to select the time period for which data exists i.e. from `2021-01-01` to `2021-07-31`. Also, make sure to do the same for both `yellow` and `green` taxi data (select the right service in the `taxi` input).
2. Alternatively, run the flow manually for each of the seven months of 2021 for both `yellow` and `green` taxi data. Challenge for you: find out how to loop over the combination of Year-Month and `taxi`-type using `ForEach` task which triggers the flow for each combination using a `Subflow` task.

#### Solution

Follow the [gcp setup](../../02_workflow_orchestration_kestra/README.md#run-etl-pipeline-with-google-cloud-platform) and run the backfill for the year 2021.
We can actually run the backfill for the complete year 2021 (from `2021-01-01` to `2021-12-31`), it will just fail for months not available, but this will not interfere with the other operations.

We added 570466 entries for 2021 into the `green_tripdata` table and We added 15000700 entries for 2021 into `yellow_tripdata` table : 

<details>
<summary>SQL queries</summary>


```sql
SELECT * 
FROM `kestra-sandbox-449806.de_zoomcamp.green_tripdata` AS t
WHERE
	t.filename LIKE 'green_tripdata_2021%';
```
570466

```sql
SELECT * 
FROM `kestra-sandbox-449806.de_zoomcamp.yellow_tripdata` as t
WHERE 
  t.filename LIKE 'yellow_tripdata_2021%';
```
15000700

</details>

### Quiz Questions

Complete the Quiz shown below. It’s a set of 6 multiple-choice questions to test your understanding of workflow orchestration, Kestra and ETL pipelines for data lakes and warehouses.

#### 1) Within the execution for `Yellow` Taxi data for the year `2020` and month `12`: what is the uncompressed file size (i.e. the output file `yellow_tripdata_2020-12.csv` of the `extract` task)?
- **128.3 MB** <<-
- 134.5 MB
- 364.7 MB
- 692.6 MB

##### Solution

After running the `06_gcp_taxi` flow, we can initially  check the output of the `extract` task, but this will vanish quickly. It is more reliable tocheck the file size in gcp [bucket](https://console.cloud.google.com/storage/browser/_details/kestra-de-zoomcamp-bucket-123456/yellow_tripdata_2020-12.csv;tab=live_object?inv=1&invt=AbokRA&project=kestra-sandbox-449806&supportedpurview=project). The file size is 128.3 MB.

---

#### 2) What is the rendered value of the variable `file` when the inputs `taxi` is set to `green`, `year` is set to `2020`, and `month` is set to `04` during execution?
- `{{inputs.taxi}}_tripdata_{{inputs.year}}-{{inputs.month}}.csv` 
- **`green_tripdata_2020-04.csv`** <<--
- `green_tripdata_04_2020.csv`
- `green_tripdata_2020.csv`

##### Solution

The rendered value of a variable is filled with the given input values, thus `file` is rendered to `green_tripdata_2020-04.csv`.

---

#### 3) How many rows are there for the `Yellow` Taxi data for all CSV files in the year 2020?
- 13,537.299
- **24,648,499** <<-
- 18,324,219
- 29,430,127

##### Solution

```sql
SELECT * 
FROM `kestra-sandbox-449806.de_zoomcamp.yellow_tripdata` as t
WHERE 
  t.filename LIKE 'yellow_tripdata_2020%'; 
```
24648499

---

#### 4) How many rows are there for the `Green` Taxi data for all CSV files in the year 2020?
- 5,327,301
- 936,199
- **1,734,051** <<--
- 1,342,034

##### Solution

```sql
SELECT * 
FROM `kestra-sandbox-449806.de_zoomcamp.green_tripdata` AS t
WHERE
	t.filename LIKE 'green_tripdata_2020%';
```
1734051

---

#### 5) How many rows are there for the `Yellow` Taxi data for the March 2021 CSV file?
- 1,428,092
- 706,911
- **1,925,152** <<--
- 2,561,031

##### Solution


```sql
SELECT * 
FROM `kestra-sandbox-449806.de_zoomcamp.yellow_tripdata` as t
WHERE 
  t.filename LIKE 'yellow_tripdata_2021-03%';
```
1925152

---

#### 6) How would you configure the timezone to New York in a Schedule trigger?
- Add a `timezone` property set to `EST` in the `Schedule` trigger configuration  
- **Add a `timezone` property set to `America/New_York` in the `Schedule` trigger configuration** <<--
- Add a `timezone` property set to `UTC-5` in the `Schedule` trigger configuration
- Add a `location` property set to `New_York` in the `Schedule` trigger configuration  


##### Solution

Update the timezone in schedule trigger of the flow (see [docs](https://kestra.io/docs/workflow-components/triggers/schedule-trigger)):

```yaml
[...]
triggers:
  - id: green_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    timezone: America/New_York
    cron: "0 9 1 * *"
    inputs:
      taxi: green
[...]
  ```

---

## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw2
* Check the link above to see the due date

## Solution

Will be added after the due date