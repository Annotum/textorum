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
    constructor: (@editor) ->
      editor.addCommand 'addSchemaTag', @addTag, this
      editor.addCommand 'changeSchemaTag', @changeTag, this
      editor.addCommand 'editSchemaTag', @editTag, this
      editor.addCommand 'removeSchemaTag', @removeTag, this
    # Create a new tag, bring up editing window
    addTag: (ui, params) ->
      console.log 'addTag', params
      console.log 'this', this
      newtagname = params['key']
      if not @editor.plugins.textorum.schema.defs[newtagname]
        console.log "error", "no such tag in schema: #{newtagname}"
        return
      @editWindow params
    # Bring up editing window for existing tag
    editTag: (ui, params) ->
      console.log 'editTag', params
      @editWindow {}, params
    # Replace a tag with another one
    changeTag: (ui, params) ->
      console.log 'changeTag', params
      newtagname = params['key']
      if not @editor.plugins.textorum.schema.defs[newtagname]
        console.log "error", "no such tag in schema: #{newtagname}"
        return
    # Delete a tag
    removeTag: (ui, params) ->
      console.log 'removeTag', params

    attrFormHTML: (name, params, node) ->
      console.log name, params
      attrValue = $(node).attr(name)
      if params.required or attrValue isnt undefined
        display = "block"
      else
        display = "none"
      out = document.createElement("div")
      out.setAttribute("style", """display: #{display};""")
      out.class = "attr_#{name}"
      label = document.createElement("label")
      label.appendChild(document.createTextNode("#{name} - #{display}"))
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
        out.appendChild(sel)
      else if params.$?
        sel = document.createElement("textarea")
        out.appendChild(sel)

      out

    editWindow: (params, node) ->
      attroptional = {}
      attrrequired = {}
      attrgroups = {}
      newtagname = $(node).attr("data-xmlel") || params['key']
      elementattrs = @editor.plugins.textorum.schema.defs[newtagname].attr

      attrform = document.createElement("div")
      for own attr of elementattrs
        attrform.appendChild(@attrFormHTML(attr, elementattrs[attr]))
        if elementattrs[attr].required
          attroptional[attr] = elementattrs[attr]
        else
          attrrequired[attr] = elementattrs[attr]
      if attrform.childNodes.length
        @editor.windowManager.open {
          inline: true
          title: "Element Editor"
          content: attrform
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