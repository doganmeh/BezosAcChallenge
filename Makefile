PYTHON_VER=python3.12
AWS_ACCNT_ID=897722699304
BUCKET_NAME=mehmet-bezos-challenge
REGION=us-east-1
LAMBDA_NAME=MehmetBezosChallenge
ROLE_NAME=MehmetLambdaS3WriteRole

install:
	pip3 install -r dev_requirements.txt
	pip3 install -r prod_requirements.txt
	rm -rf build && mkdir -p build
	pip3 install -r prod_requirements.txt --target ./build
	cp src/* build/
	cd build && zip -r ../build.zip .

config:
	aws configure

build:
	cp src/* build/
	cd build && zip -ur ../build.zip .

deploy: build
	aws lambda update-function-code \
		--function-name $(LAMBDA_NAME) \
		--zip-file fileb://build.zip

run:
	rm -f output.txt
	aws lambda invoke \
		--function-name $(LAMBDA_NAME) \
		output.txt

role:
	aws iam create-role \
		--role-name $(ROLE_NAME) \
		--assume-role-policy-document '{ \
			"Version": "2012-10-17", \
			"Statement": [ \
				{ \
					"Effect": "Allow", \
					"Principal": { \
						"Service": "lambda.amazonaws.com" \
					}, \
					"Action": "sts:AssumeRole" \
				} \
			] \
		}'

	aws iam attach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

	aws iam attach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

lambda:
	aws lambda create-function \
		--function-name $(LAMBDA_NAME) \
		--runtime $(PYTHON_VER) \
		--role arn:aws:iam::$(AWS_ACCNT_ID):role/$(ROLE_NAME) \
		--handler main.lambda_handler \
		--zip-file fileb://build.zip \
		--timeout 15 \
		--memory-size 128

s3-bucket:
	aws s3api create-bucket \
		--bucket $(BUCKET_NAME) \
		--region $(REGION)

infra: role lambda s3-bucket

clean:
	rm -Rf package
	rm -f package.zip
	rm -f output.txt

delete-lambda:
	aws lambda delete-function \
		--function-name $(LAMBDA_NAME)

delete-role:
	aws iam detach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

	aws iam detach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

	aws iam delete-role \
		--role-name $(ROLE_NAME)

delete-s3-bucket:
	aws s3 rm s3://$(BUCKET_NAME) --recursive
	aws s3api delete-bucket \
		--bucket $(BUCKET_NAME) \
		--region $(REGION)

destroy: clean delete-lambda delete-role delete-s3-bucket

