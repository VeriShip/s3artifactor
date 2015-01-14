module.exports = 
	run: () ->
		program = require 'commander'

		program
			.version('0.0.1')
			.option('-a, --action [value]', 'The action the artifactor is going to take.  Valid options are [list, push, get, delete]')
			.option('-b, --bucket [value]', 'The bucket the artifactor will search for the artifact in.')
			.option('-r, --region [value]', 'The region the bucket is available in.')
			.option('-i, --id [value]', 'The id of the artifact to retreive.')
			.option('-d, --destPath [value]', 'The destination path for a file in a get operation.')
			.option('-s, --sourcePath [value]', 'The source path for a file in a push operation.')
			.option('-v, --versionid [value]', 'The version of the artifact in a get, push, or delete operation.')
			.option('-p, --public', 'Makes the artifact public in a push operation.')
			.option('-e, --encrypt', 'Makes the artifact encrypted in a push operation.')
			.option('-o, --overwrite', 'Overwrites the version in a push operation.')
			.parse(process.argv);

		artifactory = require('./artifactory.js')(program.region, program.bucket, program.id)
		promise = null

		switch program.action
			when "list" then promise = artifactory.getArtifacts()
			when "push" then promise = artifactory.pushArtifact(program.sourcePath, program.versionid, program.public, program.encrypt)
			when "get" then promise = artifactory.getArtifact(program.destPath, program.versionid)
			when "delete" then promise = artifactory.deleteArtifact(program.version)
			else promise = Q.reject "Unknown verb: #{program.verb}"

		success = (data) ->
			console.log data
			process.exit 0
		fail = (err) ->
			console.error "Error #{err}"
			process.exit 1
		progress = (prog) ->
			console.log prog

		promise.done success, fail, progress