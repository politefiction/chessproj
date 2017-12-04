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

	def turn
		puts
		puts "#{@color.capitalize}\'s turn. Where is the piece you'd like to move? (e.g., 'A4', 'G2', etc.): "
		fromalpha = gets.chomp.downcase
		case fromalpha
		when "resign"
			confirm_resignation
		when "draw"
			confirm_draw
		when "save"
			yield
		else
			complete_turn(fromalpha)
		end
	end

	def save
	end

	def confirm_resignation
		puts "Would #{@color.capitalize} like to resign? (Y/N)"
		answer = gets.chomp.downcase
		@color == "white" ? oppcol = "Black" : oppcol = "White"
		if answer[0] == "y"
			puts "#{@color.capitalize} has resigned. #{oppcol} wins!"
			exit
		end
	end

	def confirm_draw
		puts "Would #{@color.capitalize} like to draw? (Y/N)"
		answer = gets.chomp.downcase
		@color == "white" ? oppcol = "black" : oppcol = "white"
		if answer[0] == "y"
			block_given? ? yield : confirm_with_opponent(oppcol)
		end
	end

	def confirm_with_opponent(oppcol)
		puts "Does #{oppcol.capitalize} agree to a draw?"
		response = gets.chomp.downcase
		if response[0] == "y"
			yield if block_given?
			puts "Both players have agreed to a draw. Game over."
			exit
		end
	end

	def complete_turn(fromalpha)
		from = convert_coord(fromalpha) 
		if @pieces.any? { |pc| pc.current_square == from }
			make_move(from)
		else
			puts error_message(from); turn
		end
	end

	def convert_coord(coord)
		split_coord = coord.downcase.split(//)
		num_coord = []
		unless coord.empty?
			if split_coord[0].between?('a','h') and split_coord[1].to_i.between?(1,8)
				('a'..'h').to_a.each_with_index { |ltr, i| num_coord << i if ltr == split_coord[0] }
				num_coord << (split_coord[1].to_i - 1); num_coord
			else
				false
			end
		else
			false
		end
	end

	def make_move(from)
		piece = @pieces.select { |pc| pc.current_square == from }[0]
		if !piece.potential_moves.empty?
			puts "Where would you like to move this piece?"
			toalpha = gets.chomp; to = convert_coord(toalpha)
			move_piece(from, to)
		else
			puts "This piece has no available moves. Please choose another piece."; turn
		end
	end

	def move_piece(from, to)
		movepc = @pieces.select { |pc| pc.current_square == from }[0]; captured_piece = false
		if movepc.potential_moves.include? to
			captured_piece = capture(to) if ChessPiece.occupies? to
			process_special_cases(movepc, to)
			movepc = @pieces[-1] if pawn_promotion?(movepc, to)
			reset_movepc(movepc, to, from)
			track_player_moves(movepc, captured_piece)
		else
			offer_hint(movepc)
		end
	end

	def capture(to)
		oppospc = ChessPiece.all.select { |pc| pc.current_square == to }[0]
		oppospc.previous_square = to; oppospc.nullify
		@captured << oppospc
		true
	end

	def process_special_cases(movepc, to)
		castling?(to) if movepc == @king
		movepc.first_move = false if movepc.class == (Pawn || Rook || King)
		assign_promotion(movepc, to) if pawn_promotion?(movepc, to)
	end

	def castling?(to)
		y = @king.current_square[1]
		rook1 = ChessPiece.all.select { |pc| pc.class == Rook and pc.current_square == [0, y] }[0]
		rook2 = ChessPiece.all.select { |pc| pc.class == Rook and pc.current_square == [7, y] }[0]
		if @king.first_move
			(rook1.current_square = [2,y] if to == [1,y]) if @king.potential_moves.include? [1,y]
			(rook2.current_square = [5,y] if to == [6,y]) if @king.potential_moves.include? [6,y]
		end
	end

	def pawn_promotion?(movepc, to)
		if movepc.class == Pawn
			prosquare = (movepc.color == "white" ? 7 : 0)
			to[1] == prosquare ? true : false
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

	def reset_movepc(movepc, to, from)
		movepc.previous_square = from
		movepc.current_square = to
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

	def offer_hint(movepc)
		puts "Invalid move. Would you like to see potential moves? (Y/N)"
		answer = gets.chomp.downcase
		puts hint(movepc) if answer[0] == "y"; turn
	end

	def hint(movepc)
		alphanums = []
		movepc.potential_moves.each do |coord|
			anc = ""
			('a'..'h').to_a.each_with_index { |ltr, i| anc << ltr.upcase if coord[0] == i }
			anc << (coord[1]+1).to_s
			alphanums << anc
		end
		"Potential moves for #{movepc.class}: #{alphanums.join(", ")}"
	end

	def error_message(from)
		if from == false
			"That entry is not valid. Please try again."
		else
			"Please choose a square occupied by a #{@color} piece."
		end
	end

	def subtract_captured_by(opplayer)
		@pieces -= opplayer.captured
	end
end
