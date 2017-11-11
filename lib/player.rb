require_relative 'pieces'

class Player
	attr_accessor :color, :pieces, :captured, :move_history
	@@move_count = 0

	def initialize(color)
		@color = color
		@pieces = []; @captured = []; @move_history = []
		@color == "white" ? generate_pieces(0, 1) : generate_pieces(7, 6)
	end

	def generate_pieces(a, b)
		@pieces << Queen.new(@color, [3, a]) << King.new(@color, [4, a])
		[0, 7].each { |x| @pieces << Rook.new(@color, [x, a]) }
		[1, 6].each { |x| @pieces << Knight.new(@color, [x,a]) }
		[2, 5].each { |x| @pieces << Bishop.new(@color, [x, a]) }
		(0..7).to_a.each { |x| @pieces << Pawn.new(@color, [x, b]) }
	end


	def generate_moves 
		@pieces.each { |pc| pc.set_moves }
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

	def pawn_promotion?(movepc, to)
		if (movepc.color == "white" and to[1] == 7) or (movepc.color == "black" and to[1] == 0)
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
				puts "That option is not available. Please try again."; turn
			end
		end
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

	def hint(movepc)
		alphanums = []
		movepc.potential_moves.each do |coord|
			anc = ""
			('a'..'h').to_a.each_with_index { |let, i| anc << let.upcase if coord[0] == i }
			anc << (coord[1]+1).to_s
			alphanums << anc
		end
		puts "Potential moves for #{movepc.class}: #{alphanums.join(", ")}"
	end

	def move_piece(from, to)
		movepc = @pieces.select { |pc| pc.current_square == from }[0]; captured_piece = false
		if movepc.potential_moves.include? to
			if ChessPiece.occupies? to
				oppospc = ChessPiece.all.select { |pc| pc.current_square == to }[0]
				oppospc.previous_square = to; oppospc.nullify
				captured_piece = true; @captured << oppospc
			end
			castling?(movepc, to) if movepc.class == King
			movepc.previous_square = from; movepc.current_square = to
			track_player_moves(movepc, captured_piece)
			pawn_promotion?(movepc, to) if movepc.class == Pawn
			movepc.first_move = false if movepc.class == (Pawn || Rook || King)
		else
			puts "Invalid move. Would you like to see potential moves? (Y/N)"
			answer = gets.chomp.downcase
			hint(movepc) if answer[0] == "y"; turn
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

	def subtract_captured_by(opplayer)
		@pieces -= opplayer.captured
	end

	def turn
		puts "#{@color.capitalize}\'s turn. Where is the piece you'd like to move? (e.g., 'A4', 'G2', etc.): "
		fromalpha = gets.chomp; from = convert_coord(fromalpha)
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

=begin
player1 = Player.new("white")
player2 = Player.new("black")
player1.generate_moves
player2.generate_moves

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
