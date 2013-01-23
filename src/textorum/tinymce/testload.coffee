###
# testload.coffee - Test XSLT loading/saving
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
###
define (require) ->
  helper = require('../helper')
  tinymce = require('tinymce')

  $ = window.jQuery.noConflict()

  processor = new XSLTProcessor()
  xmlhttp = new XMLHttpRequest()

  xmlhttp.open("GET", "xsl/xml2cke.xsl", false)
  xmlhttp.send('')

  xslDoc = xmlhttp.responseXML
  processor.importStylesheet(xslDoc)

  revprocessor = new XSLTProcessor()

  xmlhttp = new XMLHttpRequest()

  xmlhttp.open("GET", "xsl/cke2xml.xsl", false)
  xmlhttp.send('')

  xslDoc = xmlhttp.responseXML
  revprocessor.importStylesheet(xslDoc)

  xslDoc = xmlhttp = undefined

  loadFromURI = (uri) ->
    xmlhttp = new XMLHttpRequest()
    xmlhttp.open("GET", uri, false)
    xmlhttp.send('')
    loadFromText(xmlhttp.responseText)

  loadFromText = (text) ->
    xmlDoc = (new DOMParser()).parseFromString(text, "text/xml")
    if xmlDoc.getElementsByTagName('parsererror').length
      return (new XMLSerializer()).serializeToString(xmlDoc)
    newDoc = processor.transformToDocument(xmlDoc)
    console.log newDoc
    (new XMLSerializer()).serializeToString(newDoc)
    
  saveFromText = (text) ->
    xmlDoc = (new DOMParser()).parseFromString(text, "text/xml")
    if xmlDoc.getElementsByTagName('parsererror').length
      window.parserErrorText = text
      return (new XMLSerializer()).serializeToString(xmlDoc)
    revNewDoc = revprocessor.transformToDocument(xmlDoc)
    (new XMLSerializer()).serializeToString(revNewDoc)

  loadDataHandler = (event) ->
    uri = $('#datafile').val()
    xmlhttp = new XMLHttpRequest()
    xmlhttp.open("GET", uri, false)
    xmlhttp.send('')
    tinymce.EditorManager.get('editor1').setContent(xmlhttp.responseText)

  saveDataHandler = (event) ->
    $('#mainform').submit()

  getDataHandler = (event) ->
    # console.log "getdata", event
    if event.editor.mode isnt "source"
      event.data.dataValue = saveFromText(event.data.dataValue)

  setDataHandler = (event) ->
    # console.log "setdata", event
    if event.editor.mode isnt "source"
      event.data.dataValue = loadFromText(event.data.dataValue)

  bindHandler = (editor) ->
    editor.onBeforeSetContent.add (ed, o) ->
      console.log "beforesetcontent", o
      o.content = loadFromText(o.content)

    editor.onPostProcess.add (ed, o) ->
      console.log "postprocess", o
      if (o.set)
        o.content = loadFromText(o.content)

      if (o.get)
        o.content = saveFromText(o.content)

  
  
  $('#loaddata').on('click', loadDataHandler)
  $('#savedata').on('click', saveDataHandler)
  $('.filenames').on 'click', 'li', (e) ->
    $('#datafile').val($(e.target).text())
    $('#loaddata').click()

  return {
    bindHandler: bindHandler
  }
  
  
