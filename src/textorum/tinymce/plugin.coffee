# plugin.coffee - Textorum TinyMCE plugin, main body
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Licensed under the MIT license:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

define (require) ->
  pluginCss = require('text!../../plugin.css')
  textorumloader = require('./loader')
  helper = require('../helper')
  {TextorumTree} = require('./tree')
  {TextorumValidator} = require('./validator')
  #pathHelper = require('./pathhelper')

  tinymce = window.tinymce

  window.textorum ||= {}
  originalDTD = {}

  window.textorum.schema ||= {
    containedBy: {},
    defs: {}
  }


  $ = window.jQuery

  _getSchema = (schemaUri, baseUri = "") ->
    if not schemaUri
      return ""
    schemaprocessor = new XSLTProcessor()
    schemaStylesheet = helper.getXML baseUri + "xsl/rng2js.xsl"
    schemaprocessor.importStylesheet(schemaStylesheet)
    xmlschemaresp = helper.getXHR baseUri + schemaUri, 'text/xml'
    xmlschema = xmlschemaresp.responseXML
    xsltschema = schemaprocessor.transformToDocument(xmlschema)
    schemadoc = xsltschema.documentElement
    schematext = (schemadoc.text || schemadoc.textContent || schemadoc.innerHTML)
    schema = ($.parseJSON || tinymce.util.JSON.parse)(schematext)
    schema ||= {}
    schema.schemaURI = schemaUri
    schema.schemaXML = xmlschemaresp.responseText
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

  elementMap = {
      inlineelements: "bold italic monospace underline sub     
        sup named-content ext-link inline-graphic alt-text lbl long-desc
        copyright-statement copyright-holder license license-p disp-quote
        attrib inline-formula xref".split(/\s+/)
      fixedelements: "textorum table thead tbody td tr th".split(/\s+/)
    }

  tinymce.create 'tinymce.plugins.textorum', {
    elementMap: elementMap
    updateTree: () ->
      @tree.updateTreeCallback()
    schema: {}
    nsmap: {}


    init: (@editor, url) ->
      that = this
      that.url = url
      if tinymce.adapter
        tinymce.adapter.patchEditor(editor)
      @schema = _getSchema("schema/kipling-jp3.srng", helper.trailingslashit(url))
      @tree = new TextorumTree '#editortree', editor
      @validator = new TextorumValidator '#editorvalidation', editor
      @helper = helper

      textorumloader.bindHandler editor, url, @elementMap.inlineelements.join(','), @elementMap.fixedelements.join(',')
      editor.onSetContent.add (ed, o) ->
        that.tree.updateTreeCallback()
      editor.onKeyUp.add (editor, evt) ->
        if that.removePlaceholderTag
          that.removePlaceholderTag = false
          editor.$('[data-mce-bogus="1"]').each (idx, element) ->
            element = $(element)
            contents = element.contents()
            element.replaceWith(contents)

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
        that.removePlaceholderTag = true
        root = editor.dom.getRoot()
        while not element.hasAttribute('data-xmlel') and element isnt root and element.parentElement
          element = element.parentElement

        editor.currentNode = element
        that.tree.navigateTreeCallback(element, collapsed, extra)
        schema = editor.plugins.textorum.schema.defs
        schemaElement = schema[editor.currentNode.getAttribute('data-xmlel')]
        for button in ['bold', 'italic', 'underline', 'sub', 'sup']
          controlManager.setDisabled(button, !(schemaElement?.contains?[button]?))

      editor.onPreInit.add (editor) ->
        editor.parser.addAttributeFilter 'data-textorum-nsurl', _nsurlAttributeFilterGenerator(editor)
        editor.serializer.addAttributeFilter 'id', that.tree.attributeFilterCallback
      editor.onInit.add (editor) ->

      if editor.theme.onResolveName
        editor.theme.onResolveName.add (theme, path_object) ->
          if path_object.node.getAttribute?('data-xmlel')
            path_object.name = path_object.node.getAttribute('data-xmlel');

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
  tinymce.PluginManager.add('textorum', tinymce.plugins.textorum)
