Parchment = require('parchment')

class Color extends Parchment.Style
  @attrName: 'color'
  @styleName: 'color'

Color = Parchment.define(Color)

module.exports = Color