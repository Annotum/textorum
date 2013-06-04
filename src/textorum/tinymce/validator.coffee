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

  class TextorumValidator
    constructor: (@validationOutputSelector, @editor) ->
      schema = @editor.plugins.textorum.schema
      schemaUri = schema.schemaURI
      @schema = helper.getXHR(schemaUri).responseText
      @validatorNoAttributes = new RNGParser()
      @validatorNoAttributes.process(@schema, true)
      @validatorAttributes = new RNGParser()
      @validatorAttributes.process(@schema, false)

      @editor.addCommand 'validateWithAttributes', @validateWithAttributes, this
      @editor.addCommand 'validateWithoutAttributes', @validateWithoutAttributes, this
      @editor.addButton 'txt_validate_attrs', {cmd: 'validateWithAttributes', title: 'Full Validation'}
      @editor.addButton 'txt_validate_noattrs', {cmd: 'validateWithoutAttributes', title: 'Validation (Ignoring Attributes)'}

    validatePartialOpportunistic: (node, skipAttributes = false, descend = false) ->
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
      res = na
      while index--
        res = possiblePatterns[index].childDeriv(node, descend)
        unless res instanceof na
          return true
      return false




    validateFullEditor: (skipAttributes = false) ->
      docdom = (new window.DOMParser()).parseFromString(@editor.getContent(), "text/xml")

      if skipAttributes
        @validatorNoAttributes.getObjects().setSkipAttributes true
        res = @validatorNoAttributes.start.childDeriv(docdom.documentElement, true)
      else
        @validatorAttributes.getObjects().setSkipAttributes false
        res = @validatorAttributes.start.childDeriv(docdom.documentElement, true)
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



  return {
    TextorumValidator: TextorumValidator
  }

