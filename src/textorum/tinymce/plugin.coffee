# plugin.coffee - Textorum CKEditor plugin, main body
#
# Copyright (C) 2012 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Textorum is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# Textorum is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

define (require) ->
  pluginCss = require('text!./plugin.css')
  testload = require('./testload')
  #pathHelper = require('./pathhelper')

  tinymce = window.tinymce

  originalDTD = {}

  schema = {
    containedBy: {},
    defs: {}
  }

  jQuery.getJSON "test/rng/kipling-jp3.json", (data) ->
    schema = data
    schema.containedBy ||= {}
    schema.defs ||= {}

  console.log "let's go"
  tinymce.create 'tinymce.plugins.textorum.loader', {
    init: (editor, url) =>
      console.log "editor", editor
      console.log "url", url

      testload.bindHandler editor


    getInfo : ->
      {
        longname : 'Example plugin',
        author : 'Some author',
        authorurl : 'http://tinymce.moxiecode.com',
        infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/example',
        version : "1.0"
      }
  }
  tinymce.PluginManager.add('textorum.loader', tinymce.plugins.textorum.loader)
