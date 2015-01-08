{EventEmitter} = require 'events'
fs = require 'fs'
callsite = require 'callsite'
path = require 'path'
BufferList = require 'bl'

CHAR_R = 13
CHAR_N = 10
###
  emit : line
  emit : readable
  emit : end
###

class readlines extends EventEmitter
  constructor: (options)->
    MergedOptions =
      fileName : null
      input : null
      output : null
      lines : 10
      preloadLinesRatio : 2
      ignoreEmptyLine : true
      macStyleLineEnd : false
      encode : null
      maxBuffer : null

    callerDir = path.dirname callsite()[1].getFileName()
    
    for key, value of options
      if options.hasOwnProperty key
        MergedOptions[key] = value
    
    if MergedOptions.input == null && MergedOptions.fileName != null
      MergedOptions.fileName = path.resolve callerDir, MergedOptions.fileName
      MergedOptions.input = fs.createReadStream MergedOptions.fileName
    
    if MergedOptions.input == null
      throw new Error "no input source! #{MergedOptions.input} #{MergedOptions.fileName}"
    
    if (typeof MergedOptions.lines != 'number') && MergedOptions.lines % 1 != 0
      throw new Error 'bad lines'
    if (typeof MergedOptions.preloadLinesRatio != 'number') && MergedOptions.lines <= 1
      throw new Error 'bad preloadLinesRatio'
    if (typeof MergedOptions.ignoreEmptyLine != 'boolean')
      throw new Error 'bad ignoreEmptyLine'
    if (typeof MergedOptions.macStyleLineEnd != 'boolean')
      throw new Error 'bad macStyleLineEnd'
    if MergedOptions.maxBuffer == null
      MergedOptions.maxBuffer =  MergedOptions.lines * 256
    
    @options = MergedOptions

    if !@setEncoding @options.encode
      throw new Error 'bad encode'
    
    @buffers = new BufferList
    @unfinishedLine = []
    @lines = []
    @paused = false
    @hasEnoughData = false
    @flowMode = false
    @pulling = true
    @dry = true
    @sourceClose = false
    @exited = false
    
    @init_()
    
  init_: ()->
    @on 'newListener', (event)=>
      #console.log('here listener')
      if event == 'line'
        @flowMode = true
    
    @options.input.on 'readable', ()=>
      #console.log('here data')
      @dataAvaliable = true
      if @flowMode or @pulling
        @pullData_()
      if @lines.length >= @options.lines * @options.preloadLinesRatio
        @pulling = false
        if @dry
          @dry = false
          @emit 'readable'
    
    @options.input.on 'end', ()=>
      @parseData_ true
      if @dry
        @emit 'readable'
      @sourceClose = true
    
  pullData_: ()->
    #console.log('here pull data')
    while data = @options.input.read()
      @buffers.append data
      if @options.output
        @options.output.write data
      @dataAvaliable = false
      
      if @buffers.length > @options.maxBuffer
        @dataAvaliable = true
        break;
    
    @parseData_()
    while @flowMode && @readline()
      ;#console.log('here send data')
    
  parseData_: (Eof)->
    #console.log('here parse data')
    i = 0
    lineUpdate = false
    while undefined != (current = @buffers.get i++)
      switch current
        when CHAR_N
          if !@options.macStyleLineEnd
            if @options.ignoreEmptyLine
              if @unfinishedLine.length != 0
                lineUpdate = true
                @addline_()
            else
              lineUpdate = true
              @addline_()
          else
            @addline_()
            
        when CHAR_R
          if @options.macStyleLineEnd
            if @options.ignoreEmptyLine
              if @unfinishedLine.length != 0
                lineUpdate = true
                @addline_()
            else
              lineUpdate = true
              @addline_()
        else
          @unfinishedLine.push current
    
    if Eof && 0 > @unfinishedLine.length
      @addline_()
    
    @buffers = new BufferList
    
    
    
  addline_: ()->
    #console.log('here add line')
    line = new Buffer(@unfinishedLine)
    @lines.push line
    @unfinishedLine = []
  
  pause: ()->
    @flowMode = false
  
  resume: ()->
    @flowMode = true
    process.nextTick ()=>
      while @flowMode && @readline()
        ;#console.log('here send data')
  
  readline: ()->
    #console.log('here read line')

    if @lines.length < @options.lines * @options.preloadLinesRatio
      if @dataAvaliable
        @pullData_()
      else
        @pulling = true

    if @lines.length == 0
      @dry = true
      if @sourceClose
        @exited = true
        process.nextTick ()=>
          @emit 'end'
      return null 

    line = @encodeLine @lines.shift()
    @emit 'line', line
      
    return line
    
  encodeLine: (line)->
    return line if @options.encode == null
    return line.toString(@options.encode)
    
  setEncoding: (encode)->
    return false if -1 == [null, 'ascii', 'utf8', 'utf16le', 'ucs2', 'base64', 'binary', 'hex'].indexOf encode
    @options.encode = encode
    return true

module.exports = readlines
  
    