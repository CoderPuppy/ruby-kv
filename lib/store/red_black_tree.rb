require File.expand_path("../../store", __FILE__)
require File.expand_path("../../red_black_tree", __FILE__)

class Store::RedBlackTree < Store
	def initialize
		@tree = ::RedBlackTree.new
	end

	def apply batch
		batch.each do |k, v|
			@tree.delete k
			unless v == nil
				@tree[k] = v
			end
		end
		self
	end

	def get key
		@tree[key]
	end

	def _range from, to
		n = @tree.root
		stack = []
		while n && !n.empty?
			break unless n.key
			d = from <=> n.key
			stack << n
			if d <= 0
				n = n.left
			else
				n = n.right
			end
		end
		Enumerator.new do |out|
			loop do
				break if stack.empty?
				n = stack.last
				break if n.key > to
				out << [n.key, n.value] if n.key >= from
				if n.right && !n.right.empty?
					n = n.right
					while n && !n.empty?
						stack << n
						n = n.left
					end
				else
					stack.pop
					while stack.length > 0 && stack.last.right == n
						n = stack.last
						stack.pop
					end
				end
			end
		end
	end

	def dup
		new = super
		new.instance_variable_set :@tree, @tree.dup
		new
	end
end