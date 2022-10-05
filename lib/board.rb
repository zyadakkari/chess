require 'pry-byebug'

class Game

  attr_reader :teams, :players

  def initialize()
    @teams = ["White", "Black"]
    @players = []
    @moveCounter = 0
    @winner = false
    @checkmate = false
    puts "Welcome to Chess!"
    choose_game_mode
    @gameMode == 1 ? pass_to_play_mode(@teams) : return
  end

  def choose_game_mode()
    puts "Would you like to play against a friend or a computer? Type 1 for friend and 0 for computer: "
    @gameMode = gets.chomp.to_i
  end

  def pass_to_play_mode(teams)
    puts "Great choice! Please enter a name for player 1: "
    playerOneName = gets.chomp
    puts "Welcome #{playerOneName}! Please enter a name for player 2: "
    playerTwoName = gets.chomp
    playerOneTeam = @teams.sample
    playerOneTeam == "White" ? playerTwoTeam = "Black" : playerTwoTeam = "White"
    puts "Great, thanks #{playerTwoName}. #{playerOneName} will be #{playerOneTeam} & #{playerTwoName} will be #{playerTwoTeam}"
    @players << player1 = {:name => playerOneName, :team => playerOneTeam}
    @players << player2 = {:name => playerTwoName, :team => playerTwoTeam}
  end

  def turn_picker(players)
    if players[0][:team] == "White"
      @moveCounter % 2 == 0 ? players[0] : players[1]
    else
      @moveCounter % 2 == 0 ? players[1] : players[0]
    end
  end

  def piece_selector()
    puts "#{@turn[:name]} pick a piece to move: "
    input = gets.chomp
    @piece = [input[1].to_i,input[3].to_i]
    while @play.board[@piece[0]][@piece[1]].team != @turn[:team]
      puts "Please choose a valid piece"
      input = gets.chomp
      @piece = [input[1].to_i,input[3].to_i]
    end
    @piece
  end

  def move_selector(opponentMoves=[])
    board
    pieceMoves = @play.get_piece_moves(@piece)
    puts "#{@turn[:name]} pick a square to move to: "
    input = gets.chomp
    move = [input[1].to_i,input[3].to_i]
    while !pieceMoves.include?(move)
      puts "Please choose a valid move combination"
      input = gets.chomp
      move = [input[1].to_i,input[3].to_i]
      pieceMoves = @play.get_piece_moves(@piece)
    end
    move
  end

  def checkmate()
    if @checkmate == true
      @winner = true
    end
  end

  def play_game()
    @play = Board.new()
    board = @play.board
    @play.show_board
    while @winner == false
      @turn = turn_picker(@players)
      checkers = @play.check?(@turn[:team])
      if !checkers.empty?
    # check the case of multiple checkers
        escapes = @play.escape_check(checkers, @turn[:team])
        if escapes.empty?
          @checkmate = true
        end
        escaped = false
        moveEscapes = escapes[0]
        blockEscapes = escapes[1][0]
        takeEscape = escapes[2]
        while escaped == false
          @piece = piece_selector()
          move = move_selector()
          if board[@piece[0]][@piece[1]].type == "King" && moveEscapes.include?(move)
            escaped = true
          elsif board[@piece[0]][@piece[1]].type != "King" && blockEscapes.include?(move)
            escaped = true
          elsif checkers.length == 1 && takeEscape == move
            escaped = true
          end
        end
      else
        @piece = piece_selector()
        move = move_selector()
      end
      @play.move_piece(@piece, move)
      @play.show_board
      @moveCounter += 1
    end
  end
end

class Board < Game

  attr_accessor :board, :blackKing, :blackQueen, :blackRook1, :blackRook2,
  :blackKnight1, :blackKnight2, :blackBishop1, :blackBishop2, :blackPawn1,
  :blackPawn2, :blackPawn3, :blackPawn4, :blackPawn5, :blackPawn6, :blackPawn7,
  :blackPawn8, :whiteKing, :whiteQueen, :whiteRook1, :whiteRook2, :whiteKnight1,
  :whiteKnight2, :whiteBishop1, :whiteBishop2, :whitePawn1, :whitePawn2,
  :whitePawn3, :whitePawn4, :whitePawn5, :whitePawn6, :whitePawn7, :whitePawn8, :pieces, :board

  def initialize()
    create_board
    king_maker
    queen_maker
    rook_maker
    bishop_maker
    knight_maker
    pawn_maker
    recalculate_all_moves
  end
  def create_board()
    @@board = Array.new(8) { Array.new(8, "X") }
    @@pieces = []
  end

  def edit_board(square, input)
    @@board[square[0]][square[1]] = input
  end

  def show_board(board=@@board)
    i = 0
    for row in board
      printRow = row.map  { |elem| elem != "X" ? elem = elem.symbol : elem }
      puts "#{i} #{printRow}"
      i += 1
    end
    puts "\n"
  end

  def board()
    @@board
  end

  def clone_board(board=@@board)
    boardClone = board.clone
  end

  def get_piece_moves(square)
    piece = @@board[square[0]][square[1]]
    return piece.moves
  end

  def move_piece(piecesquare, move, board=@@board)
    piece = board[piecesquare[0]][piecesquare[1]]
    if board[move[0]][move[1]] == "X"
        edit_board(piece.position, "X")
        edit_board(move, piece)
        piece.position = move
        piece.moved = true
    else
        attack(piece, move)
    end
    recalculate_all_moves
  end

  def attack(piece, move)
    @@board[move[0]][move[1]].status = "Inactive"
    @@board[move[0]][move[1]].position = []
    edit_board(piece.position, "X")
    edit_board(move, piece)
    piece.position = move
    piece.moved = true
  end

  def check?(team, checkers=[])
    team == "White" ? piece = @whiteKing : piece = @blackKing
    position = piece.position
    for char in @@pieces
      if char.team != team && char.moves.include?(position) && char.status == "Active"
        checkers << char
      end
    end
    checkers
  end

  def escape_check(checkers, team)
    escapes = []
    team == "White" ? king = @whiteKing : king = @blackKing
    # this will run into bug with not having the pawn attack covered but all others okay
    escapes << move_check_escape(king, team)
    escapes << block_check_escape(team, checkers, king)
    escapes << take_check_escape(checkers)
    escapes
  end

  def take_check_escape(checkers)
    if checkers.length == 1
      checkers[0].position
    end
  end

  def block_check_escape(team, checkers, escapes=[], king)
    for checker in checkers
      if checker.type == "Bishop" || checker.type == "Queen" || checker.type == "Rook"
        route = checker.route_finder(king.position)
        route = route - [king.position]
        escapes << route
      end
    end
    escapes
  end

  def move_check_escape(king, team, opponentMoves=[], escapes=[])
    for char in @@pieces
      if char.team != team && char.status == "Active"
        char.moves.each { |move| opponentMoves << move }
      end
    end
    for move in king.moves
      if !opponentMoves.include?(move)
        escapes << move
      end
    end
    escapes.flatten
  end


  def recalculate_all_moves()
    for char in @@pieces
      if char.status == "Active"
        char.move_finder()
      end
    end
  end

  def king_maker(kings=[])
    kings << @whiteKing = King.new("White", "\♔", "King")
    kings << @blackKing = King.new("Black", "\♚", "King")
    for king in kings
      edit_board(king.position, king)
      @@pieces << king
    end
  end

  def queen_maker(queens=[])
    queens << @whiteQueen = Queen.new("White", "\♕", "Queen")
    queens << @blackQueen = Queen.new("Black", "\♛", "Queen")
    for queen in queens
      edit_board(queen.position, queen)
      @@pieces << queen
    end
  end

  def rook_maker(rooks=[])
    rooks << @whiteRook1 = Rook.new("White", "\♖", [7,0], "Rook")
    rooks << @whiteRook2 = Rook.new("White", "\♖", [7,7], "Rook")
    rooks << @blackRook1 = Rook.new("White", "\♜", [0,0], "Rook")
    rooks << @blackRook2 = Rook.new("White", "\♜", [0,7], "Rook")
    for rook in rooks
      edit_board(rook.position, rook)
      @@pieces << rook
    end
  end

  def bishop_maker(bishops=[])
    bishops << @whiteBishop1 = Bishop.new("White", "\♗", [7,2], "Bishop")
    bishops << @whiteBishop2 = Bishop.new("White", "\♗", [7,5], "Bishop")
    bishops << @blackBishop1 = Bishop.new("Black", "\♝", [0,2], "Bishop")
    bishops << @blackBishop2 = Bishop.new("Black", "\♝", [0,5], "Bishop")
    for bishop in bishops
      edit_board(bishop.position, bishop)
      @@pieces << bishop
    end
  end

  def knight_maker(knights=[])
    knights << @whiteKnight1 = Knight.new("White", "\♘", [7,1], "Knight")
    knights << @whiteKnight2 = Knight.new("White", "\♘", [7,6], "Knight")
    knights << @blackKnight1 = Knight.new("Black", "\♞", [0,1], "Knight")
    knights << @blackKnight2 = Knight.new("Black", "\♞", [0,6], "Knight")
    for knight in knights
      edit_board(knight.position, knight)
      @@pieces << knight
    end
  end

  def pawn_maker(pawns=[])
    pawns << @whitePawn1 = Pawn.new("White", "\♙", [6,0], "Pawn")
    pawns << @whitePawn2 = Pawn.new("White", "\♙", [6,1], "Pawn")
    pawns << @whitePawn3 = Pawn.new("White", "\♙", [6,2], "Pawn")
    pawns << @whitePawn4 = Pawn.new("White", "\♙", [6,3], "Pawn")
    pawns << @whitePawn5 = Pawn.new("White", "\♙", [6,4], "Pawn")
    pawns << @whitePawn6 = Pawn.new("White", "\♙", [6,5], "Pawn")
    pawns << @whitePawn7 = Pawn.new("White", "\♙", [6,6], "Pawn")
    pawns << @whitePawn8 = Pawn.new("White", "\♙", [6,7], "Pawn")
    pawns << @blackPawn1 = Pawn.new("Black", "\♟", [1,0], "Pawn")
    pawns << @blackPawn2 = Pawn.new("Black", "\♟", [1,1], "Pawn")
    pawns << @blackPawn3 = Pawn.new("Black", "\♟", [1,2], "Pawn")
    pawns << @blackPawn4 = Pawn.new("Black", "\♟", [1,3], "Pawn")
    pawns << @blackPawn5 = Pawn.new("Black", "\♟", [1,4], "Pawn")
    pawns << @blackPawn6 = Pawn.new("Black", "\♟", [1,5], "Pawn")
    pawns << @blackPawn7 = Pawn.new("Black", "\♟", [1,6], "Pawn")
    pawns << @blackPawn8 = Pawn.new("Black", "\♟", [1,7], "Pawn")
    for pawn in pawns
      edit_board(pawn.position, pawn)
      @@pieces << pawn
    end
  end

end

class King < Board

  attr_reader :team, :symbol, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moves = []
    @moved = false
    @team == "White" ? @position = [7,4] : @position = [0,4]
  end

  def board()
    @@board
  end

  def piece_movement()
    return [[1,0], [1,1], [1,-1], [-1,0], [-1,1], [-1,-1], [0,1], [0,-1]]
  end

  def possible_landing_squares(moves, options=[], position=@position, moved=@moved)
    for move in moves
      if (position[0]+move[0]).between?(0,7) && (position[1]+move[1]).between?(0,7)
        options << [position[0]+move[0], position[1]+move[1]]
      end
    end
    options
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = piece_movement()
    attackableSquares = possible_landing_squares(moves)
    for square in attackableSquares
      if opponent?(square)
        targets << square
      end
    end
    targets
  end

  def illegal_moves(moves)
    for char in @@pieces
      if char.team != @team && char.status == "Active"
        char.moves.each { |move| opponentMoves << move }
      end
    end
    illegalMoves = opponentMoves & @moves
  end

  def move_finder(position=@position)
    @moves = []
    board
    moves = piece_movement()
    possibleDestinations = possible_landing_squares(moves)
    for destination in possibleDestinations
      obstructed = false
      if board[destination[0]][destination[1]] != "X"
          obstructed = true
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder()
    @moves = @moves + targets
    illegalMoves = illegal_moves(@moves)
    @moves = @moves - illegalMoves
  end

end

class Queen < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moves = []
    @moved = false
    @value = 9
    @team == "White" ? @position = [7,3] : @position = [0,3]
  end

  def board()
    @@board
  end

  def piece_movement()
    return [[1,1], [1,-1], [-1,1], [-1,-1], [1,0], [-1,0], [0,1], [0,-1]]
  end

  def possible_landing_squares(moves, options=[], position=@position, moved=@moved)
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

  def route_finder(position=@position, route=[], destination)
    curSq = position
    move = []
    if destination[0]-curSq[0] > 0
      move[0] = 1
    elsif destination[0]-curSq[0] < 0
      move[0] = -1
    else
      move[0] = 0
    end
    if destination[1]-curSq[1] > 0
      move[1] = 1
    elsif destination[1]-curSq[1] < 0
      move[1] = -1
    else
      move[1] = 0
    end
    until route.include?(destination)
      route << curSq = [curSq[0]+move[0], curSq[1]+move[1]]
    end
    route
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position)
    targets = []
    board
    movesList = piece_movement()
    for move in movesList
        # binding.pry
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
      elsif opponent?(currentSquare)
        targets << currentSquare
      else
        next
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    piecemoves = piece_movement()
    possibleDestinations = possible_landing_squares(piecemoves)
    for destination in possibleDestinations
      route = route_finder(destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder(@position)
    @moves = @moves + targets
  end
end

class Rook < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moves = []
    @moved = false
    @value = 5
    @position = position
  end

  def board()
    @@board
  end

  def piece_movement()
    return [[1,0], [-1,0], [0,1], [0,-1]]
  end

  def possible_landing_squares(moves, options=[], position=@position, moved=@moved)
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

  def route_finder(position=@position, route=[], destination)
    curSq = position
    move = []
    if destination[0]-curSq[0] > 0
      move[0] = 1
    elsif destination[0]-curSq[0] < 0
      move[0] = -1
    else
      move[0] = 0
    end
    if destination[1]-curSq[1] > 0
      move[1] = 1
    elsif destination[1]-curSq[1] < 0
      move[1] = -1
    else
      move[1] = 0
    end
    until route.include?(destination)
      route << curSq = [curSq[0]+move[0], curSq[1]+move[1]]
    end
    route
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position)
    targets = []
    board
    movesList = piece_movement()
    for move in movesList
        # binding.pry
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
      elsif opponent?(currentSquare)
        targets << currentSquare
      else
        next
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    piecemoves = piece_movement()
    possibleDestinations = possible_landing_squares(piecemoves)
    for destination in possibleDestinations
      route = route_finder(destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder(@position)
    @moves = @moves + targets
  end
end

class Bishop < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
    @team = team
    @type = type
    @symbol = symbol
    @status = "Active"
    @moved = false
    @value = 3
    @position = position
  end

  def board()
    @@board
  end

  def piece_movement()
    return [[1,1], [1,-1], [-1,1], [-1,-1]]
  end

  def possible_landing_squares(moves, options=[], position=@position, moved=@moved)
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

  def route_finder(position=@position, route=[], destination)
# binding.pry
    curSq = position
    move = []
    destination[0]-curSq[0] > 0 ? move[0] = 1 : move[0] = -1
    destination[1]-curSq[1] > 0 ? move[1] = 1 : move[1] = -1
    until route.include?(destination)
      route << curSq = [curSq[0]+move[0], curSq[1]+move[1]]
    end
    route
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position)
    targets = []
    board
    movesList = piece_movement()
    for move in movesList
        # binding.pry
      loc = position.clone
      currentSquare = loc
      (currentSquare[0] + move[0]).between?(0,7) ? currentSquare[0] = currentSquare[0] + move[0] : next
      (currentSquare[1] + move[1]).between?(0,7) ? currentSquare[1] = currentSquare[1] + move[1] : next
      while board[currentSquare[0]][currentSquare[1]] == "X" && (currentSquare[0]+move[0]).between?(0,7) && (currentSquare[1]+move[1]).between?(0,7)
        currentSquare[0] = currentSquare[0] + move[0]
        currentSquare[1] = currentSquare[1] + move[1]
      end
      if board[currentSquare[0]][currentSquare[1]] == "X"
        next
      elsif opponent?(currentSquare)
        targets << currentSquare
      else
        next
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    piecemoves = piece_movement()
    possibleDestinations = possible_landing_squares(piecemoves)
    for destination in possibleDestinations
      route = route_finder(destination)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder(@position)
    @moves = @moves + targets
  end
end

class Knight < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
      @team = team
      @type = type
      @symbol = symbol
      @status = "Active"
      @moved = false
      @value = 3
      @position = position
  end

  def board()
    @@board
  end

  def piece_movement()
    return [[2,1], [2,-1], [-2,1], [-2,-1], [1,2], [-1,2], [1,-2], [-1,-2]]
  end

  def possible_landing_squares(moves, options=[], position=@position, moved=@moved)
    for move in moves
      if (position[0]+move[0]).between?(0,7) && (position[1]+move[1]).between?(0,7)
        options << [position[0]+move[0], position[1]+move[1]]
      end
    end
    options
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = piece_movement()
    attackableSquares = possible_landing_squares(moves)
    for square in attackableSquares
      if opponent?(square)
        targets << square
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    board
    moves = piece_movement()
    possibleDestinations = possible_landing_squares(moves)
    for destination in possibleDestinations
      obstructed = false
      if board[destination[0]][destination[1]] != "X"
          obstructed = true
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder()
    @moves = @moves + targets
  end
end

class Pawn < Board
  attr_reader :team, :symbol, :value, :type
  attr_accessor :status, :moves, :moved, :position

  def initialize(team, symbol, position, type)
      @team = team
      @type = type
      @symbol = symbol
      @status = "Active"
      @moves = []
      @moved = false
      @value = 1
      @position = position
  end

  def board()
    @@board
  end

  def piece_movement(team=@team)
    return team == "Black" ? [1,0] : [-1,0]
  end

  def possible_landing_squares(move, options=[], position=@position, moved=@moved)
    if (position[0]+move[0]).between?(0,7) && (position[1]+move[1]).between?(0,7)
      options << [position[0]+move[0], position[1]+move[1]]
    end
    if moved == false
      options << [position[0]+(move[0]*2), position[1]+move[1]]
    end
    options
  end

  def route_finder(position=@position, route=[], destination, move)
    curSq = position
    until route.include?(destination)
      route << curSq = [curSq[0]+move[0], curSq[1]+move[1]]
    end
    route
  end

  def attack_movement(team=@team)
    return team == "Black" ? [[1, 1], [1, -1]] : [[-1, 1], [-1,-1]]
  end

  def attackable_squares(moves, position=@position, options=[])
    for move in moves
      if (position[0]+move[0]).between?(0,7) && (position[1]+move[1]).between?(0,7)
        options << [position[0]+move[0], position[1]+move[1]]
      end
    end
    options
  end

  def opponent?(square, team=@team)
    opposingPiece = board[square[0]][square[1]]
    if opposingPiece != "X" && opposingPiece.team != team
      return true
    end
  end

  def attack_move_finder(position=@position)
    targets = []
    board
    moves = attack_movement()
    attackableSquares = attackable_squares(moves)
    for square in attackableSquares
      if opponent?(square)
        targets << square
      end
    end
    targets
  end

  def move_finder(position=@position)
    @moves = []
    # binding.pry
    board
    pieceMoves = piece_movement
    possibleDestinations = possible_landing_squares(pieceMoves)
    for destination in possibleDestinations
      route = route_finder(destination, pieceMoves)
      obstructed = false
      for square in route
        if board[square[0]][square[1]] != "X"
          obstructed = true
        end
      end
      if obstructed == false
        @moves << destination
      end
    end
    targets = attack_move_finder()
    @moves = @moves + targets
  end
end

newgame = Game.new

p newgame.play_game
