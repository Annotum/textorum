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
  TextorumTree = require('./tree')
  elementHelper = require('./element')
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

  _nsurlAttributeFilterGenerator = (editor) ->
    _nsurlAttributeFilter = (nodes, name, params) ->
      i = nodes.length

      while (i--)
        node = nodes[i]
        # Some browsers don't record the (fixed) xml prefix for the namespace during xsl transforms
        if node.attributes.map['data-textorum-nsurl'] == "http://www.w3.org/XML/1998/namespace"
          node.attributes.map['data-textorum-nsprefix'] = "xml"
        editor.plugins.textorum.nsmap[node.attributes.map['data-textorum-nsurl']] = node.attributes.map['data-textorum-nsprefix']
        node.remove()

  tinymce.create 'tinymce.plugins.textorum.loader', {
    elementMap: {
      inlineelements: "bold,italic,monospace,underline,sub,sup,named-content,ext-link,inline-graphic,inline-formula".split(',')
      fixedelements: "table,thead,tbody,td,tr,th".split(',')
    }
    updateTree: () ->
      @tree.updateTreeCallback()
    schema: {}
    nsmap: {}


    init: (@editor, url) ->
      that = this
      if tinymce.adapter
        tinymce.adapter.patchEditor(editor)
      @schema = _getSchema("test/rng/kipling-jp3-xsl.srng")
      @tree = new TextorumTree '#editortree', editor
      testload.bindHandler editor
      editor.onSetContent.add (ed, o) ->
        that.tree.updateTreeCallback()
      editor.onKeyUp.add (editor, evt) ->
        if that.removePlaceholderTag
          editor.$('[class="textorum_placeholder"]').remove();
        if evt.which > 36 and evt.which < 41
          return
        if editor.currentNode
          schema = editor.plugins.textorum.schema.defs
          schemaElement = schema[editor.currentNode.getAttribute('data-xmlel')]
          if not schemaElement or not schemaElement.$
            console.log "no text allowed in", editor.currentNode.getAttribute('data-xmlel')
            $(editor.currentNode).contents().filter(->
              return this.nodeType == 3
            ).remove()
      editor.onChange.add (editor, evt) ->
        if editor.isDirty()
          that.tree.updateTreeCallback()

      editor.onNodeChange.add (editor, controlManager, element, collapsed, extra) ->
        editor.currentNode = element
        that.tree.navigateTreeCallback(element, collapsed, extra)

      editor.onPreInit.add (editor) ->
        editor.parser.addAttributeFilter 'data-textorum-nsurl', _nsurlAttributeFilterGenerator(editor)
        editor.serializer.addAttributeFilter 'id', that.tree.attributeFilterCallback
      editor.onInit.add (editor) ->

      if editor.theme.onResolveName
        editor.theme.onResolveName.add (theme, path_object) ->
          if path_object.node.getAttribute?('data-xmlel')
            path_object.name = path_object.node.getAttribute('data-xmlel');
      elementHelper.init editor

    getInfo: ->
      {
        longname : 'Textorum',
        author : 'NCBI / Crowd Favorite',
        authorurl : 'https://github.com/Annotum/',
        infourl : 'https://github.com/Annotum/textorum/',
        version : "0.1"
      }
    translateElement: (elementName) ->
      if elementName in @elementMap.fixedelements
        elementName
      else if elementName in @elementMap.inlineelements
        "span"
      else
        "div"


  }
  tinymce.PluginManager.add('textorum', tinymce.plugins.textorum.loader)
