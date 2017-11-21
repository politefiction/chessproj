require_relative 'pieces'

class Player
	attr_accessor :color, :pieces, :king, :captured, :move_history
	@@move_count = 0

	def initialize(color)
		@color = color
		@pieces = []; @king = nil
		@captured = []; @move_history = []
		@color == "white" ? generate_pieces(0, 1) : generate_pieces(7, 6)
	end

	def generate_pieces(a, b)
		@pieces << Queen.new(@color, [3, a]) << King.new(@color, [4, a])
		[0, 7].each { |x| @pieces << Rook.new(@color, [x, a]) }
		[1, 6].each { |x| @pieces << Knight.new(@color, [x,a]) }
		[2, 5].each { |x| @pieces << Bishop.new(@color, [x, a]) }
		(0..7).to_a.each { |x| @pieces << Pawn.new(@color, [x, b]) }
		@king = @pieces.select { |pc| pc.class == King }[0]
	end


	def generate_moves 
		@pieces.each { |pc| pc.set_moves }
	end

	def convert_coord(coord)
		split_coord = coord.downcase.split(//)
		num_coord = []
		unless coord.empty?
			if split_coord[0].between?('a','h') and split_coord[1].to_i.between?(1,8)
				('a'..'h').to_a.each_with_index { |n, i| num_coord << i if n == split_coord[0] }
				num_coord << (split_coord[1].to_i - 1); num_coord
			else
				false
			end
		end
	end

	def capture_piece(to, captured_piece)
		oppospc = ChessPiece.all.select { |pc| pc.current_square == to }[0]
		oppospc.previous_square = to; oppospc.nullify
		captured_piece = true; @captured << oppospc
	end

	def subtract_captured_by(opplayer)
		@pieces -= opplayer.captured
	end

	def castling?(king, to)
		y = king.current_square[1]
		rook1 = ChessPiece.all.select { |pc| pc.class == Rook and pc.current_square == [0, y] }[0]
		rook2 = ChessPiece.all.select { |pc| pc.class == Rook and pc.current_square == [7, y] }[0]
		if king.first_move
			(rook1.current_square = [2,y] if to == [1,y]) if king.potential_moves.include? [1,y]
			(rook2.current_square = [5,y] if to == [6,y]) if king.potential_moves.include? [6,y]
		end
	end

	def assign_promotion(movepc, to)
		puts "Which promotion would you like for your pawn: 1) Rook, 2) Bishop, 3) Knight or 4) Queen?"
		answer = gets.chomp.downcase
		case answer
		when "rook", "1"
			@pieces << Rook.new(@color, to); movepc.nullify
		when "bishop", "2"
			@pieces << Bishop.new(@color, to); movepc.nullify
		when "knight", "3"
			@pieces << Knight.new(@color, to); movepc.nullify
		when "queen", "4"
			@pieces << Queen.new(@color, to); movepc.nullify
		else
			puts "That option is not available. Please try again."; assign_promotion(movepc, to)
		end
	end

	def pawn_promotion?(movepc, to)
		if movepc.class == Pawn
			prosquare = (movepc.color == "white" ? 7 : 0)
			to[1] == prosquare ? true : false
		end
	end

	def process_special_cases(movepc, to)
		castling?(movepc, to) if movepc.class == King
		movepc.first_move = false if movepc.class == (Pawn || Rook || King)
		if pawn_promotion?(movepc, to)
			assign_promotion(movepc, to)
		end
	end

	def hint(movepc)
		alphanums = []
		movepc.potential_moves.each do |coord|
			anc = ""
			('a'..'h').to_a.each_with_index { |ltr, i| anc << ltr.upcase if coord[0] == i }
			anc << (coord[1]+1).to_s
			alphanums << anc
		end
		puts "Potential moves for #{movepc.class}: #{alphanums.join(", ")}"
	end

	def offer_hint(movepc)
		puts "Invalid move. Would you like to see potential moves? (Y/N)"
		answer = gets.chomp.downcase
		hint(movepc) if answer[0] == "y"; turn
	end

	def move_piece(from, to)
		movepc = @pieces.select { |pc| pc.current_square == from }[0]; captured_piece = false
		if movepc.potential_moves.include? to
			capture_piece(to, captured_piece) if ChessPiece.occupies? to
			process_special_cases(movepc, to); movepc = @pieces[-1] if pawn_promotion?(movepc, to)
			movepc.previous_square = from; movepc.current_square = to
			track_player_moves(movepc, captured_piece)
		else
			offer_hint(movepc)
		end
	end

	def track_player_moves(movepc, captured_piece)
		@move_history << {
			move_num: @@move_count += 1,
			moved: movepc,
			from: movepc.previous_square,
			to: movepc.current_square,
			captured_piece: captured_piece
		}
	end

	def confirm_draw
		puts "Would #{@color.capitalize} like to draw? (Y/N)"
		answer = gets.chomp.downcase
		@color == "white" ? oppcol = "black" : oppcol = "white"
		if answer[0] == "y"
			if block_given?
				yield
			else
				puts "Does #{oppcol.capitalize} agree to a draw?"
				response = gets.chomp.downcase
				if response[0] == "y"
					puts "Both players have agreed to a draw. Ganme over."
					exit
				end
			end
		end
	end

	def confirm_resignation
		puts "Would #{@color.capitalize} like to resign? (Y/N)"
		answer = gets.chomp.downcase
		@color == "white" ? oppcol = "black" : oppcol = "white"
		if answer[0] == "y"
			puts "#{@color.capitalize} has resigned. #{oppcol.capitalize} wins!"
			exit
		end
	end

	def turn
		puts "#{@color.capitalize}\'s turn. Where is the piece you'd like to move? (e.g., 'A4', 'G2', etc.): "
		fromalpha = gets.chomp.downcase
		if fromalpha == "resign"
			confirm_resignation
		elsif fromalpha == "draw"
			confirm_draw
		else
			from = convert_coord(fromalpha) 
			if @pieces.any? { |pc| pc.current_square == from }
				piece = @pieces.select { |pc| pc.current_square == from }[0]
				if !piece.potential_moves.empty?
					puts "Where would you like to move this piece?"
					toalpha = gets.chomp; to = convert_coord(toalpha)
					move_piece(from, to)
				else
					puts "This piece has no available moves. Please choose another piece."; turn
				end
			else
				puts from == false ? "That coordinate is not valid. Please try again." : "Please choose a square occupied by a #{@color} piece."
				turn
			end
		end
	end
end


=begin
player1 = Player.new("white")
player2 = Player.new("black")
bpawn = Pawn.new("black", [3,1])
player2.pieces << bpawn

p player2.process_special_cases(bpawn, [3,0])
p player2.pieces[-1]

=begin

2.times {[player1, player2].each { |player| player.generate_moves }}


p bpawn.potential_moves
p player1.king.current_square
puts
p player1.king.check?


=begin
player2.pieces.each { |pc| puts "#{pc.class}: #{pc.potential_moves}"}

2.times { [player1, player1].each { |p| p.generate_moves } }

player1.move_piece([2,1], [2,3]); [player1, player2].each { |player| player.generate_moves }
player2.move_piece([3,6], [3,4]); [player1, player2].each { |player| player.generate_moves }
p player2.move_history
puts
player1.move_piece([2,3], [3,4]); player2.subtract_captured_by(player1)
#p player2.pieces[8..-1].each { |pc| pc.set_moves }
#[player1, player2].each { |player| player.generate_moves }
p player1.move_history
puts
p player2.move_history

=end 
