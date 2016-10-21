
export NAME="frank"
export SPARK_PROFILE=telemetry-spark-cloudformation-TelemetrySparkInstanceProfile-1SATUBVEXG7E3
export SPARK_BUCKET=telemetry-spark-emr-2
export KEY_NAME=fbertsch-cs-dev
export DEV_TELEMETRY_PATH="s3://telemetry-test-bucket/frank/telemetry.sh"
export DEV_BATCH_PATH="s3://telemetry-test-bucket/frank/batch.sh"
export DEV_CONFIG_PATH="telemetry-test-bucket/frank/configuration.json"
export PROD_TELEMETRY_PATH="s3://${SPARK_BUCKET}/bootstrap/telemetry.sh"
export PROD_BATCH_PATH="s3://${SPARK_BUCKET}/steps/batch.sh"
export PROD_CONFIG_PATH="${SPARK_BUCKET}/configuration/configuration.json"
export DATA_BUCKET=telemetry-public-analysis-2 
export CODE_BUCKET=telemetry-analysis-code-2

function set-dev(){
    export IS_DEV=1
    export TELEMETRY_PATH="${DEV_TELEMETRY_PATH}"
    export BATCH_PATH="${DEV_BATCH_PATH}"
    export CONFIGURATION_PATH="${DEV_CONFIG_PATH}"
}

function upload-dev-sh-files(){
    aws s3 cp "/Users/frankbertsch/repos/emr-bootstrap-spark/ansible/files/telemetry.sh" "${DEV_TELEMETRY_PATH}"
    aws s3 cp "/Users/frankbertsch/repos/emr-bootstrap-spark/ansible/files/batch.sh" "${DEV_BATCH_PATH}"
    aws s3 cp "/Users/frankbertsch/repos/emr-bootstrap-spark/ansible/files/configuration.json" "s3://${DEV_CONFIG_PATH}" --acl public-read
}

function set-prod(){
    export IS_DEV=0
    export TELEMETRY_PATH="${PROD_TELEMETRY_PATH}"
    export BATCH_PATH="${PROD_BATCH_PATH}"
    export CONFIGURATION_PATH="${PROD_CONFIG_PATH}"
}

function create-cluster(){

if [[ "${IS_DEV}" == '1' ]]; then upload-dev-sh-files; fi

aws emr create-cluster \
  --region us-west-2 \
  --name frank-cluster \
  --instance-type c3.4xlarge \
  --instance-count ${1:-1} \
  --service-role EMR_DefaultRole \
  --ec2-attributes KeyName=${KEY_NAME},InstanceProfile=${SPARK_PROFILE} \
  --release-label emr-4.5.0 \
  --applications Name=Spark Name=Hive \
  --log-uri s3://${DATA_BUCKET}/frank \
  --bootstrap-actions Path=$TELEMETRY_PATH \
  --configurations "https://s3-us-west-2.amazonaws.com/$CONFIGURATION_PATH" ;} 

function run-spark-job(){

if [[ "${IS_DEV}" == '1' ]]; then upload-dev-sh-files; fi

if [[ "$2" != "" ]]; then
    if [[ "$2" != "s3://"* ]]; then
        aws s3 cp "${2}" "s3://telemetry-test-bucket/frank/"
        JOB="s3://telemetry-test-bucket/frank/${2}"
    else
        JOB="${2}"
    fi
else
    JOB="s3://${CODE_BUCKET}/jobs/foo/Telemetry Hello World.ipynb"
fi
aws emr create-cluster \
  --region us-west-2 \
  --name frank-batch-job \
  --instance-type c3.4xlarge \
  --instance-count ${1:-1} \
  --service-role EMR_DefaultRole \
  --ec2-attributes KeyName=${KEY_NAME},InstanceProfile=${SPARK_PROFILE} \
  --release-label emr-4.5.0 \
  --applications Name=Spark Name=Hive \
  --bootstrap-actions Path=$TELEMETRY_PATH,Args=\["--timeout","${3:-10}","--job-name","frank-shutdown-test","--data-bucket","${DATA_BUCKET}"\]  \
  --configurations "https://s3-us-west-2.amazonaws.com/$CONFIGURATION_PATH" \
  --log-uri s3://${DATA_BUCKET}/frank \
  --steps Type=CUSTOM_JAR,Name=CustomJAR,ActionOnFailure=TERMINATE_JOB_FLOW,Jar=s3://us-west-2.elasticmapreduce/libs/script-runner/script-runner.jar,Args=\["${BATCH_PATH}","--job-name","${4:-${NAME}}","--notebook","${JOB}","--data-bucket","${DATA_BUCKET}"\] ;}
