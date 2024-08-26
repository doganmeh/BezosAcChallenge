### Initialize:
```
python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade pip
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

### Deploy code to AWS (only after code update):
```
make deploy
```

### Run lambda function (to prepare data):
```
make run
```

### Destroy infrastructure on AWS:
```
make destroy
```
