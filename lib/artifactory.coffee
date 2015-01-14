s3ArtifactCollection = require './s3/s3artifactcollection.js'
s3Artifactory = require './s3/s3artifactory.js'
fsArtifactCollection = require './filesystem/fsartifactcollection.js'
fsArtifactory = require './filesystem/fsartifactory.js'
fs = require 'fs'
aws = require 'aws-sdk'

module.exports = (region, bucket, id) ->
	if process.env.ARTIFACTORY_PATH? and fs.existsSync(process.env.ARTIFACTORY_PATH)
		collection = new fsArtifactCollection process.env.ARTIFACTORY_PATH, fs
		return new fsArtifactory collection, fs, region, bucket, id
	else
		collection = new s3ArtifactCollection aws, region, bucket, id
		return new s3Artifactory collection, aws, fs, region, bucket, id