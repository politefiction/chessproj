require_relative 'board'
require_relative 'pieces'
require_relative 'player'

# Notes:
# King protection stuff appears to be working now. Castling move fixed.
# Pawn promotion added.
# Need draw conditions.


class ChessGame
	attr_accessor :board, :player1, :player2

	def initialize
		ChessPiece.clear
		@board = ChessBoard.new
		@player1 = Player.new("white")
		@player2 = Player.new("black")
		pieces_on_board
	end

	def pieces_on_board
		@board.squares.each do |sq|
			ChessPiece.all.each do |pc|
				if sq.coord == pc.current_square
					sq.piece = pc.token
				else
					sq.piece = nil unless ChessPiece.occupies? sq.coord
				end
			end
		end
		@board.display_board
	end


	def run_game (current_turn=@player1)
		2.times { @player1.generate_moves; @player2.generate_moves }
		king_checkmated?; king_checked?; king_stalemated?
		current_turn.turn; puts
		pieces_on_board; puts
		if current_turn == @player1
			@player2.subtract_captured(@player1.captured)
			run_game(@player2)+
		else
			@player1.subtract_captured(@player2.captured)
			run_game
		end
	end

	def king_checked?
		kings = ChessPiece.all.select { |pc| pc.class == King }
		kings.each do |king| 
			if king.check?
				puts "#{king.color.capitalize}'s king is in check!" if king.check?
				king.protect_king
			end
		end
	end

	def king_checkmated?
		kings = ChessPiece.all.select { |pc| pc.class == King }
		kings.each do |king|
			if king.checkmate? 
				puts "Checkmate! #{king.color == "white" ? "Black wins!" : "White wins!"}"
				exit
			end
		end
	end

	def king_stalemated?
		kings = ChessPiece.all.select { |pc| pc.class == King }
		kings.each do |king|
			if king.stalemate?
				puts "Stalemate. Game over."
				exit
			end
		end
	end

end




game = ChessGame.new
#game.pieces_on_board
game.run_game


=begin 

=end


