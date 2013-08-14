'use strict';
module.exports = function (grunt) {
  var path = require('path');
  var combine_js_files = {
    '<%= distdir %>/editor_plugin.js': [
      'vendor/jquery.scrollintoview.js',
      'vendor/jstree/jquery.jstree.js',
      '<%= requirejs.compile.options.out %>'
    ]
  }
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    'license_header': grunt.file.read('vendor/license_header.txt'),
    distdir: 'dist/textorum',
    
    uglify: {
        options: {
          banner: '/*\n<%= license_header %>\n\n<%= pkg.name %> | <%= pkg.version %> | <%= grunt.template.today("yyyy-mm-dd") %>\n*/\n'
        },
        js: {
          files: combine_js_files
        }
      },

      concat: {
        options: {
          banner: '/*\n<%= license_header %>\n\n<%= pkg.name %> | <%= pkg.version %> | <%= grunt.template.today("yyyy-mm-dd") %>\n*/\n'
        },
        js: {
          files: combine_js_files
        }
    },
 
    coffee: {
      compile: {
        expand: true,
        cwd: 'src/',
        src: ['**/*.coffee'],
        dest: 'lib/',
        ext: '.js'
      }
    },
    
    requirejs: {
        compile: {
            options: {
              almond: true,
              name: 'vendor/almond',
              baseUrl: 'lib',
              paths: {
                'vendor/almond': '../vendor/almond',
                'text': '../vendor/text',
                'sax': '../vendor/sax',
                'jqueryui-popups': '../vendor/tinymce.jqueryui.popups',
                'tinymce-jquery': '../vendor/tinymce_jquery/jquery.tinymce',
                'tinymce-jquery-adapter': '../vendor/tinymce_jquery/adapter',
                'jquery': 'fake/jquery',
                'stream': 'fake/stream'
              },
              optimize: 'none',
              inlineText: true,
              include: [
                'jquery',
                'textorum/tinymce/plugin',
                'jqueryui-popups',
                'tinymce-jquery',
                'tinymce-jquery-adapter'
              ],
              insertRequire: ['textorum/tinymce/plugin'],
              wrap: {
                startFile: 'vendor/start.frag',
                endFile: 'vendor/end.frag'
              },
              fileExclusionRegExp: /^\.|node_modules|Gruntfile|\.md|package.json/,
              out: '.tmp/textorum-rjs.js'
            }
        }
    },

    sass: {
        dist: {
            options: {
                style: 'compressed'
            },
            expand: true,
            cwd: 'src/',
            src: ['**/*.scss', '!**/_*.scss'],
            dest: 'lib/',
            ext: '.css'
        },
        dev: {
            options: {
                style: 'expanded',
                debugInfo: true,
                lineNumbers: true
            },
            expand: true,
            cwd: 'src/',
            src: ['**/*.scss'],
            dest: 'lib/',
            ext: '.css',
            filter: function(fn) {
              return path.basename(fn)[0] !== '_';
            }
            
        }
    },
    
    sync: {
      dist: {
        files: [
          {
            cwd: 'fonts/',
            src: ['**/*'],
            dest: '<%= distdir %>/fonts/'
          },
          {
            cwd: 'img/',
            src: ['**/*.{png,jpg,jpeg,gif,bmp,ico}'],
            dest: '<%= distdir %>/img/'
          },
          {
            cwd: 'lib/',
            src: ['**/*.css'],
            dest: '<%= distdir %>/css/'
          },
          {
            cwd: 'schema/',
            src: ['**/*.{rng,srng}'],
            dest: '<%= distdir %>/schema/'
          },
          {
            cwd: 'xsl/',
            src: ['**/*.xsl'],
            dest: '<%= distdir %>/xsl/'
          }
        ]
      }
    },

    // Run: `grunt watch` from command line for this section to take effect
    watch: {
      coffee: {
        files: ['<%= coffee.compile.src %>'],
        tasks: ['coffee:compile', 'requirejs:compile', 'concat:js', 'sync']
      },
      sass: {
        files: ['<%= sass.dev.src %>'],
        tasks: ['sass:dev', 'sync']
      }
    }

  });

  // Load NPM Tasks
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-requirejs');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-sync');

  grunt.registerTask('default', ['coffee:compile', 'sass:dev', 'requirejs:compile', 'concat:js', 'sync']);
  grunt.registerTask('dist', ['coffee:compile', 'sass:dist', 'requirejs:compile', 'uglify:js', 'sync']);

};
