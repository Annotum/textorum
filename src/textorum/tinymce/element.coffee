# element.coffee - Textorum element-editing popups
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
  helper = require('../helper')
  tinymce = window.tinymce
  $ = window.jQuery

  class ElementHandler
    namespaceIdx: 0
    constructor: (@editor) ->
      editor.addCommand 'addSchemaTag', @addTag, this
      editor.addCommand 'changeSchemaTag', @changeTag, this
      editor.addCommand 'editSchemaTag', @editTag, this
      editor.addCommand 'removeSchemaTag', @removeTag, this
    # Create a new tag, bring up editing window
    addTag: (ui, params) ->
      newtagname = params['key']
      if not @editor.plugins.textorum.schema.defs[newtagname]
        console.log "error", "no such tag in schema: #{newtagname}"
        return
      @editWindow params
    # Bring up editing window for existing tag
    editTag: (ui, params) ->
      @editWindow {}, params
    # Replace a tag with another one
    changeTag: (ui, params) ->
      newtagname = params['key']
      if not @editor.plugins.textorum.schema.defs[newtagname]
        console.log "error", "no such tag in schema: #{newtagname}"
        return
    # Delete a tag
    removeTag: (ui, params) ->

    attrFormHTML: (name, params, node) ->
      node = $(node)
      node = @editor.dom.select("##{node.attr('name')}")[0]
      if params.ns
        prefix = @editor.plugins.textorum.nsmap[params.ns]
        if prefix is undefined
          prefix = "txtns#{@namespaceIdx}"
          @editor.plugins.textorum.nsmap[params.ns] = prefix
          @namespaceIdx += 1
          # Better way to get the actual base document element?
          @editor.dom.select("body")[0].firstElementChild.setAttribute("xmlns:#{prefix}", params.ns)
          attrValue = node.getAttributeNS(params.ns, name)
          if attrValue
            node.removeAttributeNS(params.ns, name)
            node.setAttribute("#{prefix}:#{name}", attrValue)
          else
        if prefix
          name = "#{prefix}:#{name}"
          attrValue = node.getAttribute(name)
      else
        attrValue = node.getAttribute(name)

      if params.required or attrValue isnt undefined
        display = "block"
      else
        display = "none"
      out = document.createElement("div")
      out.setAttribute("style", """display: #{display};""")
      out.class = "attr_#{name}"
      label = document.createElement("label")
      label.appendChild(document.createTextNode("#{name}"))
      out.appendChild(label)

      if params.value?.length
        sel = document.createElement("select")
        sel.name = "attr_#{name}"
        if not params.required
          opt = document.createElement("option")
          opt.value = ""
          opt.appendChild(document.createTextNode(" -- empty -- "))
          sel.appendChild(opt)
        for value in params.value
          opt = document.createElement("option")
          opt.value = value
          if value is attrValue
            opt.setAttribute("selected", "selected")
          opt.appendChild(document.createTextNode(value))
          sel.appendChild(opt)
        out.appendChild(sel)
      else if params.data isnt undefined
        sel = document.createElement("input")
        sel.type = "text"
        sel.value = attrValue
        out.appendChild(sel)
      else if params.$?
        sel = document.createElement("textarea")
        sel.appendChild(document.createTextNode(attrValue))
        out.appendChild(sel)

      out

    editWindow: (params, node) ->
      attroptional = {}
      attrrequired = {}
      attrgroups = {}
      newtagname = $(node).attr("data-xmlel") || params['key']
      elementattrs = @editor.plugins.textorum.schema.defs[newtagname]?.attr

      attrform = document.createElement("div")
      for own attr of elementattrs
        attrform.appendChild(@attrFormHTML(attr, elementattrs[attr], node))
        if elementattrs[attr].required
          attroptional[attr] = elementattrs[attr]
        else
          attrrequired[attr] = elementattrs[attr]
      if attrform.childNodes.length
        wm = @editor.windowManager
        w = wm.open {
          inline: true
          resizable: true
          title: "Edit #{newtagname}"
          content: attrform
          buttons: [{
            text: 'Ok'
            click: (e) -> 
              console.log "OK button clicked:", e, w
              wm.close(null, w.id)
          }, {
            text: 'Cancel'
            click: (e) -> 
              console.log "Cancel button clicked:", e, w
              wm.close(null, w.id)
          }]
        }
      else
        console.log "no attributes"
      console.log "attrform", attrform
      console.log "Required:", attrrequired
      console.log "Optional:", attroptional


  init = (editor) ->
    return new ElementHandler(editor)

  {
    init: init    
  }