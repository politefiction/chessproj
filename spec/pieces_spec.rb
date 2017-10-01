require 'pieces'

# Some trouble clearing out data for successive tests,
# causing King's tests to fail; will modify later.


describe MoveSet do
	subject { MoveSet.new([4, 2]) }
	context 'upon creation' do
		it { is_expected.to respond_to(:current_square) }
		it { is_expected.to respond_to(:potential_moves) }
	end
end

describe ChessPiece do 
	after(:all) { ChessPiece.all.map { |pc| pc = nil } } # Delete, I guess?
	subject { ChessPiece.new("black", [5,4]) }
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
	#after(:all) { ChessPiece.all.map { |pc| pc = nil } }
	subject { Pawn.new("white", [1,1]) }
	before(:each) { subject.pawn_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♙")
		end

		it 'should have two potential moves' do
			expect(subject.move_set.potential_moves.length).to eq(2)
		end
	end

	describe '#pawn_moves' do
		context 'after pawn has had first move' do
			before do 
				subject.first_move = false 
				subject.pawn_moves
			end

			it 'should have one potential move' do
				expect(subject.move_set.potential_moves.length).to eq(1)
			end
		end

		context 'when an opposing piece is diagonal to pawn' do
			let(:knight) { Knight.new("black", [2,2]) }
			before do
				knight.inspect # test doesn not work without this, for some reason
			end
			it 'should add a diagonal move' do
				expect(subject.move_set.potential_moves).to include([2,2])
			end
		end
	end
end

describe Rook do
	#after(:all) { ChessPiece.all.map { |pc| pc = nil } }
	subject { Rook.new("white", [0,0]) }
	before(:each) { subject.rook_moves }
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
	#after(:all) { ChessPiece.all.map { |pc| pc = nil } }
	subject { Knight.new("black", [6,7]) }
	before(:each) { subject.knight_moves }
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
	#after(:all) { ChessPiece.all.map { |pc| pc = nil } }
	subject { Bishop.new("white", [0,2]) }
	before(:each) { subject.bishop_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♗")
		end
		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([1,3], [3,5], [4,6])
			expect(pm).not_to include(nil)
		end
	end
end

describe Queen do
	#after(:all) { ChessPiece.all.map { |pc| pc = nil } }
	subject { Queen.new("black", [3, 7]) }
	before(:each) { subject.queen_moves }
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
	#after(:all) { ChessPiece.all.map { |pc| pc = nil } }
	subject { King.new("white", [4, 0])}
	before(:each) { subject.king_moves }
	context 'upon creation' do
		it 'has a token matching its color' do
			expect(subject.token).to eq("♔")
		end

		it 'generates correct potential moves' do
			pm = subject.move_set.potential_moves
			expect(pm).to include([4, 1], [5, 0])
			expect(pm).not_to include(nil)
		end
	end

	describe '#check?' do
		context 'when king is threatened by an opposing piece' do
			let(:rook) { Rook.new("black", [0,0])}
			it 'triggers a check' do
				rook.inspect
				expect(subject.check?).to eq(true)
			end
		end
	end

	describe '#checkmate?' do
		context 'when king is threatened on all sides' do
			let(:bishop) { Bishop.new("black", [7,2]) }
			let(:queen) { Queen.new("black", [3,3]) }
			before { bishop.inspect; queen.inspect }
			it 'triggers a checkmate' do
				expect(subject.checkmate?).to eq(true)
			end
		end
	end
end