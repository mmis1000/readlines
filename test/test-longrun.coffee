Readable = require('stream').Readable;
readlines = require '../'


class Counter extends Readable
    constructor: (opt)->
        Readable.call(this, opt);
        this._max = 100000000000000000;
        this._index = 1;
    _read: ()->
        i = this._index++;
        if i > this._max
            this.push(null);
        else
            this.push('azzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz-' + i + '-\r\n')

reader =  new readlines({input : new Counter, encode : "utf8", lines : 200})
count = 0
id = null

load = ()->
    console.log 'init'
    read = ()->
        i = 0
        while i++ < 200
            line = reader.readline()
            if !line
                break
            count++
            if reader.exited
                clearInterval(id)
        console.log(count)
    id = setInterval read, 10

reader.once 'readable', load

reader.on 'end', ()->
    console.log 'bye! bye!'