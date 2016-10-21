PSA: This is just ready for use by Frank at the moment. Please check back for updates to make it more generally available.

#Moz AWS Cli
This library is a few simple CLI functions to make life easy developing for our EMR infrastructure.

## Available Functions

create-cluster N: creates a cluster of size N, which defaults to 1

run-spark-job N job timeout name: runs a spark job (as our scheduled jobs do). N defaults to 1, job defaults to the telemetry-hello-world, timeout defaults to 10, and job name defaults to frank
