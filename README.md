### Initialize:
```
python3 -m venv venv
source venv/bin/activate
pip3 install make
```

### Configure AWS Credentials:
```
make config
```

### Local Install:
```
make install
```

### Create infrastructure on AWS and deploy code:
```
make infra
```

### Run lambda function (to extract & transform data):
```
make data
```

### See files (extracted & transformed data in s3):
```
make see-files
```

### Run query (to process data):
```
make query
```

### Destroy infrastructure on AWS:
```
make destroy
```
-----
### Deploy code to AWS (only after code update):
```
make deploy
```
