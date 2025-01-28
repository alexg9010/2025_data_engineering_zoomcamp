
previous lesson: [01_docker](../01_docker/README.md) 

- [1.3.1 Terraform Primer](#131-terraform-primer)
  - [Terraform Commands](#terraform-commands)
- [1.3.2 Terraform Basics](#132-terraform-basics)
  - [Install Terraform + Vscode Plugin](#install-terraform--vscode-plugin)
  - [Create Terraform Test Project](#create-terraform-test-project)
    - [Use the gcloud command line tool](#use-the-gcloud-command-line-tool)
    - [Export credentials to environment variables](#export-credentials-to-environment-variables)
  - [Initialize provider](#initialize-provider)
  - [Create a google cloud bucket](#create-a-google-cloud-bucket)
  - [!!! Before uploading to GitHub !!!](#-before-uploading-to-github-)
- [1.3.3 Terraform Variables](#133-terraform-variables)
  - [Adding BigQuery Dataset](#adding-bigquery-dataset)
  - [Using Variables](#using-variables)



## 1.3.1 Terraform Primer

[Terraform](https://www.terraform.io) is a configuration management tool that allows you to define and manage infrastructure resources using code. It is used to automate the provisioning and management of infrastructure resources, such as virtual machines, networks, and storage.

Using a `provider` to interact with the cloud provider, you can define the resources you want to create and manage, and Terraform will take care of creating and managing them for you. [Providers](https://registry.terraform.io/browse/providers) include AWS, Azure, Google Cloud, and many others.

### Terraform Commands

- `terraform init`: initialize a working directory containing Terraform configuration files

- `terraform plan`: show changes Terraform will make to your infrastructure

- `terraform apply`: apply changes Terraform will make to your infrastructure

- `terraform destroy`: destroy all resources Terraform created

## 1.3.2 Terraform Basics

We want to use terraform with GCP. We need to create a service account and a key in the [GCP console](https://console.cloud.google.com/welcome?hl=de&inv=1&invt=AboC4Q&project=gen-lang-client-0996108631).

In the dashboard, I created a new project called [`terraform-demo`](https://console.cloud.google.com/welcome?inv=1&invt=AboC4Q&project=terraform-demo-449210), then moved to IAM and Admin panel to create a [service account](https://console.cloud.google.com/iam-admin/serviceaccounts?inv=1&invt=AboC4Q&project=terraform-demo-449210). The new service account `terraform-runner` should get the following permissions: "Storage Admin", "BiqQuery Admin" and "Compute Admin". We add a key with credentials and downloaded as a JSON file.

### Install Terraform + Vscode Plugin

[Terraform installation](https://developer.hashicorp.com/terraform/install) and [Extension](https://marketplace.visualstudio.com/items?itemName=hashicorp.terraform)

Via Homebrew:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Via Micromamba:
```bash
micromamba install -n $(basename $PWD) -c conda-forge terraform
```

### Create Terraform Test Project

```bash
mkdir -p terrademo
cd terrademo
mkdir keys 
cp ~/Downloads/terraform-demo-*.json keys/
```

Create a `main.tf` file with a GCP provider configuration. Find the GCP provider [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs).
Use the default configuration found at the "Use Provider" panel, then copy the example code into the `main.tf` file.

Use `terraform fmt` to format the code.

Fetch the project id from the GCP console and replace the `my-project-id` placeholder in the `main.tf` file. Optionally search for the [region](https://cloud.google.com/about/locations) closest to your location.

You have to add credentials to the project. This can be done in multiple ways:
- add `credentials` to the `provider` in the `main.tf` file
- use the `gcloud` [command line tool](https://cloud.google.com/cli?hl=de) 
- export credentials to the `GOOGLE_APPLICATION_CREDENTIALS` environment variable



#### Use the gcloud command line tool

install the gcloud command line tool:

```bash
brew install --cask google-cloud-sdk
```

Make sure to unset the `GOOGLE_APPLICATION_CREDENTIALS` environment variable:

```bash
unset GOOGLE_APPLICATION_CREDENTIALS  
```

Give the gcloud command line tool permission to access your GCP account:

```bash
gcloud auth application-default login
```


#### Export credentials to environment variables

Download the credentials file from the GCP console and save it to the `keys` folder. Export your credentials as environment variables:

```bash 
export GOOGLE_APPLICATION_CREDENTIALS="path/to/terraform-demo-xxx.json"
```

This is how the `main.tf` file should look like:

<details>
<summary>main.tf</summary>

```terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.0"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs
provider "google" {
  project = "terraform-demo-449214"
  region  = "europe-west10"
}

resource "google_storage_bucket" "demo-bucket" {
  ## bucket name has to be unique across all google cloud storage
  ## usually bucket name is in the format of <project_id>-<bucket_name>
  name = "terraform-demo-449214-terra-bucket"
  ## adjust if you want to use a different location
  location      = "EU"
  force_destroy = true

  ## delete bucket after 3 days
  lifecycle_rule {
    condition {
      ## Minimum age of an object in days
      age = 3
    }
    action {
      type = "Delete"
    }
  }

  ## automatically abort multipart uploads that are incomplete after x days
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
```
</details>

### Initialize provider

This will download the provider code and create a `.terraform.lock.hcl` lock file.

```bash
terraform init
```

### Create a google cloud bucket

Search the [google_storage_bucket docs](https://registry.terraform.io/providers/hashicorp/google/5.0.0/docs/resources/storage_bucket.html) for the life cycle settings example. Explore the comments in the `main.tf` file for more information.

Review with `terraform plan` to see what will be created.

```bash
terraform plan
```


Deploy the resources with `terraform apply`.

```bash
terraform apply
```

The `terraform.tfstate` file is a state file that keeps track of the resources that have been created. 

We can go to the GCP console to see the [bucket](https://console.cloud.google.com/storage/browser?inv=1&invt=AboD4g&project=terraform-demo-449214&pageState=("StorageBucketsTable":("f":"%255B%255D","s":%5B("i":"name","s":"0")%5D,"r":30))) has been created.



### !!! Before uploading to GitHub !!!

Add a `.gitignore` file for the terraform config, e.g. this one from [here](https://github.com/github/gitignore/blob/main/Terraform.gitignore).



## 1.3.3 Terraform Variables

### Adding BigQuery Dataset

We want to add a [BigQuery dataset](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) to our project. This requires at least a dataset id.

Adding this part to the `main.tf` file:

```terraform
resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id                  = "demo_dataset"
}
```

And running `terraform plan`, followed by `terraform apply` will create a new dataset in our project.

### Using Variables

Instead of hardcoding the project id in the `main.tf` file, we can use variables to make the configuration more flexible.

Variables defined in the `variables.tf` file can be used in the `main.tf` file via the `var` object. When using the vscode extension, the variables are autocompleted. 