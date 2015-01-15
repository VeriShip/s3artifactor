s3artifactor
============
![TravisCI](https://travis-ci.org/NiteoSoftware/s3artifactor.svg?branch=master)
![Build status](https://ci.appveyor.com/api/projects/status/78ubm4xukw4tc0sy?svg=true)

Most developers don't worry about what they're code produces or where it is stored.  We could rely on the build server to keep the artifacts until we need them, but what if we need to rebuild the build server? We created this tool to solve this problem.  

S3Artifactor is a command line [nodejs](http://nodejs.org/) tool that utilizes [AWS S3](http://aws.amazon.com/s3/) to store and version our proprietary artifacts.

Install
-------

```
npm install -g s3artifactor
```

Usage
-----

```
Usage: s3artifactor [options]

  Options:

    -h, --help                output usage information
    -V, --version             output the version number
    -a, --action [value]      The action the artifactor is going to take.  Valid options are [list, push, get, delete]
    -b, --bucket [value]      The bucket the artifactor will search for the artifact in.
    -r, --region [value]      The region the bucket is available in.
    -i, --id [value]          The id of the artifact to retreive.
    -d, --destPath [value]    The destination path for a file in a get operation.
    -s, --sourcePath [value]  The source path for a file in a push operation.
    -v, --versionid [value]   The version of the artifact in a get, push, or delete operation.
    -p, --public              Makes the artifact public in a push operation.
    -e, --encrypt             Makes the artifact encrypted in a push operation.
    -o, --overwrite           Overwrites the version in a push operation.
```

*List Available Versions of a particular artifact*

```
s3artifactor --action list --region us-east-1 --bucket somebucket --id someartifact
```

*Push an artifact to the artifactory*

```
s3artifactor --action push --region us-east-1 --bucket somebucket --id someartifact --version 0.0.1 --sourcePath /someartifact.tar.gz
```

By default the s3artifactor makes the new artifact version private.  However, you can supply the `--public` flag to make it public within S3. You can also tell the s3artifactor to encrypt your artifact within S3 with the `--encrypt` flag.  If you try to push up a version that already exists in the artifactory, then the s3artifactor will fail.  You can supply the `--overwrite` flag to allow the s3artifactor to overwrite a previous version.

*Get an artifact from the artifactory*

```
s3artifactor --action get --region us-east-1 --bucket somebucket --id someartifact --version 0.0.1 --destPath /artifactlocation.tar.gz
```

*Delete an artifact version from the artifactory*

```
s3artifactor --action delete --region us-east-1 --bucket somebucket --id someartifact --version 0.0.1
```