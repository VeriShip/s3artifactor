module.exports = (grunt) =>

	grunt.initConfig
		createDirectories:
			dir: ['bin']
		cleanUpDirectories:
			dir: ['bin']
		copy:
			main:
				files: [
					expand: true, 
					src: ['lib/**/*.js'], 
					dest: 'bin/', 
					filter: 'isFile'
				]
		coffee:
			compile:
				expand: true,
				flatten: false,
				dest: 'bin',
				src: ['**/*.coffee', '!**/gruntfile*'],
				ext: '.js',
				cwd: '.'
		mochaTest:
			test:
				options:
					reporter: 'spec'
				src: ['bin/lib/tests/**/*.js']

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-mocha-test');
	grunt.loadNpmTasks('grunt-contrib-copy');

	grunt.registerTask('default', [ 'build' ]);
	grunt.registerTask('build', [ 'createDirectories', 'copy:main', 'coffee:compile', 'mochaTest:test' ]);
	grunt.registerTask('clean', [ 'cleanUpDirectories' ]);
	grunt.registerTask('rebuild', [ 'clean', 'build' ]);

	grunt.registerMultiTask 'createDirectories', ->
		for dir in this.data
			if not grunt.file.exists dir
				grunt.file.mkdir dir

	grunt.registerMultiTask 'cleanUpDirectories', ->
		for dir in this.data
			if grunt.file.exists dir
				grunt.file.recurse dir, (abspath) ->
					grunt.file.delete abspath
				grunt.file.delete dir, { force: true }