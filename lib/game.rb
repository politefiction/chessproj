require 'yaml'
require_relative 'board'
require_relative 'pieces'
require_relative 'player'


class ChessGame
	attr_accessor :board, :p1, :p2, :full_move_history, :snapshots

	def initialize
		ChessPiece.clear
		@board = ChessBoard.new
		@p1 = Player.new("white")
		@p2 = Player.new("black")
		@full_move_history = []
		@snapshots = []
	end

	def start_game
		puts "Welcome to Chess! Would you like to load a previously saved game? (Y/N)"
		answer = gets.chomp.downcase
		if answer[0] == "y"
			puts "Loading previous game..."
			ChessGame.load_game
		elsif answer[0] == "n"
			puts "Starting new game..."
			puts "(Note: You can save your game at any point by entering 'save' in the console.)"
			puts; run_game
		else
			puts "Unable to understand entry. Please try again."
			puts; start_game
		end
	end

	def self.load_game
		data = YAML.load(File.read("saved_game.yaml"))
		save = self.new
		save.board = data[:board]
		save.p1 = data[:p1]; save.p2 = data[:p2]
		ChessGame.load_chesspieces(save.p1, save.p2)
		save.full_move_history = data[:full_move_history]
		save.snapshots = data[:snapshots]
		current = data[:current]
		save.run_game(current)
	end

	def self.load_chesspieces(p1, p2)
		ChessPiece.clear
		[p1, p2].each do |player|
			player.pieces.each do |pc| 
				ChessPiece.all << pc
				ChessPiece.white << pc if pc.color == "white"
				ChessPiece.black << pc if pc.color == "black"
			end
		end
	end

	def save_game(current)
		saved_game = File.open("saved_game.yaml", "w")
		saved_game.puts YAML.dump ({
			:board => @board,
			:p1 => @p1,
			:p2 => @p2,
			:full_move_history => @full_move_history,
			:snapshots => @snapshots,
			:current => current
		})
	end

	def run_game(current=@p1)
		pieces_on_board
		opponent = (current == @p1 ? @p2 : @p1 )
		[current, opponent].each { |player| player.generate_moves }
		snapshot_board; assess_king_status(current.king)
		check_draw_rules(current)
		process_turn(current); track_moves(current)
		opponent.subtract_captured_by(current)
		run_game(opponent)
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

	def process_turn(player)
		player.turn do 
			puts "Saving game..."
			save_game(player)
			process_turn(player)
		end
	end

	def snapshot_board
		snapshot = []
		ChessPiece.all.select { |pc| pc.current_square != nil }.each do |pc|
			snapshot << [pc.class.to_s, pc.color, pc.current_square]
		end
		@snapshots << snapshot.sort!
	end

	def track_moves(player)
		@full_move_history << player.move_history[-1]
	end

	def check_draw_rules(current)
		draw { "seventy-five move rule" } if seventyfive_move_rule?
		ask_for_draw(current) if (fifty_move_rule? or threefold_rep?)
	end

	def ask_for_draw(player, opponent=nil)
		opponent = (player == @p1 ? @p2 : @p1)
		puts fifty_move_rule? ? "Fifty-move rule achieved." : "Threefold repetition."
		player.confirm_draw do
			if fifty_move_rule?
				player.confirm_with_opponent(opponent.color) { draw { "fifty-move rule" } }
			else
				draw { "threefold repetition" } if threefold_rep?
			end
		end
	end

	def draw
		puts "Draw due to #{yield}. Game over."
		exit
	end

	def threefold_rep?
		@snapshots.count(@snapshots[-1]) >= 3 ? true : false
	end

	def fifty_move_rule?
		if @full_move_history.length >= 50
			unless @full_move_history.last(50).any? { |pc| pc[:moved].class == Pawn }
				@full_move_history.last(50).all? { |pc| pc[:captured_piece] == false } ? true : false
			end
		end
	end

	def seventyfive_move_rule?
		if @full_move_history.length >= 75
			unless @full_move_history.last(75).any? { |pc| pc[:moved].class == Pawn }
				@full_move_history.last(75).all? { |pc| pc[:captured_piece] == false } ? true : false
			end
		end
	end

	def assess_king_status(king)
		king.assess_threats
		if king.check?
			end_if_checkmate(king)
			puts "#{king.color.capitalize}'s king is in check!"
		else
			end_if_stalemate(king)
		end
	end

	def end_if_checkmate(king)
		if king.checkmate?
			puts "Checkmate! #{king.color == "white" ? "Black wins!" : "White wins!"}"
			exit
		end
	end

	def end_if_stalemate(king)
		if king.stalemate?
			puts "Stalemate. Game over."
			exit
		end
	end

end




#game = ChessGame.new
#game.start_game


