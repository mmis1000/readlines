readlines = require '../'

reader =  new readlines({fileName : "/dev/urandom", encode : "utf8", lines : 100000})

count = 0
id = null

load = ()->
    console.log 'init'
    read = ()->
        i = 0
        while line = reader.readline()
            i++
            if i % 10000 == 0
                console.log i
            count++
            #if reader.exited
                #clearInterval(id)
        console.log(count)
    #id = setInterval read, 1000
    read()

reader.on 'readable', load

reader.on 'end', ()->
    console.log 'bye! bye!'