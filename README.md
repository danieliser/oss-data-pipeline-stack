# oss-data-pipeline-stack
Attempt at making a cohesive open-source, self-hosted data pipeline.


## What is this?

This is an attempt at making a cohesive open-source, self-hosted data pipeline. It is a collection of tools that can be used to build a data pipeline that is open-source, self-hosted, and can be deployed on a single machine. It is not meant to be a production-ready solution, but rather a proof of concept that can be used to build a production-ready solution.

## Getting Started

After ensuring you have the [requirements](#Requirements) installed, you can run the following commands to get started:

```bash
git clone git@github.com:/danieliser/oss-data-pipeline-stack.git
cd oss-data-pipeline-stack



## Accessing the tools

### Web UI
- [Appsmith](https://localhost:8082)
- [Airbyte](https://localhost:8000)
- [Minio(S3 Block Storage)](https://localhost:9000)
- [DBeaver](https://localhost:8978)
- [Tensorflow Notebooks](https://localhost:8888)

### Services
- [Hydra(Postgres DB)](https://localhost:5432)
- [Minio(S3 Block Storage)](https://localhost:9001)


## Still possibly to do

- [ ] Add Prefect2
- [ ] Add Airflow
- [ ] Add dbt
- [ ] Add MetaBase
- [ ] Add superset
- [ ] Add PowerBI
- [ ] Add Looker
- [ ] Add Redash
- [ ] Add RStudio
- [ ] Add DVC
- [ ] Add MLFlow
- [ ] Add Streamlit
- [ ] Add kubeflow