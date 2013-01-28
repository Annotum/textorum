# tree.coffee - Textorum TinyMCE plugin, element tree
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
  helper = require('../helper')
  tinymce = require('tinymce')
  window.textorum ||= {}
  $ = window.jQuery

  window.textorum.w ||= {}
  w = window.textorum.w

  treeIDPrefix = 'tmp_tree_'
  ignoreNavigation = false
  w.structs = {}
  w.deletedStructs = {}
  treeSelector = undefined
  createTree = (selector, editor) ->
    treeSelector = selector
    foo = $(selector).jstree({
      core: {
        animation: 0
        },
      themeroller: {},
      ui: {
        select_limit: 1
      },
      json_data: {
        data: {
          data: 'Document',
          attr: {id: 'root'},
          state: 'open'
        }
      },
      plugins: ['json_data', 'ui', 'themeroller', 'contextmenu']
      })

  _selectNodeHandlerGenerator = (editor) ->
    selectNodeHandler = (event, data) ->
      if ignoreNavigation
        return
      console.log "select_node", event, data
      node = data.rslt.obj;
      id = node.attr('name');
      if (id)
        console.log "clicked", id

        node = editor.dom.select('#'+id);
        #node.append('<span class="empty_tag_remove_me"></span>');

        nodeEl = node[0]
        editor.getWin().scrollTo(0, editor.dom.getPos(nodeEl).y);
        editor.selection.select(nodeEl)
        editor.nodeChanged()

        editor.focus()

  _depthWalkCallbackGenerator = (holder) ->
    depthWalkCallback = (depth) ->
      node = this
      if not node.getAttribute?
        return false
      id = node.getAttribute('id')
      if not id
        node.setAttribute('id', tinymce.DOM.uniqueId(treeIDPrefix))
        id = node.getAttribute('id')
      while depth < (holder.length - 1)
        holder.shift()
      title = node.getAttribute('data-xmlel') || ("[" + node.localName + "]")
      holder[0]['children'] ||= []
      holder[0]['state'] ||= 'closed'
      holder[0]['children'].push {
        'data': title,
        'attr': {
          name: id,
          class: node.getAttribute('class')
        }
      }
      if (depth) <= holder.length - 1
        holder.unshift holder[0]['children'][holder[0]['children'].length - 1]
      true


  updateTree = (selector, editor) ->
    body = editor.dom.getRoot()

    treeInstance = $(selector).jstree('get_instance')

    top = {
      data: 'Document',
      state: 'open',
      children: []
    }
    window.topcontainer = top
    holder = []
    holder.unshift top
    window.bodything = body

    helper.depthFirstWalk body, _depthWalkCallbackGenerator(holder)

    $(selector).jstree({
      json_data: {
        data: [window.topcontainer]
      },
      ui: {
        select_limit: 1
      }
      core: {
        animation: 0
      },
      plugins: ['json_data', 'ui', 'themes', 'contextmenu']
      }).on('select_node.jstree', _selectNodeHandlerGenerator(editor))
    
  navigateTree = (editor, controlmanager, node) ->
    ignoreNavigation = true
    treeInstance = $(treeSelector).jstree('get_instance')
    treeInstance.close_all(-1, false)
    firstNode = treeInstance._get_node("[name='#{node.getAttribute('id')}']")
    if firstNode
      secondNode = treeInstance._get_parent(firstNode)
      treeInstance.open_node(secondNode)
      treeInstance.open_node(firstNode)
      treeInstance.select_node(firstNode)
    ignoreNavigation = false
    return null

  # Module return
  {
    create: createTree
    update: updateTree
    navigate: navigateTree
    id_prefix: treeIDPrefix
  }
    

