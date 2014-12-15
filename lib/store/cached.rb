class Store::Cached < Store
	attr_reader :db
	attr_reader :cache, :working

	def initialize db, cache = Store::Memory.new, working = Store::Memory.new
		@db = db
		@cache = cache
		@working_blank = working
		@working = working.dup
	end

	def load opts = {}, &blk
		batch = @cache.batch
		@db.range(opts).each do |k, v|
			batch[k] = v
		end.onend do
			batch.apply
			blk.call if blk
		end
		self
	end

	def unload opts = {}
		t = @working
		@working = @working_blank.dup
		batch = @cache.batch
		@cache.range(opts).each do |k, v|
			batch.del k
		end
		batch.apply
		@working = t
		self
	end

	def apply batch
		@cache.apply batch
		@working.apply batch
		# @working.merge! batch
		self
	end

	def get key
		val = @cache[key]
		if val == nil
			begin
				val = @db[key]
				@cache[key] = val
			rescue
			end
		end
		val
	end

	def _range from, to
		# @data.select { |key, val| key >= from && key <= to }.map { |key, val| [key, val] }
		@cache._range from, to
	end

	def save
		@db.apply Hash[*@working.range.flat_map{|kv|kv}]
		@working = @working_blank.dup
		self
	end

	def dup
		Store::Cached.new @db.dup, @cache.dup, @working_blank.dup
	end
end