import json
import os
import boto3

s3 = boto3.client('s3')


def lambda_handler(event, context):
    # Specify the S3 bucket name and the object key (file name)
    bucket_name = "mehmet-bezos-challenge"  # os.environ['mehmet-bezos-challenge']  # You can also hard-code this if you prefer
    file_name = 'example.txt'
    file_content = 'Hello, World!'

    try:
        # Upload the file to S3
        response = s3.put_object(
            Bucket=bucket_name,
            Key=file_name,
            Body=file_content
        )
        return {
            'statusCode': 200,
            'body': json.dumps('File successfully uploaded to S3!')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
