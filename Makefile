include .env
export $(shell sed 's/=.*//' .env)

.PHONY: build

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

data-2020:
	rm -f output-2020.txt
	aws lambda invoke \
		--function-name $(LAMBDA_NAME) \
		--cli-binary-format raw-in-base64-out \
		--payload '{"YEAR": "2020"}' \
		output-2020.txt

data-2021:
	rm -f output-2021.txt
	aws lambda invoke \
		--function-name $(LAMBDA_NAME) \
		--cli-binary-format raw-in-base64-out \
		--payload '{"YEAR": "2021"}' \
		output-2021.txt

data-2022:
	rm -f output-2022.txt
	aws lambda invoke \
		--function-name $(LAMBDA_NAME) \
		--cli-binary-format raw-in-base64-out \
		--payload '{"YEAR": "2022"}' \
		output-2022.txt

data: data-2020 data-2021 data-2022

see-files:
	aws s3 ls s3://$(BUCKET_NAME)/ --recursive

download-files:
	aws s3 cp s3://$(BUCKET_NAME)/ . --recursive

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

	aws iam attach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaRole

lambda:
	aws lambda create-function \
		--function-name $(LAMBDA_NAME) \
		--runtime $(PYTHON_VER) \
		--role arn:aws:iam::$(AWS_ACCNT_ID):role/$(ROLE_NAME) \
		--handler main.lambda_handler \
		--zip-file fileb://build.zip \
		--timeout 60 \
		--memory-size 128 \
		--environment "Variables={BUCKET_NAME=$(BUCKET_NAME)}"

s3-bucket:
	aws s3api create-bucket \
		--bucket $(BUCKET_NAME) \
		--region $(REGION)

athena-database:
	aws athena start-query-execution \
		--query-string "CREATE DATABASE $(ATHENA_DB);" \
		--result-configuration "OutputLocation=s3://$(BUCKET_NAME)/result/"

athena-table:
	aws athena start-query-execution \
		--query-string "CREATE EXTERNAL TABLE IF NOT EXISTS $(ATHENA_DB).ccd_enrollment_grade_pk ( \
			year INT, \
			ncessch STRING, \
			ncessch_num BIGINT, \
			grade INT, \
			race INT, \
			sex INT, \
			enrollment INT, \
			fips INT, \
			leaid STRING \
		) ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe' \
		WITH SERDEPROPERTIES ( \
			'serialization.format' = '1' \
		) LOCATION 's3://$(BUCKET_NAME)/2_transformed/' \
		TBLPROPERTIES ('has_encrypted_data'='false');" \
		--result-configuration "OutputLocation=s3://$(BUCKET_NAME)/result/"

query-enrollment:
	aws athena start-query-execution \
		--query-string " \
				SELECT fips,  \
					   SUM(enrollment) as total_enrollment  \
				FROM $(ATHENA_DB).ccd_enrollment_grade_pk  \
				WHERE year=2021 AND grade=-1  \
				GROUP BY fips  \
				ORDER BY total_enrollment DESC \
				LIMIT 10;" \
		--result-configuration "OutputLocation=s3://$(BUCKET_NAME)/result/enrollment/"
	aws s3 cp s3://$(BUCKET_NAME)/result/enrollment/ . --recursive

query-counts:
	aws athena start-query-execution \
		--query-string " \
				SELECT count(*) as record_count,  \
					   year  \
				FROM $(ATHENA_DB).ccd_enrollment_grade_pk  \
				GROUP BY year  \
				ORDER BY year DESC \
				;" \
		--result-configuration "OutputLocation=s3://$(BUCKET_NAME)/result/count/"
	aws s3 cp s3://$(BUCKET_NAME)/result/count/ . --recursive

infra: role lambda s3-bucket athena-database athena-table

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

delete-files:
	aws s3 rm s3://$(BUCKET_NAME)/ --recursive

delete-s3-bucket: delete-files
	aws s3api delete-bucket \
		--bucket $(BUCKET_NAME) \
		--region $(REGION)

delete-athena-database:
	aws athena start-query-execution \
		--query-string "DROP DATABASE $(ATHENA_DB);" \
		--result-configuration "OutputLocation=s3://$(BUCKET_NAME)/result/"

delete-athena-table:
	aws athena start-query-execution \
		--query-string "DROP TABLE $(ATHENA_DB).ccd_enrollment_grade_pk;" \
		--result-configuration "OutputLocation=s3://$(BUCKET_NAME)/result/"

destroy: clean delete-lambda delete-role delete-athena-table delete-athena-database delete-s3-bucket

