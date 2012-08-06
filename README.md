s3utils
=======

Ruby s3 utils that use AWS SDK to work easily with IAM roles.

install with gem install s3utils

AWS configuration is taken from one of the following places in the order
given:
1. If Environment Variable AWS_CREDENTIAL_FILE is set, it will look in
   the file. The file should have at least two lines: 
      AWSAccessKeyId= 
      AWSSecretKey=
2. Environment Variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
3. If you are running this in an EC2 instance with IAM role, this will
   automatically pick up the configuration



If you are behind a proxy, set the environment variable:
HTTPS_PROXY_='https://user:password@my.proxy:443/'

After installation, following commands will work:

s3cmd  listbuckets
s3cmd  createbucket|deletebucket  <bucket>  
s3cmd  list  <bucket>[:prefix]  [max/page]  [delimiter]  
s3cmd  delete  <bucket>:key  
s3cmd  deleteall  <bucket>[:prefix]
s3cmd  get|put  <bucket>:key  <file>  


