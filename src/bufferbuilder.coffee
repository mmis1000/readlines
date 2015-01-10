
class BufferBuilder
  constructor: ()->
    @buffers = []
    @length = 0

  append: (buffer)->
    if not (buffer instanceof Buffer)
      buffer = new Buffer(buffer)
    @length += buffer.length
    @buffers.push buffer
    @

  get: ()->
    newBuffer =Buffer.concat @buffers
    @buffers = [newBuffer]
    
    #console.log newBuffer, @
    newBuffer
    
    
module.exports = BufferBuilder