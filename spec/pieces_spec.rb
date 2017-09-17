require 'pieces'

describe MoveSet do
	subject { MoveSet.new([4, 2]) }
	context 'upon creation' do
		it { is_expected.to respond_to(:current_square) }
		it { is_expected.to respond_to(:potential_moves) }
	end
end

describe ChessPiece do 
	subject { ChessPiece.new("black", [2,2]) }
	context 'upon creation' do
		it { is_expected.to respond_to(:color) }
		it { is_expected.to respond_to(:token) }
		it { is_expected.to respond_to(:move_set) }
	end

	describe '#set_token' do
		before { subject.set_token("♧", "♣") }
		it 'assigns the token matching the color' do
			expect(subject.token).to eq("♣")
		end
	end
end

describe Pawn do 
	subject { Pawn.new("white", [1,0]) }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♙")
		end

		it 'should have two potential moves' do
			expect(subject.move_set.potential_moves.length).to eq(2)
		end
	end

	context 'after pawn has had first move' do
		before do 
			subject.move_set.potential_moves = []
			subject.first_move = false 
			subject.pawn_moves
		end

		it 'should have one potential move' do
			expect(subject.move_set.potential_moves.length).to eq(1)
		end
	end
end

describe Rook do
	subject { Rook.new("white", [0,0]) }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♖")
		end
		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([5,0], [0,3], [7,0])
			expect(pm).not_to include(nil)
		end
	end
end

describe Knight do
	subject { Knight.new("black", [6,7]) }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♞")
		end
		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([5,5], [7,5], [4,6])
			expect(pm).not_to include(nil)
		end
	end
end

describe Bishop do
	subject { Bishop.new("white", [0,2]) }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♗")
		end
		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([1,1], [3,5], [4,6])
			expect(pm).not_to include(nil)
		end
	end
end

describe Queen do
	subject { Queen.new("black", [3, 7]) }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♛")
		end
		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([3, 4], [2, 7], [6, 4], [1,5])
			expect(pm).not_to include(nil)
		end
	end
end

describe King do
	subject { King.new("white", [4, 0])}
		context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♔")
		end
		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([4, 1], [5, 0], [3, 1])
			expect(pm).not_to include(nil)
		end
	end
end