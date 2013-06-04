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

      @editor.addCommand 'validateWithAttributes', @validateWithAttributes, this
      @editor.addCommand 'validateWithoutAttributes', @validateWithoutAttributes, this
      @editor.addButton 'txt_validate_attrs', {cmd: 'validateWithAttributes', title: 'Full Validation'}
      @editor.addButton 'txt_validate_noattrs', {cmd: 'validateWithoutAttributes', title: 'Validation (Ignoring Attributes)'}

    validate: (skipAttributes = false) ->
      rngparser = new RNGParser()
      # rngparser.debug = true
      rngparser.process(@schema, skipAttributes)
      docdom = (new window.DOMParser()).parseFromString(@editor.getContent(), "text/xml")

      res = rngparser.start.childDeriv(docdom.documentElement, true)
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
        $(@validationOutputSelector).html("<i>Error:</i> #{res}")
      return res

    validateWithoutAttributes: ->
      @validate(true)

    validateWithAttributes: ->
      @validate(false)



  return {
    TextorumValidator: TextorumValidator
  }

