# plugin.coffee - Textorum TinyMCE plugin, main body
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
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

  tinymce = window.tinymce

  window.textorum ||= {}
  originalDTD = {}

  window.textorum.schema ||= {
    containedBy: {},
    defs: {}
  }


  $ = window.jQuery

  _getSchema = (schemaUri) ->
    if not schemaUri
      return ""
    schemaprocessor = new XSLTProcessor()
    schemaStylesheet = helper.getXML "xsl/rng2js.xsl"
    schemaprocessor.importStylesheet(schemaStylesheet)
    xmlschema = helper.getXML(schemaUri)
    xsltschema = schemaprocessor.transformToDocument(xmlschema)
    schemadoc = xsltschema.documentElement
    schematext = (schemadoc.text || schemadoc.textContent || schemadoc.innerHTML)
    schema = ($.parseJSON || tinymce.util.JSON.parse)(schematext)
    schema ||= {}
    schema.containedBy ||= {}
    schema.defs ||= {}
    schema.$root ||= []
    for element, details of schema.defs
      elementContains = {}
      for own containedElement, v of details.contains
        schema.containedBy[containedElement] ||= {}
        schema.containedBy[containedElement][element] = 1
    schema

  _treeAttributeFilter = (nodes, name) ->
    i = nodes.length;
    snip = tree.id_prefix.length
    while (i--)
      if nodes[i].attr('id').substr(0, snip) is tree.id_prefix
        nodes[i].attr(name, null)

  tinymce.create 'tinymce.plugins.textorum.loader', {
    init: (editor, url) ->
      @schema = _getSchema("test/rng/kipling-jp3-xsl.srng")
      tree.create '#editortree', editor
      testload.bindHandler editor
      editor.onSetContent.add (ed, o) ->
        tree.update '#editortree', ed
      editor.onNodeChange.add tree.navigate
      editor.onInit.add (editor) ->
        editor.serializer.addAttributeFilter 'id', _treeAttributeFilter
        
      if editor.theme.onResolveName
        editor.theme.onResolveName.add (theme, path_object) ->
          if path_object.node.getAttribute?('data-xmlel')
            path_object.name = path_object.node.getAttribute('data-xmlel');

    getInfo : ->
      {
        longname : 'Textorum',
        author : 'NCBI / Crowd Favorite',
        authorurl : 'https://github.com/Annotum/',
        infourl : 'https://github.com/Annotum/textorum/',
        version : "0.1"
      }
  }
  tinymce.PluginManager.add('textorum', tinymce.plugins.textorum.loader)
