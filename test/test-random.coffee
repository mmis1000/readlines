readlines = require '../'

reader =  new readlines({fileName : "/dev/urandom", encode : "utf8", lines : 200})

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
    id = setInterval read, 200

reader.once 'readable', load

reader.on 'end', ()->
    console.log 'bye! bye!'