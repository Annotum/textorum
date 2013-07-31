###
# demobindings.coffee - Hooks for loading/saving in the textorum demo
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

  tinymce = window.tinymce
  $ = window.jQuery

  loadDataHandler = ->
    uri = $('#datafile').val()
    data = helper.getXML uri
    if data
      ed = tinymce.EditorManager.get('editor1')
      if ed
        ed.setContent(data)

  clickLoadDataHandler = (event) ->
    uri = $('#datafile').val()
    browseruri = window.location + ""
    browseruri = browseruri.replace(/\?.*$/, "")
    browseruri = browseruri + "?s=" + encodeURIComponent(uri)
    if history?.pushState
      history.pushState {
        uri: uri
      }, "uri #{uri}", browseruri
    loadDataHandler()

  popStateHandler = (event) ->
    #console.log event
    if event.originalEvent?.state?.uri
      $('#datafile').val(event.originalEvent.state.uri)
      loadDataHandler()

  saveDataHandler = (event) ->
    $('#mainform').submit()

  $(window).on('popstate', popStateHandler)
  $('#loaddata').on('click', clickLoadDataHandler)
  $('#savedata').on('click', saveDataHandler)
  $('.filenames').on 'click', 'li', (e) ->
    $('#datafile').val($(e.target).text())
    $('#loaddata').click()
