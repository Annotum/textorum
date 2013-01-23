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
  plugin = () ->
    beforeInit = (editor) ->
      CKEDITOR.tools.extend editor.config, {
        enterMode: CKEDITOR.ENTER_DIV
        fillEmptyBlocks: false,
        basicEntities: false,
        entities_latin: false,
        entities_greek: false,
        entities: true,
        entities_additional: 'gt,lt,amp'
        }, true

    onLoad = ->
      CKEDITOR.addCss(pluginCss)

    init = (editor) ->
      # TODO: Move rules for a given schema into an external config file.
      editor.dataProcessor.dataFilter.addRules {
        elements: {
          $: (element) ->
            if element.attributes['data-xmlel']
              switch element.attributes['data-xmlel']
                when 'bold' then element.name = 'b'
                when 'italic' then element.name = 'i'
                when 'monospace' then element.name = 'code'
                when 'preformat' then element.name = 'pre'
                when 'underline' then element.name = 'u'
                when 'sup' then element.name = 'sup'
                when 'sub' then element.name = 'sub'
                when 'formats', 'named-content', 'ext-link', 'inline-graphic', 'inline-formula'
                  element.name = 'span'
                when 'list'
                  if element.attributes['list-type'] is 'order'
                    element.name = 'ol'
                  else
                    element.name = 'ul'
                when 'list-item'
                  element.name = 'li'
                when 'table', 'tbody', 'thead', 'th', 'tr', 'td'
                  element.name = element.attributes['data-xmlel']
                else
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
