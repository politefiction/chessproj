
# Keeps track of each piece's current square and potential moves
class MoveSet
	attr_accessor :current_square, :potential_moves

	def initialize(current_square, potential_moves=[])
		@current_square = current_square
		@potential_moves = potential_moves
	end
end

# Attributes and methods common(ish) to all pieces
class ChessPiece 
	attr_accessor :color, :move_set, :token
	@@all = []; @@white = []; @@black = []

	def initialize(color, current_square)
		@color = color
		@move_set = MoveSet.new(current_square)
		@@all << self
		@color == "white" ? @@white << self : @@black << self
	end

	def self.all 
		@@all
	end 

	def self.white
		@@white
	end

	def self.black
		@@black
	end

	def set_token(wt, bt)
		@color == "white" ? @token = wt : @token = bt
	end 

	def set_moves
		x = @move_set.current_square[0]; y = @move_set.current_square[1]
		pm = @move_set.potential_moves
		yield(x, y, pm)
		pm.compact!
		overlap_wt = pm & @@white.map { |pc| pc.move_set.current_square }
		overlap_bk = pm & @@black.map { |pc| pc.move_set.current_square }
		@color == "white" ? @move_set.potential_moves -= overlap_wt : @move_set.potential_moves -= overlap_bk
	end

	# Helper for setting rook, bishop, and queen moves
	def push_by_stops(stop_hash)
		stop_hash.map do |coord, stop| 
			unless stop.include? true
				@move_set.potential_moves << (coord if coord[0].between?(0,7) and coord[1].between?(0,7))
			end
			stop << true if occupied?(coord)
		end
	end

	def occupied? (coord)
		occupied = @@all.map { |pc| pc.move_set.current_square }
		occupied.include? coord
	end
end


class Pawn < ChessPiece 
	attr_accessor :first_move
	@@wt = "♙"; @@bt = "♟"

	def initialize(color, current_square)
		super
		@first_move = true
		set_token(@@wt, @@bt) 
	end

	def pawn_moves
		@move_set.potential_moves = []
		set_moves do |x, y, pm|
			if @color == "white"
				(pm << ([x, y+1] if y+1 < 8) << (([x, y+2] if @first_move) unless occupied? [x, y+2])) unless occupied? [x, y+1]
				[[x+1, y+1], [x-1, y+1]].each { |coord| pm << coord if occupied? coord }
			else
				(pm << ([x, y-1] if y-1 >= 0) << (([x, y-2] if @first_move) unless occupied? [x, y-2])) unless occupied? [x, y-1]
				[[x+1, y-1], [x-1, y-1]].each { |coord| pm << coord if occupied? coord }
			end
		end
	end
end

class Rook < ChessPiece
	attr_accessor :first_move
	@@wt = "♖"; @@bt = "♜"

	def initialize(color, current_square)
		super
		@first_move = true
		set_token(@@wt, @@bt) 
	end

	def rook_moves
		@move_set.potential_moves = []
		set_moves do |x, y, pm|
			estop = [false]; wstop = [false]; nstop = [false]; sstop = [false]
			(1..7).to_a.map do |n|
				rstops = { [x+n, y]=>estop, [x-n, y]=>wstop, [x, y+n]=>nstop, [x, y-n]=>sstop }
				push_by_stops(rstops)
			end
		end
	end
end

class Knight < ChessPiece
	@@wt = "♘"; @@bt = "♞"
	
	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
	end

	def knight_base(a, b)
		set_moves do |x, y, pm|
			kncoords = [[x+a, y+b], [x+a, y-b], [x-a, y+b], [x-a, y-b]]
			kncoords.each { |coord| pm << coord if coord[0].between?(0,7) and coord[1].between?(0,7) }
		end
	end

	def knight_moves
		@move_set.potential_moves = []
		knight_base(1, 2)
		knight_base(2, 1)
	end
end

class Bishop < ChessPiece
	@@wt = "♗"; @@bt = "♝"

	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
	end

	def bishop_moves
		@move_set.potential_moves = []
		set_moves do |x, y, pm|
			nestop = [false]; nwstop = [false]; sestop = [false]; swstop = [false]
			(1..7).to_a.each do |n|
				bstops = { [x+n, y+n]=>nestop, [x+n, y-n]=>nwstop, [x-n, y+n]=>sestop, [x-n, y-n]=>swstop }
				push_by_stops(bstops)
			end
		end
	end
end

class Queen < ChessPiece
	@@wt = "♕"; @@bt = "♛"

	def initialize(color, current_square)
		super
		set_token(@@wt, @@bt)
	end

	def queen_moves
		@move_set.potential_moves = []
		set_moves do |x, y, pm|
			estop = [false]; wstop = [false]; nstop = [false]; sstop = [false]
			nestop = [false]; nwstop = [false]; sestop = [false]; swstop = [false]
			(1..7).to_a.each do |n|
				qstops = { [x+n, y]=>estop, [x-n, y]=>wstop, [x, y+n]=>nstop, [x, y-n]=>sstop, 
					[x+n, y+n]=>nestop, [x+n, y-n]=>nwstop, [x-n, y+n]=>sestop, [x-n, y-n]=>swstop }
				push_by_stops(qstops)
			end
		end
	end
end

class King < ChessPiece
	attr_accessor :check, :checkmate, :first_move
	@@wt = "♔"; @@bt = "♚"

	def initialize(color, current_square)
		super
		@first_move = true
		@checkmate = false
		set_token(@@wt, @@bt)
	end

	def king_moves 
		@move_set.potential_moves = []
		set_moves do |x, y, pm|
			kcoords = [[x, y+1], [x, y-1], [x+1, y], [x+1, y+1], [x+1, y-1], [x-1, y], [x-1, y+1], [x-1, y-1]]
			kcoords.each do |coord| 
				(pm << coord if coord[0].between?(0,7) and coord[1].between?(0,7)) unless check? coord
			end
			castle?(pm, y) if @first_move and check? == false
		end
	end

	def castle? (pm, y)
		rooks = @@all.select { |pc| pc.class == Rook and pc.first_move == true and pc.color == @color }
		if rooks.any? { |pc| pc.move_set.current_square == [0, y] }
			pm << [1, y] if [1,2,3].all? { |x| !(occupied? [x, y]) and !(check? [x, y]) }
		elsif rooks.any? { |pc| pc.move_set.current_square == [7, y] }
			pm << [6, y] if [5,6].all? { |x| !(occupied? [x, y]) and !(check? [x, y]) }
		end
	end

	def check? (square=@move_set.current_square)
		if @color == "white"
			@@black.any? { |pc| pc.move_set.potential_moves.include? square } ? true : false
		else
			@@white.any? { |pc| pc.move_set.potential_moves.include? square } ? true : false
		end
	end

	def checkmate?
		if check?
			@checkmate = true if @move_set.potential_moves.all? { |coord| check? coord }
		end
		@checkmate
	end
end

