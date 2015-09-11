Quill    = require('../quill')
Document = require('../core/document')
_        = Quill.require('lodash')
dom      = Quill.require('dom')
Delta    = Quill.require('delta')

class PasteManager
  @DEFAULTS:
    onConvert: null

  constructor: (@quill, options) ->
    @container = @quill.addContainer('ql-paste-manager')
    @container.setAttribute('contenteditable', true)
    dom(@quill.root).on('paste', _.bind(this._paste, this))
    @options = _.defaults(options, PasteManager.DEFAULTS)
    @options.onConvert ?= this._onConvert;

  _onConvert: (container) =>
    doc = new Document(container, @quill.options)
    delta = doc.toDelta()
    lengthAdded = delta.length()
    if lengthAdded == 0
      return delta
    # Need to remove trailing newline so paste is inline, losing format is expected and observed in Word
    return delta.compose(new Delta().retain(lengthAdded - 1).delete(1))

  _paste: ->
    oldDocLength = @quill.getLength()
    range = @quill.getSelection()
    scrollTopBefore = @quill.container.scrollTop
    containerClientRect = @quill.container.getBoundingClientRect()
    return unless range?
    @container.focus()
    window.requestAnimationFrame( =>
      delta = @options.onConvert(@container)
      lengthAdded = delta.length()
      if lengthAdded > 0
        delta.ops.unshift({ retain: range.start }) if range.start > 0
        delta.delete(range.end - range.start)
        @quill.updateContents(delta, 'user')
      @quill.setSelection(range.start + lengthAdded, range.start + lengthAdded)
      # Make sure pasted content is visible
      [line, offset] = @quill.editor.doc.findLineAt(range.start + lengthAdded)
      lineClientRect = line.node.getBoundingClientRect()
      lineBottom = lineClientRect.bottom
      if scrollTopBefore + containerClientRect.top < lineBottom < scrollTopBefore + containerClientRect.top + containerClientRect.height
        # pasted line was in conteiner viewport — return scrollTop
        @quill.container.scrollTop = scrollTopBefore
      else
        # calculate scrollTop of container in the way that pasted content in the middle
        @quill.container.scrollTop = line.node.offsetTop + lineClientRect.height - containerClientRect.height/2
      @container.innerHTML = ""
    )


Quill.registerModule('paste-manager', PasteManager)
module.exports = PasteManager
