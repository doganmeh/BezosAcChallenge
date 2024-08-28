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

### Run lambda function (to prepare data):
```
make data
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
