# plugin.coffee - Textorum CKEditor plugin, main body
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
  CKEDITOR = require('ckeditor')
  xslt = require('./xslt')
  pluginCss = require('text!./plugin.css')

  originalDTD = {}

  schema = {
    elementMappings: {},
    containedBy: {},
    defs: {}
  }

  htmlElements = {
    caption: 1,
    article: 1
  }

  jQuery.getJSON "test/rng/kipling-jp3.json", (data) ->
    schema = data
    schema.elementMappings ||= {}
    schema.containedBy ||= {}
    schema.defs ||= {}

  plugin = () ->
    beforeInit = (editor) ->
      CKEDITOR.tools.extend editor.config, {
        enterMode: CKEDITOR.ENTER_DIV,
        autoParagraph: false,
        fillEmptyBlocks: false,
        basicEntities: false,
        entities_latin: false,
        entities_greek: false,
        entities: true,
        ignoreEmptyParagraph: true,
        entities_additional: 'gt,lt,amp'
        }, true

    onLoad = ->
      CKEDITOR.addCss(pluginCss)

    addDTDContains = (containingElement, containedElement) ->
      # console.log "adding", "#{containingElement} to #{containedElement}"
      elementContains = {}
      elementContains[containedElement] = 1
      output = {}
      output[containingElement] = elementContains
      CKEDITOR.tools.extend CKEDITOR.dtd, output
      CKEDITOR.tools.extend CKEDITOR.dtd[containingElement], elementContains

    updateDTD = ->
      originalDTD = {}
      for own k, v of CKEDITOR.dtd
        originalDTD[k] = v
      containedBy = {}
      for element, details of schema.defs
        elementContains = {}
        for own containedElement, v of details.contains
          if containedElement is 'body'
            elementContains['cke-body'] = 1
          elementContains[containedElement] = 1
          containedBy[containedElement] ||= {}
          containedBy[containedElement][element] = 1
        if details.$
          elementContains['#'] = 1
        else
          elementContains['#'] = 1
        output = {}
        output[element] = elementContains
        CKEDITOR.tools.extend CKEDITOR.dtd, output
        CKEDITOR.tools.extend CKEDITOR.dtd[element], elementContains
        if details.$
          CKEDITOR.tools.extend CKEDITOR.dtd['$editable'][element] = 1

      schema.containedBy = containedBy
      CKEDITOR.dtd.$inline = {}


    addElementMapping = (originalElementName, newElementName) ->
      # console.log "mapping", "#{originalElementName} to #{newElementName}"

      schema.elementMappings[originalElementName] ||= {}
      schema.elementMappings[originalElementName][newElementName] = 1

      updateDTDContainsMappings originalElementName


    updateDTDContainsMappings = (originalElementName) ->
      if schema.containedBy[originalElementName] and schema.elementMappings[originalElementName]
        for own mappedMainElement, v of schema.elementMappings[originalElementName]
          CKEDITOR.dtd[mappedMainElement] = CKEDITOR.dtd[originalElementName]
          for own containingElement, v of schema.containedBy[originalElementName]
            addDTDContains containingElement, mappedMainElement
            if schema.elementMappings[containingElement]
              for own mappedContainingElement, v of schema.elementMappings[containingElement]
                CKEDITOR.dtd[mappedContainingElement] = CKEDITOR.dtd[containingElement]

    init = (editor) ->
      updateDTD()

      # TODO: Move rules for a given schema into an external config file.
      editor.dataProcessor.dataFilter.addRules {
        elements: {
          $: (element) ->
            if not element.attributes['data-xmlel']
              # console.log "skipping", element
              return null
            originalElementName = if (element.attributes['data-xmlel']) then element.attributes['data-xmlel'] else element.name
            switch originalElementName
              # Formatting
              when 'bold' then element.name = 'b'
              when 'italic' then element.name = 'i'
              when 'monospace' then element.name = 'code'
              when 'preformat' then element.name = 'pre'
              when 'underline' then element.name = 'u'
              when 'sup', 'sub'
                element.name = originalElementName
              # Inline elements
              when 'formats', 'named-content', 'ext-link', 'inline-graphic', 'inline-formula'
                element.name = 'span'
              # List elements
              when 'list'
                if element.attributes['list-type'] is 'order'
                  element.name = 'ol'
                else
                  element.name = 'ul'
              when 'list-item'
                element.name = 'li'
              # Table elements
              when 'table', 'thead', 'tbody', 'tr', 'th', 'td'
                element.name = originalElementName
              # Otherwise, use the basic element name _unless_ it is a known html5 element,
              # in which case prefix it with cke- to avoid (inherent) strange dom effects
              else
                if originalDTD[originalElementName]
                  element.name = "cke-#{originalElementName}"
                else
                  element.name = originalElementName

            if element.name isnt originalElementName
              element.attributes['data-xmlel'] = originalElementName
              addElementMapping originalElementName, element.name
            return null
          }
        }, 2
      editor.dataProcessor.htmlFilter.addRules {
        elements: {
          $: (element) ->
            element.name = 'div'
            return null
          }
        }, 2
      dblClickHandler = (evt) ->
        jQuery(evt.data.element.$).children().toggle()

        # console.log(evt)

      editor.on('doubleclick', dblClickHandler)

    afterInit = (editor) ->
      editor._.elementsPath?.filters?.push (element, name) ->
        # Hide elementsPath breadcrumbs for non-schema elements
        if name is 'body' or !element.getAttribute('data-xmlel')
          return "[" + name + "]"
        element.getAttribute('data-xmlel') or null

    CKEDITOR.plugins.add 'textorum', {
      requires: 'entities,ajax'
      onLoad: onLoad
      beforeInit: beforeInit
      init: init
      afterInit: afterInit
      }

  if CKEDITOR.status is 'loaded'
    plugin()
  else if CKEDITOR.on isnt undefined
    CKEDITOR.on('loaded', plugin)
  else
    setTimeout plugin, 1000
