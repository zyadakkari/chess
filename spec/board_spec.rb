require '../lib/board.rb'

# test for starting board set up right (check black king and white rook)
# describe Board do
#   describe "#move_piece" do
#     expect(subject.move_piece(subject.blackPawn1, [3,0])).to
#   end
# end
# pawn tests
# test for moving a pawn two spaces
describe Pawn do

  describe "#move_finder" do
    let(:pawn) { subject.new("Black", "\♟", [1,0]) }
    it "correctly finds legal moves of black Pawn at (1,0)" do
      expect(subject.move_finder([1,0])).to match("[2,0], [3,0]")
    end
  end
end

# test for blocking a pawn moving sideways

#test for blocking a pawn moving one space when obstructed
