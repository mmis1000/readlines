(function() {
  var BufferBuilder;

  BufferBuilder = (function() {
    function BufferBuilder() {
      this.buffers = [];
      this.length = 0;
    }

    BufferBuilder.prototype.append = function(buffer) {
      if (!(buffer instanceof Buffer)) {
        buffer = new Buffer(buffer);
      }
      this.length += buffer.length;
      this.buffers.push(buffer);
      return this;
    };

    BufferBuilder.prototype.get = function() {
      var newBuffer;
      newBuffer = Buffer.concat(this.buffers);
      this.buffers = [newBuffer];
      return newBuffer;
    };

    return BufferBuilder;

  })();

  module.exports = BufferBuilder;

}).call(this);
