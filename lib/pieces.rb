#require_relative 'board'

# Attributes and methods common(ish) to all pieces
class ChessPiece 
	attr_accessor :color, :token, :current_square, :previous_square, :potential_moves, :first_move
	@@all = []; @@white = []; @@black = []

	def initialize(color, current_square)
		@color = color
		@current_square = current_square
		@previous_square = nil
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
		unless @current_square == nil
			x = @current_square[0]; y = @current_square[1]; pm = @potential_moves
			yield(x, y, pm)
			pm.compact!
			@color == "white" ? subtract_overlap(@@white, @@black) : subtract_overlap(@@black, @@white)
		end
	end

	def subtract_overlap(same, opp)
		overlap = @potential_moves & same.map do |pc| 
			pc.current_square
		end
		@potential_moves -= overlap
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
		self.current_square = nil
		self.color = nil
		self.potential_moves = nil
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
	attr_accessor :checkmate, :protection, :full_rom, :barred_squares
	@@wt = "♔"; @@bt = "♚"

	def initialize(color, current_square)
		super
		@first_move = true
		@checkmate = false
		@protection = []; @barred_squares = []; @full_rom = []
		set_token(@@wt, @@bt)
	end

	def set_moves 
		@potential_moves = []; @barred_squares = []; @full_rom = []
		determine_barred_squares
		set_moves_gen do |x, y, pm|
			kcoords = [[x, y+1], [x, y-1], [x+1, y], [x+1, y+1], [x+1, y-1], [x-1, y], [x-1, y+1], [x-1, y-1]]
			kcoords.each { |coord| pushto_fullrom_pm(coord) }
			can_castle?(pm, y) if @first_move and check? == false
			pawn_ahead?(x, y)
		end
	end

	def determine_barred_squares
		real_csquare = @current_square
		oppcol = (@color == "white" ? @@black : @@white)
		oppking = oppcol.select { |pc| pc.class == King }[0]
		bar_squares(oppcol, oppking)
		@current_square = real_csquare
	end

	def bar_squares(oppcol, oppking)
		(0..7).to_a.each do |x|
			(0..7).to_a.each do |y|
				@current_square = [x, y]
				oppcol.each { |pc| pc.set_moves unless pc == oppking }
				@barred_squares << [x, y] if check? or oppking.full_rom.include? [x,y]
			end
		end
	end

	def pushto_fullrom_pm(coord)
		if coord.all? { |c| c.between?(0,7) }
			@full_rom << coord
			@potential_moves << coord unless @barred_squares.include? coord
		end
	end

	def pawn_ahead?(x, y)
		sides = [[x+1, y], [x-1, y]]
		oppcol = (@color == "white" ? @@black : @@white)
		ahead = (@color == "white" ? [x, y+1] : [x, y-1])
		@potential_moves -= sides if oppcol.any? { |pc| pc.class == Pawn and pc.current_square == ahead }
	end

	def can_castle?(pm, y)
		rooks = @@all.select { |pc| pc.class == Rook and pc.first_move == true and pc.color == @color }
		left = [1,2,3]
		right = [5,6]
		pm << [1, y] if rooks.any? { |pc| pc.current_square == [0, y] } and all_clear?(left, y)
		pm << [6, y] if rooks.any? { |pc| pc.current_square == [7, y] } and all_clear?(right, y)
	end

	def all_clear? (direction, y)
		direction.all? { |x| !(ChessPiece.occupies? [x, y]) and !(check? [x, y]) }
	end

	def check? (square=@current_square)
		oppcol = (@color == "white" ? @@black : @@white)
		if oppcol.any? { |pc| pc.potential_moves.include? square }
			true
		else
			false
		end
	end

	def checkmate?
		if check?
			@checkmate = true if @potential_moves.all? { |coord| check? coord } and @protection.empty?
		end
		@checkmate
	end

	def stalemate?
		@color == "white" ? team = @@white : team = @@black
		(check? == false and team.all? { |pc| pc.potential_moves.empty? }) ? true : false
	end

	def protect_king 
		@protection = []
		samecol = @@all.select { |pc| pc.color == @color }
		oppcol = @@all.select { |pc| pc.color != @color }
		generate_protective_moves(samecol, oppcol)
		samecol.select { |pc| pc.class != King }.each do |pc|
			pc.potential_moves = (pc.potential_moves & @protection)
		end
	end

	def generate_protective_moves (samecol, oppcol)
		oppcol.select { |pc| pc.potential_moves.include? @current_square }.each { |pc| @protection << pc.current_square }
		samecol.select { |pc| pc.class != King }.each do |pc|
			real_csquare = pc.current_square
			pc.potential_moves.each do |coord|
				unless @protection.include? coord
					pc.current_square = coord
					oppcol.each { |pc| pc.set_moves }
					@protection << coord if check? == false
				end
			end
			pc.current_square = real_csquare
		end
	end
end


# Unsure of how to optimize protect_king method; may fix at later date.

=begin

king2 = King.new("black", [4, 7])
king = King.new("white", [4,0])
pawn = Pawn.new("black", [4,1])
2.times { [king, king2, pawn].each { |pc| pc.set_moves  } }
p pawn.potential_moves
p king.potential_moves


=begin
#puts 
p "Can occupy: #{king.potential_moves}"
p "Can't occupy: #{king.barred_squares}"
p "Current square: #{king.current_square}"
puts
p king.stalemate?

pawn = Pawn.new("black", [4,1])
king = King.new("white", [4,0])
king2 = King.new("black", [4,2])

[pawn, king, king2].each { |pc| pc.set_moves }
p king.potential_moves
p king.full_rom

p king2.potential_moves
p king2.full_rom

		elsif oppcol.any? { |pc| pc.potential_moves.include? square and pc.current_square[0] != square[0] }
			true

=end