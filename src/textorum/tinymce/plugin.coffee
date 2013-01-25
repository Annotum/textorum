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
  helper = require('../helper')
  tree = require('./tree')
  #pathHelper = require('./pathhelper')

  tinymce = require('tinymce')

  window.textorum ||= {}
  originalDTD = {}

  schema = {
    containedBy: {},
    defs: {}
  }


  $ = window.jQuery

  schemaprocessor = new XSLTProcessor()
  schemaStylesheet = helper.getXML "xsl/rng2js.xsl"
  schemaprocessor.importStylesheet(schemaStylesheet)
  schema = helper.getXML "test/rng/kipling-jp3-xsl.srng"
  xsltschema = schemaprocessor.transformToDocument(schema)
  schema = ($.parseJSON || tinymce.util.JSON.parse)(xsltschema.documentElement.innerText)
  schema.containedBy ||= {}
  schema.defs ||= {}
  schema.$root ||= []
  for element, details of schema.defs
    elementContains = {}
    for own containedElement, v of details.contains
      schema.containedBy[containedElement] ||= {}
      schema.containedBy[containedElement][element] = 1
  window.textorum.schema = schema

  tinymce.create 'tinymce.plugins.textorum.loader', {
    init: (editor, url) =>
      console.log "editor", editor
      console.log "url", url
      tree.create '#editortree', editor
      testload.bindHandler editor
      editor.onSetContent.add (ed, o) ->
        tree.update '#editortree', ed
      editor.onNodeChange.add tree.navigate

    getInfo : ->
      {
        longname : 'Textorum',
        author : 'NCBI / Crowd Favorite',
        authorurl : 'https://github.com/Annotum/',
        infourl : 'https://github.com/Annotum/textorum/',
        version : "0.1"
      }
  }
  tinymce.PluginManager.add('textorum.loader', tinymce.plugins.textorum.loader)
