require_relative 'board'
require_relative 'pieces'
require_relative 'player'


class ChessGame
	attr_accessor :board, :player1, :player2

	def initialize
		ChessPiece.clear
		@board = ChessBoard.new
		@player1 = Player.new("white", @board)
		@player2 = Player.new("black", @board)
	end

	def pieces_on_board
		@board.squares.each do |sq|
			ChessPiece.all.each do |pc|
				if sq.coord == pc.move_set.current_square
					sq.piece = pc.token
				else
					sq.piece = nil unless pc.occupied? sq.coord
				end
			end
		end
	end

end


=begin

game = ChessGame.new
game.pieces_on_board
game.board.display_board


=end