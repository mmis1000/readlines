(function() {
  var BufferBuilder, CHAR_N, CHAR_R, EventEmitter, callsite, fs, path, readlines,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  fs = require('fs');

  callsite = require('callsite');

  path = require('path');

  BufferBuilder = require('./bufferbuilder.js');

  CHAR_R = 13;

  CHAR_N = 10;


  /*
    emit : line
    emit : readable
    emit : end
   */

  readlines = (function(_super) {
    __extends(readlines, _super);

    function readlines(options) {
      var MergedOptions, callerDir, key, value;
      MergedOptions = {
        fileName: null,
        input: null,
        output: null,
        lines: 10,
        preloadLinesRatio: 2,
        ignoreEmptyLine: true,
        macStyleLineEnd: false,
        encode: null,
        maxBuffer: null
      };
      callerDir = path.dirname(callsite()[1].getFileName());
      for (key in options) {
        value = options[key];
        if (options.hasOwnProperty(key)) {
          MergedOptions[key] = value;
        }
      }
      if (MergedOptions.input === null && MergedOptions.fileName !== null) {
        MergedOptions.fileName = path.resolve(callerDir, MergedOptions.fileName);
        MergedOptions.input = fs.createReadStream(MergedOptions.fileName);
      }
      if (MergedOptions.input === null) {
        throw new Error("no input source! " + MergedOptions.input + " " + MergedOptions.fileName);
      }
      if ((typeof MergedOptions.lines !== 'number') && MergedOptions.lines % 1 !== 0) {
        throw new Error('bad lines');
      }
      if ((typeof MergedOptions.preloadLinesRatio !== 'number') && MergedOptions.lines <= 1) {
        throw new Error('bad preloadLinesRatio');
      }
      if (typeof MergedOptions.ignoreEmptyLine !== 'boolean') {
        throw new Error('bad ignoreEmptyLine');
      }
      if (typeof MergedOptions.macStyleLineEnd !== 'boolean') {
        throw new Error('bad macStyleLineEnd');
      }
      if (MergedOptions.maxBuffer === null) {
        MergedOptions.maxBuffer = MergedOptions.lines * 256;
      }
      this.options = MergedOptions;
      if (!this.setEncoding(this.options.encode)) {
        throw new Error('bad encode');
      }
      this.buffers = new BufferBuilder;
      this.unfinishedLine = [];
      this.lines = [];
      this.paused = false;
      this.hasEnoughData = false;
      this.flowMode = false;
      this.pulling = true;
      this.dry = true;
      this.lastByte = -1;
      this.sourceClose = false;
      this.exited = false;
      this.reading = false;
      this.init_();
    }

    readlines.prototype.init_ = function() {
      this.on('newListener', (function(_this) {
        return function(event) {
          if (event === 'line') {
            return _this.flowMode = true;
          }
        };
      })(this));
      this.options.input.on('readable', (function(_this) {
        return function() {
          _this.dataAvaliable = true;
          if (_this.flowMode || _this.pulling) {
            _this.pullData_();
          }
          if (_this.lines.length >= _this.options.lines * _this.options.preloadLinesRatio) {
            _this.pulling = false;
            if (_this.dry) {
              _this.dry = false;
              return _this.emit('readable');
            }
          }
        };
      })(this));
      return this.options.input.on('end', (function(_this) {
        return function() {
          _this.parseData_(true);
          if (_this.dry) {
            _this.emit('readable');
          }
          return _this.sourceClose = true;
        };
      })(this));
    };

    readlines.prototype.pullData_ = function() {
      var data;
      while (this.lines.length < this.options.lines * this.options.preloadLinesRatio) {
        while (data = this.options.input.read()) {
          this.buffers.append(data);
          if (this.options.output) {
            this.options.output.write(data);
          }
          this.dataAvaliable = false;
          if (this.buffers.length > this.options.maxBuffer) {
            this.dataAvaliable = true;
            break;
          }
        }
        this.parseData_();
        if (!data) {
          break;
        }
      }
      if (!this.reading) {
        while (this.flowMode && this.readline()) {}
        return undefined;
      }
    };

    readlines.prototype.parseData_ = function(Eof) {
      var buffer, current, i, lineUpdate;
      i = 0;
      lineUpdate = false;
      buffer = this.buffers.get();
      while (void 0 !== (current = buffer[i++])) {
        switch (current) {
          case CHAR_N:
            if (!this.options.macStyleLineEnd) {
              if (this.options.ignoreEmptyLine) {
                if (this.unfinishedLine.length !== 0) {
                  lineUpdate = true;
                  this.addline_();
                }
              } else {
                lineUpdate = true;
                this.addline_();
              }
            } else {
              this.addline_();
            }
            break;
          case CHAR_R:
            if (this.options.macStyleLineEnd) {
              if (this.options.ignoreEmptyLine) {
                if (this.unfinishedLine.length !== 0) {
                  lineUpdate = true;
                  this.addline_();
                }
              } else {
                lineUpdate = true;
                this.addline_();
              }
            }
            break;
          default:
            if (this.lastByte === CHAR_R && !this.options.macStyleLineEnd) {
              this.unfinishedLine.push(CHAR_R);
            }
            this.unfinishedLine.push(current);
        }
        this.lastByte = current;
      }
      if (Eof && 0 > this.unfinishedLine.length) {
        if (this.lastByte === CHAR_R && !this.options.macStyleLineEnd) {
          this.unfinishedLine.push(CHAR_R);
        }
        this.addline_();
      }
      return this.buffers = new BufferBuilder;
    };

    readlines.prototype.addline_ = function() {
      var line;
      line = new Buffer(this.unfinishedLine);
      this.lines.push(line);
      return this.unfinishedLine = [];
    };

    readlines.prototype.pause = function() {
      return this.flowMode = false;
    };

    readlines.prototype.resume = function() {
      this.flowMode = true;
      return process.nextTick((function(_this) {
        return function() {
          while (_this.flowMode && _this.readline()) {}
          return undefined;
        };
      })(this));
    };

    readlines.prototype.readline = function() {
      var line;
      if (this.reading) {
        this.emit('error', new Error('call readline within line event'));
      }
      this.reading = true;
      if (this.lines.length < this.options.lines) {
        if (this.dataAvaliable) {
          this.pullData_();
        } else {
          this.pulling = true;
        }
      }
      if (this.lines.length === 0) {
        this.dry = true;
        if (this.sourceClose) {
          this.exited = true;
          process.nextTick((function(_this) {
            return function() {
              return _this.emit('end');
            };
          })(this));
        }
        this.reading = false;
        return null;
      }
      line = this.encodeLine(this.lines.shift());
      this.emit('line', line);
      this.reading = false;
      return line;
    };

    readlines.prototype.encodeLine = function(line) {
      if (this.options.encode === null) {
        return line;
      }
      return line.toString(this.options.encode);
    };

    readlines.prototype.setEncoding = function(encode) {
      if (-1 === [null, 'ascii', 'utf8', 'utf16le', 'ucs2', 'base64', 'binary', 'hex'].indexOf(encode)) {
        return false;
      }
      this.options.encode = encode;
      return true;
    };

    return readlines;

  })(EventEmitter);

  module.exports = readlines;

}).call(this);
