
class ChessPiece 
	attr_accessor :color, :token, :current_square, :previous_square, :potential_moves, :first_move, :full_rom
	@@all = []; @@white = []; @@black = []

	def initialize(color, current_square)
		@color = color
		@current_square = current_square
		@previous_square = nil
		@potential_moves = []; @full_rom = []
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

	def self.clear
		@@all = []; @@white = []; @@black = []
	end

	def set_token(wt, bt)
		@token = (@color == "white" ? wt : bt)
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
		overlap = @potential_moves & same.map { |pc| pc.current_square }
		@potential_moves -= overlap
	end

	# Helper for setting rook, bishop, and queen moves
	def push_by_stops(stop_hash)
		stop_hash.map do |coord, stop| 
			@full_rom << coord if valid?(coord)
			unless stop.include? true
				@potential_moves << coord if valid?(coord)
			end
			stop << true if ChessPiece.occupies?(coord)
		end
	end

	def valid?(coord)
		coord.all? { |c| c.between?(0,7) } ? true : false
	end

	def self.occupies?(coord)
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
		@potential_moves = []; @full_rom = []
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
			kncoords.each { |coord| pm << coord if valid?(coord) }
		end
	end

	def set_moves
		@potential_moves = []; @full_rom = []
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
		@potential_moves = []; @full_rom = []
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
		@potential_moves = []; @full_rom = []
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
	attr_accessor :protection, :barred_squares, :oppcol
	@@wt = "♔"; @@bt = "♚"

	def initialize(color, current_square)
		super
		@first_move = true
		@protection = []; @barred_squares = []
		set_token(@@wt, @@bt)
		@oppcol = (@color == "white" ? @@black : @@white)
	end

	def set_moves 
		@potential_moves = []; @barred_squares = []; @full_rom = []
		determine_barred_squares
		set_moves_gen do |x, y, pm|
			kcoords = [[x, y+1], [x, y-1], [x+1, y], [x+1, y+1], 
				[x+1, y-1], [x-1, y], [x-1, y+1], [x-1, y-1]]
			kcoords.each { |coord| pushto_fullrom_pm(coord) }
			maybe_castle_move(pm, y) if @first_move and check? == false
			pawn_ahead?(x, y)
		end
	end

	def reassess_moves(pc)
		real_csquare = pc.current_square
		yield
		pc.current_square = real_csquare
	end

	def determine_barred_squares
		reassess_moves(self) do
			oppking = @oppcol.select { |pc| pc.class == King }[0]
			bar_squares(oppking)
		end
	end

	def bar_squares(oppking)
		(0..7).to_a.each do |x|
			(0..7).to_a.each do |y|
				@current_square = [x, y]
				@oppcol.each { |pc| pc.set_moves unless pc == oppking }
				@barred_squares << [x, y] if check? or oppking.full_rom.include? [x,y]
			end
		end
	end

	def pushto_fullrom_pm(coord)
		if valid?(coord)
			@full_rom << coord
			@potential_moves << coord unless @barred_squares.include? coord
		end
	end

	def pawn_ahead?(x, y)
		sides = [[x+1, y], [x-1, y]]
		ahead = (@color == "white" ? [x, y+1] : [x, y-1])
		if @oppcol.any? { |pc| pc.class == Pawn and pc.current_square == ahead }
			@potential_moves -= sides 
		end
	end

	def maybe_castle_move(pm, y)
		rooks = @@all.select { |pc| pc.class == Rook and pc.first_move and pc.color == @color }
		left = [1,2,3]
		right = [5,6]
		pm << [1, y] if rooks.any? { |pc| pc.current_square == [0, y] } and all_clear?(left, y)
		pm << [6, y] if rooks.any? { |pc| pc.current_square == [7, y] } and all_clear?(right, y)
	end

	def all_clear?(direction, y)
		direction.all? { |x| !(ChessPiece.occupies? [x, y]) and !(check? [x, y]) }
	end

	def check?(square=@current_square)
		@oppcol.any? { |pc| pc.potential_moves.include? square }
	end

	def checkmate? 
		if check?
			@potential_moves.all? { |coord| check? coord } and @protection.empty?
		else
			false
		end
	end

	def stalemate?
		samecol = (@color == "white" ? @@white : @@black)
		check? == false and samecol.all? { |pc| pc.potential_moves.empty? }
	end

	def assess_threats
		pts = @oppcol.select { |pc| pc.full_rom.include? @current_square }
		kingsmen = @@all.select { |pc| pc.color == @color and pc.class != King }
		check? ? protect_king(kingsmen) : address_potential_threats(kingsmen, pts)
	end

	def protect_king(kingsmen)
		@protection = []
		generate_protective_moves(kingsmen)
		@oppcol.each { |pc| pc.set_moves }
		kingsmen.each { |pc| pc.potential_moves = (pc.potential_moves & @protection) }
	end

	def generate_protective_moves(kingsmen)
		threats = @oppcol.select { |pc| pc.potential_moves.include? @current_square }
		kingsmen.each do |km|
			reassess_moves(km) { neutralize_threats(km, threats) }
		end
	end

	def neutralize_threats(pc, threats)
		threats.each do |thr|
			@protection << thr.current_square
			overlap = pc.potential_moves & thr.potential_moves
			process_overlap(overlap, pc, threats)
		end
	end

	def process_overlap(overlap, piece, threats)
		overlap.each do |coord|
			piece.current_square = coord
			threats.each { |pc| pc.set_moves }
			@protection << coord if check? == false
		end
	end

	def address_potential_threats(kingsmen, pts)
		kingsmen.each do |km|
			if pts.any? { |pt| pt.potential_moves.include? km.current_square }
				reassess_moves(km) { prevent_threat(km, pts) }
				pts.each { |pt| pt.set_moves }
			end
		end
	end

	def prevent_threat(km, pts)
		can_move_to = []
		km.potential_moves.each do |coord|
			km.current_square = coord
			pts.each { |pt| pt.set_moves }
			can_move_to << coord if check? == false
		end
		km.potential_moves = can_move_to
	end

	def assess_threats
		pts = @oppcol.select { |pc| pc.full_rom.include? @current_square }
		kingsmen = @@all.select { |pc| pc.color == @color and pc.class != King }
		check? ? protect_king(kingsmen) : address_potential_threats(kingsmen, pts)
	end
end