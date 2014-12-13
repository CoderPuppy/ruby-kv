class RedBlackTree
	include Enumerable

	class Node
		UNDEFINED = Object.new

		attr_reader :key, :value, :color
		attr_reader :left, :right

		def initialize(key, value, left, right, color = :red)
			@key = key
			@value = value
			@left = left
			@right = right
			# new node is added as red
			@color = color
		end

		def as_root
			with_color(:black)
		end

		def with_key(key)
			Node.new(key, @value, @left, @right, @color)
		end

		def with_value(value)
			Node.new(@key, value, @left, @right, @color)
		end

		def with_left(left)
			Node.new(@key, @value, left, @right, @color)
		end

		def with_right(right)
			Node.new(@key, @value, @left, right, @color)
		end

		def with_color(color)
			Node.new(@key, @value, @left, @right, color)
		end

		def red?
			@color == :red
		end

		def black?
			@color == :black
		end

		def empty?
			false
		end

		def size
			@left.size + 1 + @right.size
		end

		# inorder
		def each(&block)
			@left.each(&block)
			yield [@key, @value]
			@right.each(&block)
		end

		def each_key
			each do |k, v|
				yield k
			end
		end

		def each_value
			each do |k, v|
				yield v
			end
		end

		def keys
			collect { |k, v| k }
		end

		def values
			collect { |k, v| v }
		end

		# returns new_root
		def insert(key, value)
			ret = self
			case key <=> @key
			when -1
				ret = ret.with_left(@left.insert(key, value))
				if ret.black? and ret.right.black? and ret.left.red? and !ret.left.children_color?(:black)
					ret = ret.rebalance_for_left_insert
				end
			when 0
				@value = value
			when 1
				ret = ret.with_right(@right.insert(key, value))
				if ret.black? and ret.left.black? and ret.right.red? and !ret.right.children_color?(:black)
					ret = ret.rebalance_for_right_insert
				end
			else
				raise TypeError, "cannot compare #{key} and #{@key} with <=>"
			end
			ret.pullup_red
		end

		# returns value
		def retrieve(key)
			case key <=> @key
			when -1
				@left.retrieve(key)
			when 0
				@value
			when 1
				@right.retrieve(key)
			else
				nil
			end
		end

		# returns [deleted_node, new_root, is_rebalance_needed]
		def delete(key)
			ret = self
			case key <=> @key
			when -1
				deleted, left, rebalance = @left.delete(key)
				ret = ret.with_left(left)
				if rebalance
					ret, rebalance = ret.rebalance_for_left_delete
				end
			when 0
				deleted = self
				ret, rebalance = delete_node
			when 1
				deleted, right, rebalance = @right.delete(key)
				ret = ret.with_right(right)
				if rebalance
					ret, rebalance = ret.rebalance_for_right_delete
				end
			else
				raise TypeError, "cannot compare #{key} and #{@key} with <=>"
			end
			[deleted, ret, rebalance]
		end

		def dump_tree(io, indent = '')
			@right.dump_tree(io, indent + '  ')
			io << indent << sprintf("#<%s:0x%010x %s %s> => %s", self.class.name, __id__, @color, @key.inspect, @value.inspect) << $/
			@left.dump_tree(io, indent + '  ')
		end

		def dump_sexp
			left = @left.dump_sexp
			right = @right.dump_sexp
			if left or right
				'(' + [@key, left || '-', right].compact.join(' ') + ')'
			else
				@key
			end
		end

		# for debugging
		def check_height
			lh = @left.nil?  || @left.empty? ? 0 : @left.check_height
			rh = @right.nil? || @right.empty? ? 0 : @right.check_height
			if red?
				if @left.red? or @right.red?
					puts dump_tree(STDERR)
					raise 'red/red assertion failed'
				end
			else
				if lh != rh
					puts dump_tree(STDERR)
					raise "black height unbalanced: #{lh} #{rh}"
				end
			end
			(lh > rh ? lh : rh) + (black? ? 1 : 0)
		end

	protected

		def children_color?(color)
			@right.color == @left.color && @right.color == color
		end

		def delete_min
			if @left.empty?
				[self, *delete_node]
			else
				ret = self
				deleted, @left, rebalance = @left.delete_min
				if rebalance
					ret, rebalance = rebalance_for_left_delete
				end
				[deleted, ret, rebalance]
			end
		end

		# trying to rebalance when the left sub-tree is 1 level lower than the right
		def rebalance_for_left_delete
			rebalance = false
			[if black?
				if @right.black?
					if @right.children_color?(:black)
						# make whole sub-tree 1 level lower and ask rebalance
						rebalance = true
						with_right(@right.with_color(:red))
					else
						# move 1 black from the right to the left by single/double rotation
						balanced_rotate_left
					end
				else
					# flip this sub-tree into another type of 3-children node
					ret = rotate_left
					# try to rebalance in sub-tree
					left, rebalance = ret.left.rebalance_for_left_delete
					raise 'should not happen' if rebalance
					ret.with_left(left)
				end
			else # red
				if @right.children_color?(:black)
					# make right sub-tree 1 level lower
					with_right(@right.with_color(color)).with_color(@right.color)
				else
					# move 1 black from the right to the left by single/double rotation
					balanced_rotate_left
				end
			end, rebalance]
		end

		# trying to rebalance when the right sub-tree is 1 level lower than the left
		# See rebalance_for_left_delete.
		def rebalance_for_right_delete
			rebalance = false
			[if black?
				if @left.black?
					if @left.children_color?(:black)
						rebalance = true
						with_left(@left.with_color(:red))
					else
						balanced_rotate_right
					end
				else
					ret = rotate_right
					right, rebalance = ret.right.rebalance_for_right_delete
					raise 'should not happen' if rebalance
					ret.with_right(right)
				end
			else # red
				if @left.children_color?(:black)
					with_left(@left.with_color(color)).with_color(@left.color)
				else
					balanced_rotate_right
				end
			end, rebalance]
		end

		# move 1 black from the right to the left by single/double rotation
		def balanced_rotate_left
			ret = self
			if @right.left.red? and @right.right.black?
				ret = with_right(@right.rotate_right)
			end
			ret = ret.rotate_left
			ret = ret.with_left(ret.left.with_color(:black))
			ret = ret.with_right(ret.right.with_color(:black))
			ret
		end

		# move 1 black from the left to the right by single/double rotation
		def balanced_rotate_right
			ret = self
			if @left.right.red? and @left.left.black?
				ret = with_left(@left.rotate_left)
			end
			ret = ret.rotate_right
			ret = ret.with_left(ret.left.with_color(:black))
			ret = ret.with_right(ret.right.with_color(:black))
			ret
		end

		# Right single rotation
		# (b a (D c E)) where D and E are red --> (d (B a c) E)
		#
		#   b              d
		#  / \            / \
		# a   D    ->    B   E
		#    / \        / \
		#   c   E      a   c
		#
		def rotate_left
			root = @right
			root = root.with_left(with_right(root.left))
			root.with_left(root.left.with_color(root.color)).with_color(root.left.color)
		end

		# Left single rotation
		# (d (B A c) e) where A and B are red --> (b A (D c e))
		#
		#     d          b
		#    / \        / \
		#   B   e  ->  A   D
		#  / \            / \
		# A   c          c   e
		#
		def rotate_right
			root = @left
			root = root.with_right(with_left(root.right))
			root.with_right(root.right.with_color(root.color)).with_color(root.right.color)
		end

		# Pull up red nodes
		# (b (A C)) where A and C are red --> (B (a c))
		#
		#   b          B
		#  / \   ->   / \
		# A   C      a   c
		#
		def pullup_red
			if black? and children_color?(:red)
				self
					.with_left(@left.with_color(:black))
					.with_right(@right.with_color(:black))
					.with_color(:red)
			else
				self
			end
		end

		# trying to rebalance when the left sub-tree is 1 level higher than the right
		# precondition: self is black and @left is red
		def rebalance_for_left_insert
			# move 1 black from the left to the right by single/double rotation
			if @left.right.red?
				with_left(@left.rotate_left)
			else
				self
			end.rotate_right
		end

		# trying to rebalance when the right sub-tree is 1 level higher than the left
		# See rebalance_for_left_insert.
		def rebalance_for_right_insert
			if @right.left.red?
				with_right(@right.rotate_right)
			else
				self
			end.rotate_left
		end

	private

		def delete_node
			rebalance = false
			if @left.empty? and @right.empty?
				# just remove this node and ask rebalance to the parent
				new_root = EMPTY
				if black?
					rebalance = true
				end
			elsif @left.empty? or @right.empty?
				# pick the single children
				new_root = @left.empty? ? @right : @left
				if black?
					# keep the color black
					raise 'should not happen' unless new_root.red?
					new_root = new_root.with_color(:black)
				else
					# just remove the red node
				end
			else
				# pick the minimum node from the right sub-tree and replace self with it
				deleted, @right, rebalance = @right.delete_min
				new_root = Node.new(deleted.key, deleted.value, @left, @right, @color)
				if rebalance
					new_root, rebalance = new_root.rebalance_for_right_delete
				end
			end
			[new_root, rebalance]
		end

		def collect
			pool = []
			each do |key, value|
				pool << yield(key, value)
			end
			pool
		end

		class EmptyNode < Node
			def initialize
				@value = nil
				@color = :black
			end

			def empty?
				true
			end

			def size
				0
			end

			def each(&block)
				# intentionally blank
			end

			# returns new_root
			def insert(key, value)
				Node.new(key, value, self, self)
			end

			# returns value
			def retrieve(key)
				UNDEFINED
			end

			# returns [deleted_node, new_root, is_rebalance_needed]
			def delete(key)
				[self, self, false]
			end

			def dump_tree(io, indent = '')
				# intentionally blank
			end

			def dump_sexp
				# intentionally blank
			end
		end
		EMPTY = Node::EmptyNode.new.freeze
	end

	DEFAULT = Object.new

	attr_accessor :default
	attr_reader :default_proc

	def initialize(default = DEFAULT, &block)
		if block && default != DEFAULT
			raise ArgumentError, 'wrong number of arguments'
		end
		@root = Node::EMPTY
		@default = default
		@default_proc = block
	end

	def root
		@root
	end

	def empty?
		root == Node::EMPTY
	end

	def size
		root.size
	end
	alias length size

	def each(&block)
		if block_given?
			root.each(&block)
			self
		else
			Enumerator.new(root)
		end
	end
	alias each_pair each

	def each_key
		if block_given?
			root.each do |k, v|
				yield k
			end
			self
		else
			Enumerator.new(root, :each_key)
		end
	end

	def each_value
		if block_given?
			root.each do |k, v|
				yield v
			end
			self
		else
			Enumerator.new(root, :each_value)
		end
	end

	def keys
		root.keys
	end

	def values
		root.values
	end

	def clear
		@root = Node::EMPTY
	end

	def []=(key, value)
		@root = @root.insert(key, value).as_root
		@root.check_height if $DEBUG
	end
	alias insert []=

	def key?(key)
		root.retrieve(key) != Node::UNDEFINED
	end
	alias has_key? key?

	def [](key)
		value = @root.retrieve(key)
		if value == Node::UNDEFINED
			default_value
		else
			value
		end
	end

	def delete(key)
		deleted, @root, rebalance = @root.delete(key)
		unless empty?
			@root = @root.as_root
			@root.check_height if $DEBUG
		end
		deleted.value
	end

	def dump_tree(io = '')
		root.dump_tree(io)
		io << $/
		io
	end

	def dump_sexp
		root.dump_sexp || ''
	end

	def to_hash
		inject({}) { |r, (k, v)| r[k] = v; r }
	end

private

	def default_value
		if @default != DEFAULT
			@default
		elsif @default_proc
			@default_proc.call
		else
			nil
		end
	end
end