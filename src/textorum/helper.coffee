# helper.coffee - Utility and DOM manipulation functions
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
  # Check if a given name is:
  #  - The same as the "names" (names is a string)
  #  - A proeprty of "names" (names is an object)
  #  - An element of "names" (names is an array / array-like)
  __name_matcher = (names, nombre) ->
    return nombre == names or names[nombre]? or nombre in names


  class Helpers
    ELEMENT_NODE: 1
    ATTRIBUTE_NODE: 2
    TEXT_NODE: 3
    CDATA_SECTION_NODE: 4
    ENTITY_REFERENCE_NODE: 5
    ENTITY_NODE: 6
    PROCESSING_INSTRUCTION_NODE: 7
    COMMENT_NODE: 8
    DOCUMENT_NODE: 9
    DOCUMENT_TYPE_NODE: 10
    DOCUMENT_FRAGMENT_NODE: 11
    NOTATION_NODE: 12


    constructor: ->

    clone: (obj) ->
      if not obj? or typeof obj isnt 'object'
        return obj

      if obj instanceof RegExp
        flags = ''
        flags += 'g' if obj.global?
        flags += 'i' if obj.ignoreCase?
        flags += 'm' if obj.multiline?
        flags += 'y' if obj.sticky?
        return new RegExp(obj.source, flags)

      if obj instanceof Date
        return new Date(obj.getTime())

      newInstance = new obj.constructor()

      for key of obj
        newInstance[key] = clone obj[key]

      return newInstance

    getFirstChildElement: (node, tagName) ->
      node = node.firstChild
      while node and node.nodeType isnt @ELEMENT_NODE
        node = node.nextSibling
      if node and tagName
        tagName = tagName.toLowerCase()
        if node.tagName and node.tagName.toLowerCase() isnt tagName
          node = @getNextSiblingElement(node, tagName)
      node

    getNextSiblingElement: (node, tagName) ->
      node = node.nextSibling
      while node and node.nodeType isnt @ELEMENT_NODE
        node = node.nextSibling
      if tagName
        tagName = tagName.toLowerCase()
        while node and node.tagName and node.tagName.toLowerCase() isnt tagName
          node = node.nextSibling
      return node


    getChildByName: (node, names, namespaceURI) ->
      for child in node.childNodes
        matches = __name_matcher(names, @getLocalName(child))
        nsOk = not child.namespaceURI? or child.namespaceURI is namespaceURI
        if matches and nsOk
          return child
      null

    getChildrenByName: (node, names, namespaceURI) ->
      children = []
      for child in node.childNodes
        matches = __name_matcher(names, @getLocalName(child))
        nsOk = not child.namespaceURI? or child.namespaceURI is namespaceURI
        if matches and nsOk
          children.push child
      children

    getNamespacePrefix: (nodeName) ->
      return '' if not nodeName?
      if nodeName.indexOf(':') isnt -1
        nodeName.split(':')[0]
      else
        ''

    getLocalName: (node) ->
      return "" if not node?
      if node?.localName?
        return node.localName
      if not node.nodeName?
        return ""
      colonIdx = node.nodeName.indexOf ":"
      if colonIdx < 0
        node.nodeName
      else
        node.nodeName.substr colonIdx + 1

    textContent: (node) ->
      return node.textContent if node.textContent
      result = ''
      for child in node.childNodes
        switch child.nodeType
          when @ELEMENT_NODE, @ENTITY_REFERENCE_NODE
            result += @textContent child
          when @ATTRIBUTE_NODE, @TEXT_NODE, @CDATA_SECTION_NODE
            result += child.nodeValue
      result

    getXML: (url) ->
      xslDoc = null
      if window.tinymce?.util?.XHR?
        tinymce.util.XHR.send {
          url: url,
          content_type: 'text/xml'
          async: false,
          success: (text, response) ->
            xslDoc = response.responseXML
        }
        return xslDoc
      xmlhttp = new XMLHttpRequest()
      xmlhttp.open("GET", url, false)
      xmlhttp.send('')
      xslDoc = xmlhttp.responseXML


    parseXML: (data) ->
      if not data or typeof data isnt "string"
        return data
      try
        if window.DOMParser
          parser = new DOMParser()
          xml = parser.parseFromString(data, "text/xml")
        else
          xml = new ActiveXObject("Microsoft.XMLDOM")
          xml.async = "false"
          xml.loadXML data
      catch e
        xml = undefined
      xml

    parseJSON: (text) ->
      (window.jQuery?.parseJSON || window.tinymce?.util?.JSON?.parse)(text)
      
    hasDomError: (dom) ->
      errorNS = "http://www.mozilla.org/newlayout/xml/parsererror.xml"
      (!dom or
        !dom.documentElement or
        dom.documentElement.namespaceURI == errorNS or
        (dom.getElementsByTagName("parsererror").length > 0)
      )
      

    depthFirstWalk: (node, callback) ->
      depth = 0
      skip = false
      done = false
      tmp = undefined
      while depth >= 0 and not done
        if not skip
          skip = (callback.call(node, depth) == false)
        if not skip and tmp = node.firstChild
          depth += 1
        else if tmp = node.nextSibling
          skip = false
        else
          tmp = node.parentNode
          depth -= 1
          if depth == 0
            done = true
          skip = true
        node = tmp
      undefined
  new Helpers()
