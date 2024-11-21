<!--
---
page_type: sample
name: Azure Cosmos DB for NoSQL with CosmicWorks Azure Developer CLI template
description: This AZD template deploys an Azure Cosmos DB for NoSQL instance with CosmicWorks data set pre-seeded.
urlFragment: template
languages:
- azdeveloper
products:
- azure-sql
---
-->

# Azure Cosmos DB for NoSQL with CosmicWorks Azure Developer CLI template

This template deploys an Azure Cosmos DB for NoSQL instance with CosmicWorks data set pre-seeded.

## Details

| | Value |
| --- | --- |
| **Database name** | `cosmicworks` |
| **Container names** | `products` &amp; `employees` |

## Deploy

```
azd init --template database-templates-cosmos-db-nosql-cosmicworks --environment development
 
azd up
```

## Clean-up

```
azd down --force --purge
```
