import boto3
import json
import logging
import os
import urllib.request
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    # get vars from the environment
    year = event.get('YEAR', None)  # TODO: calculate using system time if not provided
    bucket_name = os.getenv('BUCKET_NAME', None)
    count = event.get('count', 0)  # page count; also to prevent from infinite recursive call
    api_url = event.get('API_URL', None)  # if the URL is in the env, this is a recursive call

    if api_url is None:  # i.e., initial call
        api_url = f"https://educationdata.urban.org/api/v1/schools/ccd/enrollment/{year}/grade-pk/"
    file_name = f"ccd-enrollment-prek-{year}-page-{count}.json"

    # log everything for debugging
    logger.info(f"""Variables:
                     - year: {year}
                     - bucket_name: {bucket_name}
                     - Page count: {count}
                     - api_url: {api_url}
                     - file_name: {file_name}
    """)

    # fetch data from the API
    try:
        with urllib.request.urlopen(api_url) as response:
            data_str = response.read().decode()

            # save raw/extracted JSON data to S3
            s3_key = f"1_extracted/{file_name}"  # file name/path in S3
            s3 = boto3.client('s3')
            s3.put_object(Body=data_str, Bucket=bucket_name, Key=s3_key)
            logger.info(f"Success: 'Extracted data successfully saved to S3'")

            # convert data from string to dict
            data_dict = json.loads(data_str)

            # transform: Athena likes one JSON object per line without [, ]
            # TODO: put this in a separate lambda function to isolate processes
            results = data_dict["results"]
            data_str = json.dumps(results) \
                .replace("}, {", "}\n{") \
                .replace("[", "") \
                .replace("]", "")

            # save transformed JSON data to S3
            s3_key = f"2_transformed/{file_name}"  # file name/path in S3
            s3.put_object(Body=data_str, Bucket=bucket_name, Key=s3_key)
            logger.info(f"Success: 'Transformed data successfully saved to S3'")

            # get "next" page's URL
            next_url = data_dict.get("next")

            # recursively call self to bring "next" pages
            if count <= 10 and next_url and next_url != api_url:
                new_payload = {
                    "count": count + 1,
                    "API_URL": next_url,
                    "YEAR": year,
                }

                logger.info(f"Invoking self to bring the next page: {next_url}")
                # asynchronous invocation to allow the calling func to exit without waiting
                boto3.client('lambda').invoke(
                    FunctionName=context.function_name,
                    InvocationType='Event',  # asynchronous
                    Payload=json.dumps(new_payload)
                )

            return {
                'statusCode': 200,
                'body': json.dumps({'message': "Data successfully saved to S3"})
            }

    except urllib.error.HTTPError as e:
        error = f'HTTP error: {e.code} {e.reason}'
    except urllib.error.URLError as e:
        error = f'URL error: {e.reason}'
    except NoCredentialsError:
        error = 'AWS credentials not available'
    except PartialCredentialsError:
        error = 'AWS credentials incomplete'
    except Exception as e:
        error = f'An unexpected error occurred: {str(e)}'

    logger.error(f"error: {error}")

    return {
        'statusCode': 500,
        'body': json.dumps({'error': error})
    }
