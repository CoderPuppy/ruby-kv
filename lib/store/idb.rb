class Store::IDB < Store
	def initialize name
		@queue = []
		%x{
			var request = indexedDB.open(#{name}, 1)
			request.onupgradeneeded = function(e) {
				var db = request.result
				if(!db.objectStoreNames.contains('kv')) {
					var store = db.createObjectStore('kv', {keyPath: 'key'})
					store.createIndex('key', 'key', {unique: true})
				}
			}
			request.onsuccess = function(e) {
				#{
					@db = `request.result;`
					@queue.each do |job|
						job[]
					end
					@queue = nil
				}
			}
			request.onerror = function(e) {
				console.log(e)
			}
		}
	end

	def apply batch
		try do
			transaction = `#@db.transaction(['kv'], 'readwrite')`
			store = `#{transaction}.objectStore('kv')`
			batch.each do |key, val|
				`#{store}.delete(#{key})`
				unless val == nil
					`#{store}.put({key: #{key}, val: #{val}})`
				end
			end
		end
		self
	end

	# def get key
		
	# end

	def _range from, to
		range = `IDBKeyRange.bound(#{from}, #{to})`
		Enumerator.new do |out, done|
			try do
				transaction = `#@db.transaction(['kv'], 'readonly')`
				store = `#{transaction}.objectStore('kv')`
				index = `#{store}.index('key')`
				%x{#{index}.openCursor(#{range}).onsuccess = function(e) {
					var cursor = e.target.result
					if(cursor) {
						// #{log `cursor.value.key`, `cursor.value.val`}
						// debugger
						#{out << [`cursor.value.key`, `cursor.value.val`]}
						cursor.continue()
					} else {
						#{done[]}
					}
				}}
			end
		end.lazy
	end

	def close
		try do
			`#@db.close()`
		end
		self
	end

	private
		def try &blk
			if @db
				blk[]
			else
				@queue << blk
			end
		end
end