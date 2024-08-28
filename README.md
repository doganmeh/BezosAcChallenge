# Installation & Use

### 1. Initialize:
```
python3 -m venv venv
source venv/bin/activate
pip3 install make
```

### 2.a. Configure AWS Credentials:
```
make config
```

### 2.b. Export your AWS Account ID:
```
export AWS_ACCNT_ID=????
```

### 3. Local Install:
```
make install
```

### 4. Create infrastructure on AWS and deploy code:
```
make infra
```

### 5. Run lambda function (to extract & transform data):
```
make data
```

### 6. See files (extracted & transformed data in s3):
```
make see-files
```

### 7. Run query (to get enrollment summary):
```
make query-enrollment
```

### 8. Destroy infrastructure on AWS:
```
make destroy
```
___
# Submission Questions
#### Provide a SQL query that will answer this question: In 2021, which 10 states had the highest number of children enrolled in Pre-K

Please see #7 above. The code is in the `Makefile`. Here is the result:

| fips | total_enrollment |
|------|-----------------:|
| 48   |          245,135 |
| 17   |           71,078 |
| 12   |           58,900 |
| 36   |           56,452 |
| 55   |           51,159 |
| 13   |           46,841 |
| 34   |           43,884 |
| 39   |           39,632 |
| 40   |           37,733 |
| 51   |           30,979 |

### List all tools and technologies you used:

AWS Lambda, S3, Athena, Make

### Explain your rationale for approaching this task:

- For non-computationally intensive applications like this, Lambda would be very cost-effective and scalable.
- This solution can be scheduled to extract future years incrementally via CloudWatch/EventBridge.
- I kept data in `.json` format because the performance was good enough. 

### What else would you do if you had more time:
Depending on the importance of this data to the business I would consider:
- Put transformation logic in a separate Lambda function to isolate processes and to be able to run them separately when needed
- Make it repeatable: let it clean-up and pick up from where left off the second time it is run
- More data validation
- IaC: such as CDK or TerraForm
- More testing:
  - Add unit tests (mock data/components, or live)
  - IaC allows to test pipelines in non-prod environments end-to-end.
- Containerization.
- Better resilience: regional fail-overs (or warm/active stand-by).
- Better monitoring: 
  - track lambda metrics such as execution time, memory
  - track record counts year over year to detect anomalies
  - alert dev team if things fail e.g., PagerDuty
- Better governance: document schema, etc. 
- Better modeling or treating data as a product. 
- If data and the queries will grow, parquet may be better than json.
___
# Misc Useful Stuff
### Deploy code to AWS (only after code update):
```
make deploy
```

### Run query to validate record counts by year (a basic validation):
```
make query-counts
```
___


