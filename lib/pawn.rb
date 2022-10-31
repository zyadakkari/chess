require 'pry-byebug'

moves = [[1,1], [1,-1], [-1,1], [-1,-1]]

def possible_landing_squares(moves, options=[], position=[5,5])
  for move in moves
    for i in (1..7)
      tempvar = []
      tempvar[0] = move[0] * i
      tempvar[1] = move[1] * i
      if (position[0]+tempvar[0]).between?(0,7) && (position[1]+tempvar[1]).between?(0,7)
        options << [position[0]+tempvar[0], position[1]+tempvar[1]]
      end
    end
  end
  options
end
p possible_landing_squares(moves)
