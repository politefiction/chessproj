
# Attributes and methods common(ish) to all pieces
class ChessPiece 
	attr_accessor :color, :token, :current_square, :potential_moves, :first_move
	@@all = []; @@white = []; @@black = []

	def initialize(color, current_square)
		@color = color
		@current_square = current_square
		@potential_moves = []
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

	# Clears the board for a new game
	def self.clear
		@@all = []; @@white = []; @@black = []
	end

	def set_token(wt, bt)
		@color == "white" ? @token = wt : @token = bt
	end 

	def set_moves_gen
		x = @current_square[0]; y = @current_square[1]
		pm = @potential_moves
		yield(x, y, pm)
		pm.compact!
		overlap_wt = pm & @@white.map { |pc| pc.current_square }
		overlap_bk = pm & @@black.map { |pc| pc.current_square }
		@color == "white" ? @potential_moves -= overlap_wt : @potential_moves -= overlap_bk
	end

	# Helper for setting rook, bishop, and queen moves
	def push_by_stops(stop_hash)
		stop_hash.map do |coord, stop| 
			unless stop.include? true
				@potential_moves << coord if coord.all? { |c| c.between?(0,7) }
			end
			stop << true if ChessPiece.occupies?(coord)
		end
	end

	def self.occupies? (coord)
		occupied = @@all.map { |pc| pc.current_square }
		occupied.include? coord
	end

	def nullify
		self.current_square = nil; self.color = nil; self.potential_moves = nil
	end
end

class Pawn < ChessPiece 
	@@wt = "♙"; @@bt = "♟"

	def initialize(color, current_square)
		super
		@first_move = true
		set_token(@@wt, @@bt) 
	end

	def set_moves
		@potential_moves = []
		set_moves_gen do |x, y, pm|
			@color == "white" ? (n = 1; b = 2) : (n = -1; b = -2)
			unless ChessPiece.occupies? [x, y+n]
				pm << [x, y+n] if (y+n).between?(0,7) 
				pm << ([x, y+b] if @first_move) unless ChessPiece.occupies? [x, y+b]
			end
			[[x+1, y+n], [x-1, y+n]].each { |crd| pm << crd if ChessPiece.occupies? crd }
		end
	end
end

class Rook < ChessPiece
	@@wt = "♖"; @@bt = "♜"

	def initialize(color, current_square)
		super
		@first_move = true
		set_token(@@wt, @@bt) 
	end

	def set_moves
		@potential_moves = []
		set_moves_gen do |x, y, pm|
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
		set_moves_gen do |x, y, pm|
			kncoords = [[x+a, y+b], [x+a, y-b], [x-a, y+b], [x-a, y-b]]
			kncoords.each { |coord| pm << coord if coord.all? { |c| c.between?(0,7) } }
		end
	end

	def set_moves
		@potential_moves = []
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

	def set_moves
		@potential_moves = []
		set_moves_gen do |x, y, pm|
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

	def set_moves
		@potential_moves = []
		set_moves_gen do |x, y, pm|
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
	attr_accessor :checkmate, :protection
	@@wt = "♔"; @@bt = "♚"

	def initialize(color, current_square)
		super
		@first_move = true
		@checkmate = false
		@protection = []
		set_token(@@wt, @@bt)
	end

	def set_moves 
		@potential_moves = []
		set_moves_gen do |x, y, pm|
			kcoords = [[x, y+1], [x, y-1], [x+1, y], [x+1, y+1], [x+1, y-1], [x-1, y], [x-1, y+1], [x-1, y-1]]
			kcoords.each do |coord| 
				(pm << coord if coord.all? { |c| c.between?(0,7) }) unless check? coord
			end
			can_castle?(pm, y) if @first_move and check? == false
		end
	end

	def can_castle? (pm, y)
		rooks = @@all.select { |pc| pc.class == Rook and pc.first_move == true and pc.color == @color }
		if rooks.any? { |pc| pc.current_square == [0, y] }
			pm << [1, y] if [1,2,3].all? { |x| !(ChessPiece.occupies? [x, y]) and !(check? [x, y]) }
		end
		if rooks.any? { |pc| pc.current_square == [7, y] }
			pm << [6, y] if [5,6].all? { |x| !(ChessPiece.occupies? [x, y]) and !(check? [x, y]) }
		end
	end

	def check? (square=@current_square)
		if @color == "white"
			@@black.any? { |pc| pc.potential_moves.include? square } ? true : false
		else
			@@white.any? { |pc| pc.potential_moves.include? square } ? true : false
		end
	end

	def checkmate?
		if check?
			@checkmate = true if @potential_moves.all? { |coord| check? coord } and @protection.empty?
		end
		@checkmate
	end

	def protect_king
		@protection = []
		@color == "white" ? oppcol = @@black : oppcol = @@white
		oppcol.select { |pc| pc.potential_moves.include? @current_square }.each { |pc| @protection << pc.current_square }
		@@all.select { |pc| pc.color == @color and pc.class != King }.each do |pc|
			pc.potential_moves.each do |coord|
				move = ChessPiece.new(@color, coord)
				oppcol.each { |pc| pc.set_moves }
				@protection << coord if check? == false unless @protection.include? coord
				move.nullify
			end
			pc.potential_moves = (pc.potential_moves & @protection)
		end
	end
end

=begin
rook = Rook.new("white", [0, 3])
bishop = Bishop.new("black", [7, 3])
king = King.new("white", [4, 0])
pawn = Pawn.new("white", [6, 0])
bishop2 = Bishop.new("white", [4, 4])

2.times { ChessPiece.all.each { |pc| pc.set_moves unless pc.current_square == nil } }
king.protect_king if king.check?

#p king.potential_moves
p pawn.potential_moves
p rook.potential_moves
p bishop2.potential_moves


#p king.check?
#ChessPiece.all.each { |pc| puts pc.inspect unless pc.current_square == nil }
#p ChessPiece.all



=begin

what if I tried with the black (well, opposing) pieces?
-go through each black piece's potential moves
-see if moving there would result in check of white's king
-if so, push that square to, idk, a 'threatened' array
-match that array against white pieces (except king); subtract any potential moves that don't match
-no, the test pieces would need to have same set of moves as threatening piece

=end