###
# loader.coffee - Textorum XSLT-filtered loading/saving
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
###
define (require) ->
  helper = require('../helper')

  processor = undefined
  revprocessor = undefined

  initProcessors = (textorumPath = "", inlineElements = null, fixedElements = null) ->
    processor = new XSLTProcessor()
    textorumPath = helper.trailingslashit textorumPath
    forwardStylesheet = helper.getXML textorumPath + "xsl/xml2cke.xsl"
    processor.importStylesheet(forwardStylesheet)
    # TODO: Switch to class setup, get these params from main textorum plugin
    # Elements to bring across as <span> rather than <div>
    processor.setParameter(null, "inlineelements", inlineElements)

    # Elements to bring over without changing their element name
    processor.setParameter(null, "fixedelements", fixedElements)

    revprocessor = new XSLTProcessor()
    revStylesheet = helper.getXML textorumPath + "xsl/cke2xml.xsl"
    revprocessor.importStylesheet(revStylesheet)

  serializeError = (xmlDoc) ->
    try
      return (new XMLSerializer()).serializeToString(xmlDoc)
    catch e
      if e.name is "NS_ERROR_XPC_BAD_CONVERT_JS"
        return ""
      throw e

  loadFromText = (text) ->
    xmlDoc = helper.parseXML text
    if helper.hasDomError(xmlDoc)
      return serializeError(xmlDoc)
    newDoc = processor.transformToDocument(xmlDoc)
    (new XMLSerializer()).serializeToString(newDoc)

  saveFromText = (text) ->
    xmlDoc = helper.parseXML text
    if helper.hasDomError(xmlDoc)
      return serializeError(xmlDoc)
    revNewDoc = revprocessor.transformToDocument(xmlDoc)
    (new XMLSerializer()).serializeToString(revNewDoc)
      .replace(/\/\/TEXTORUM\/\/DOCTYPE-SYSTEM\/\//,
        "http://dtd.nlm.nih.gov/publishing/3.0/journalpublishing3.dtd")
      .replace(/^(<!DOCTYPE[^>]*>\s*<[^>]*?)[ ]?xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/g, "$1")
      # XSLT 1.0 doesn't support params in <xsl:output>, so use a placeholder
      # Chrome adds an unneeded xmlns:xml

  bindHandler = (editor, textorumPath, inlineElements, fixedElements) ->
    if not processor
      initProcessors(textorumPath, inlineElements, fixedElements)

    editor.onBeforeSetContent.add (ed, o) ->
      if o.format is "raw"
        return
      # console.log "beforesetcontent", o, [o.content]
      o.content = loadFromText(o.content)

    editor.onPostProcess.add (ed, o) ->
      # console.log "postprocess", o
      if o.set and not o.format is "raw"
        o.content = loadFromText(o.content)

      if o.get
        o.content = saveFromText(o.content)

  return {
    bindHandler: bindHandler
  }


