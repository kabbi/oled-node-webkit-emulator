DataStore = exports? and exports or @DataStore = {}

# Which kind of database do you want?
# "simple" - use localStorage. Simple, but synchronous/blocking!
# "relational" - use browser sqlite implementation, Web SQL Database
# "document" - use https://github.com/louischatriot/nedb
DataStore.create = ( type ) ->
	switch type
		when "simple" then createSimpleStore()
		when "relational" then createRelationalStore()
		when "document" then createDocumentStore()
		else return undefined

createSimpleStore = ->
	get: ( key ) ->
		JSON.parse localStorage.getItem JSON.stringify key
	set: ( key, value ) ->
		localStorage.setItem JSON.stringify key, JSON.stringify value
	delete: ( key ) ->
		localStorage.removeItem JSON.stringify key
	count: ->
		localStorage.length
	clear: ->
		localStorage.clear()

createRelationalStore = ->
	db = openDatabase "nwsqldb", "1.0", "embedded sql database",
		1024 * 1024 * 256
	store =
		run: ( query, fn ) ->
			db.transaction ( tx ) ->
				tx.executeSql query, [], ( tx, result ) ->
					fn? (result.rows.item i for i in [0 ... result.rows.length])

	return store

createDocumentStore = ->
	try
		NeDB = require "nedb"
		datapath = require( "nw.gui" ).App.dataPath + "/nedb"
		store =
			collection: ( name ) ->
				new NeDB
					filename: "/#{name}"
					autoload: true

		return store

	catch e
		if e.code is "MODULE_NOT_FOUND"
			console.error "NeDB not found. Try `npm install nedb --save`
			inside of `/app/assets`."
		else
			console.error e
