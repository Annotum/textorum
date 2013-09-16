# validator.coffee - Textorum TinyMCE plugin, validation toolkit
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
  helper = require('../helper')
  {RNGParser} = require('../relaxng/parse')
  objects = require('../relaxng/objects')
  $ = require('jquery')

  class TextorumValidator
    constructor: (@validationOutputSelector, @editor, alternateStart) ->
      schema = @editor.plugins.textorum.schema
      if schema.schemaXML
        @schema = schema.schemaXML
      else
        schemaUri = schema.schemaURI
        @schema = helper.getXHR(schemaUri).responseText
      @validatorNoAttributes = new RNGParser()
      @validatorNoAttributes.process(@schema, true)
      @validatorAttributes = new RNGParser()
      @validatorAttributes.process(@schema, false)

      @validationAttributesStart = @validatorAttributes.start
      @validationNoAttributesStart = @validatorNoAttributes.start
      if alternateStart
        if @validatorAttributes.defines[alternateStart]
          @validationAttributesStart = validatorAttributes.defines[alternateStart]
        if @validatorNoAttributes.defines[alternateStart]
          @validationNoAttributesStart = validatorNoAttributes.defines[alternateStart]

      @editor.addCommand 'validateWithAttributes', @validateWithAttributes, this
      @editor.addCommand 'validateWithoutAttributes', @validateWithoutAttributes, this
      @editor.addButton 'txt_validate_attrs', {cmd: 'validateWithAttributes', title: 'Full Validation'}
      @editor.addButton 'txt_validate_noattrs', {cmd: 'validateWithoutAttributes', title: 'Validation (Ignoring Attributes)'}

    validatePartialOpportunistic: (node, skipAttributes = false, descend = false) ->
      if skipAttributes
        validator = @validatorNoAttributes
      else
        validator = @validatorAttributes
      res = @validatePartialOpportunisticResult(node, skipAttributes, descend)
      if res instanceof validator.getObjects().NotAllowed
        return false
      return true

    validatePartialOpportunisticResult: (node, skipAttributes = false, descend = false) ->
      if skipAttributes
        validator = @validatorNoAttributes
      else
        validator = @validatorAttributes
      na = validator.getObjects().NotAllowed
      validator.getObjects().setSkipAttributes skipAttributes
      # validator.debug = true
      # validator.getObjects().setDebug true

      possiblePatterns = []
      for name, define of validator.defines
        res = define.startTagOpenDeriv(node)
        unless res instanceof na
          possiblePatterns.push define
      index = possiblePatterns.length
      if not index
        return na
      res = na
      while index--
        res = possiblePatterns[index].childDeriv(node, descend)
        unless res instanceof na
          return res
      return res

    validateFullEditor: (skipAttributes = false, opportunistic = false) ->
      docdom = (new window.DOMParser()).parseFromString(@editor.getContent(), "text/xml")

      if skipAttributes
        if opportunistic
          res = @validatePartialOpportunisticResult docdom.documentElement, true
        else
          @validatorNoAttributes.getObjects().setSkipAttributes true
          res = @validationNoAttributesStart.childDeriv(docdom.documentElement, true)
      else
        if opportunistic
          res = @validatePartialOpportunisticResult docdom.documentElement, false
        else
          @validatorAttributes.getObjects().setSkipAttributes false
          res = @validationAttributesStart.childDeriv(docdom.documentElement, true)
      if res instanceof objects.Empty
        $(@validationOutputSelector).html('<b>No errors detected</b>')
      else
        path = helper.pathForNode(res.childNode)
        target = helper.followTextorumPath(path, @editor.dom.getRoot())
        if target isnt @editor.dom.getRoot()
          @editor.getWin().scrollTo(0, @editor.dom.getPos(target).y - 10);
          @editor.selection.setCursorLocation(target, 0)
          @editor.nodeChanged()
          $(target).effect("highlight", {}, 500)
          @editor.focus()
        $(@validationOutputSelector).html("<ul><li><i>Error:</i> #{res}</li></ul>")
      return res

    validateWithoutAttributes: ->
      @validateFullEditor(true)

    validateWithAttributes: ->
      @validateFullEditor(false)
    
    validElementsForNode: (target, location = "inside", returnType = "array") =>
      validator = @editor.plugins.textorum.validator
      dom = @editor.dom
      checkElements =  @editor.plugins.textorum.schema.defs?[dom.getAttrib(target, 'data-xmlel')]?.contains
      validKeys = []
      validElements = {}
      parent = target.parentNode
      
      for key, details of checkElements
        editorNode = dom.create(@editor.plugins.textorum.translateElement(key), {
          'data-xmlel': key, 
          class: key
        })
        switch location
          when "before"
            parent.insertBefore(editorNode, target)
            res = @validatePartialOpportunistic(parent, true, 1)
          when "after"
            dom.insertAfter(editorNode, target)
            res = @validatePartialOpportunistic(parent, true, 1)
          when "inside"
            target.appendChild(editorNode)
            res = @validatePartialOpportunistic(target, true, 1)
        dom.remove(editorNode)
        if res
          validKeys.push(key)
          validElements[key] = details
      if returnType is "array"
        return validKeys
      else
        return validElements



  return {
    TextorumValidator: TextorumValidator
  }

