import json
import unittest
import urllib
from src import main
from unittest.mock import patch, MagicMock, call


class TestLambdaHandler(unittest.TestCase):

    @patch('src.main.boto3.client')
    @patch('src.main.urllib.request.urlopen')
    @patch('src.main.os.getenv')
    @patch('src.main.logging.getLogger')
    def test_lambda_handler_success(self, mock_getLogger, mock_getenv, mock_urlopen, mock_boto3_client):
        # set up mocks
        mock_getenv.return_value = 'test-bucket'

        mock_s3 = MagicMock()
        mock_boto3_client.return_value = mock_s3

        # simulate API response
        mock_urlopen.return_value.__enter__.return_value.read.return_value = json.dumps({
            'results': [
                {'sample_data': 'value1'},
                {'sample_data': 'value2'},
            ],
            'next': None
        }).encode('utf-8')

        # define the event and context
        event = {
            'YEAR': '2021',
            'PAGE_COUNT': 1
        }
        context = MagicMock()
        context.function_name = 'test_function'

        # call the lambda handler
        result = main.lambda_handler(event, context)

        # assertions
        mock_getenv.assert_has_calls([
            call('BUCKET_NAME'),
            call('MAX_PAGE_COUNT')
        ])


        mock_boto3_client.assert_called_with('s3')
        mock_s3.put_object.assert_any_call(
            Body=json.dumps([{'sample_data': 'value1'}, {'sample_data': 'value2'}])
            .replace("}, {", "}\n{")
            .replace("[", "")
            .replace("]", ""),
            Bucket='test-bucket',
            Key='2_transformed/ccd-enrollment-prek-2021-page-001.json'
        )
        # self.assertEqual(result['statusCode'], 200)  # TOFIX
        # self.assertIn('Data successfully saved to S3', result['body'])  # TOFIX

    @patch('src.main.boto3.client')
    @patch('src.main.urllib.request.urlopen')
    @patch('src.main.os.getenv')
    @patch('src.main.logging.getLogger')
    def test_lambda_handler_http_error(self, mock_getLogger, mock_getenv, mock_urlopen, mock_boto3_client):
        # set up mocks
        mock_logger = MagicMock()
        mock_getLogger.return_value = mock_logger

        mock_getenv.return_value = 'test-bucket'

        mock_urlopen.side_effect = urllib.error.HTTPError(
            url=None, code=500, msg="Internal Server Error", hdrs=None, fp=None)

        # define the event and context
        event = {
            'YEAR': '2021',
            'PAGE_COUNT': 1
        }
        context = MagicMock()

        # call the lambda handler
        result = main.lambda_handler(event, context)

        # assertions
        self.assertEqual(result['statusCode'], 500)
        self.assertIn('HTTP error', result['body'])
        mock_logger.error.assert_called_once()
