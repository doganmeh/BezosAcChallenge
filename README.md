### Initialize:
```
python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade pip
pip3 install make
```

### Install:
```
make install
```

### Configure AWS Credentials:
```
make config
```

### Create infrastructure on AWS:
```
make infra
```

### Destroy infrastructure on AWS:
```
make destroy
```
