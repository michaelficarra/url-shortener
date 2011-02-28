using 'mongodb'

helper getMongoClient: ->
		{Db,Server} = mongodb
		db = new Db 'urlshortener', new Server '127.0.0.1', 27017, {}
		throw new Error "mongo: couldn't connect" unless db
		db


get '/mongo/shorten/:url', (req, resp) ->
	db = getMongoClient()
	url = @url
	finish = (e) ->
		throw e if e
		db.close()
		render 'showAlias'
	db.open (err, pdb) ->
		db.collection 'aliasCount', (e, aliasCount) ->
			throw e if e
			do retry = ->
				aliasCount.findOne {}, (e, count) ->
					throw e if e
					if count in [null, undefined]
						aliasCount.save {count: 0}, retry
						return
					nextAlias = +count.count
					aliasCount.update count, {$inc: count: 1}, (e, doc) ->
						throw e if e
						return retry() if !doc
						params.alias = nextAlias
						db.collection 'aliases', (e, aliases) ->
							throw e if e
							aliases.save {url, alias: nextAlias}, finish
	null


get '/mongo/expand/:alias', (req, resp) ->
	db = getMongoClient()
	alias = parseInt @alias, 32
	db.open (err, pdb) ->
		db.collection 'aliases', (e, aliases) ->
			aliases.findOne {alias}, (e, doc) ->
				throw e if e
				if doc in [null, undefined]
					params.url = 'alias not found'
				else
					params.url = doc.url
				db.close()
				render 'showUrl'
	return


get '/mongo/clean', (req, resp) ->
	db = getMongoClient()
	otherFinished = false
	finish = ->
		# unsafe because of no test-and-set
		if !otherFinished then return otherFinished = true
		db.close()
	db.open (err, pdb) ->
		db.collection 'aliasCount', (e, aliasCount) ->
			aliasCount.remove {}, finish
	db.open (err, pdb) ->
		db.collection 'aliases', (e, aliases) ->
			aliases.remove {}, finish
	"done"
