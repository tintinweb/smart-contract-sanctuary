pragma solidity ^0.4.23;

import "./2_SafeMath.sol";
import "./3_Ownable.sol";

/// @title Implements the classic game, Connect 4
contract LedgerConnect4 is Ownable {
    using SafeMath for uint256;

    event NextMove(
        uint256 indexed gameId,
        address player,
        bool isPlayer1Next,
        uint8 x,
        uint8 y
    );
    event Victory(uint256 indexed gameId, address winner);
    event Resigned(uint256 indexed gameId, address resigner);
    event Draw(uint256 indexed gameId);
    event Log(string category, string message);
    event NewGame(
        address indexed player1,
        address indexed player2,
        uint256 gameId
    );

    uint8 boardWidth;
    uint8 boardHeight;
    uint8 winCount;
    uint256 claimWindow;
    uint256 payAmount;

    // A game instance. Connect 4 is played between two players on a 2D game board.
    struct Game {
        address player1;
        address player2;
        bool isOver;
        bool isPlayer1Next;
        uint8[6][7] usedTiles;
        uint32 claimTime;
        uint256 p1Amount;
        uint256 p2Amount;
    }

    Game[] public games;
    mapping(address => uint256) activeGames;

    constructor() public {
        boardWidth = 7;
        boardHeight = 6;
        winCount = 4;
        //claimWindow = 10;
        claimWindow = 1;
        payAmount = 1000000;
    }

    /// @dev modifier to allow the function to proceed only if the game is not yet over.
    modifier isGameActive(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(!game.isOver, "Game Over");
        _;
    }

    /// @dev Pay funds to the game winner and the contract owner. Contract owner takes a 10% cut.
    /// @param _game The completed game
    /// @param _winner The address of the winning player
    function _payoutVictory(Game _game, address _winner) private {
        // uint256 prize = _game.p1Amount.add(_game.p2Amount);
        uint256 prize = _game.p1Amount + _game.p2Amount;
        emit Log("prize", "after  _game.p1Amount.add(_game.p2Amount)");
        // uint256 ownerCut = prize.mul(10).div(100);
        // owner().transfer(ownerCut);
        // _winner.transfer(prize.sub(ownerCut));
        _winner.transfer(prize);
    }

    /// @dev Repay funds to both players if the game is drawn
    /// @param _game The drawn game
    function _payoutDraw(Game _game) private {
        _game.player1.transfer(_game.p1Amount);
        _game.player2.transfer(_game.p2Amount);
    }

    /// @dev Marks the game complete
    /// @param _game The completed game
    function _markGameOver(Game storage _game) private {
        _game.isOver = true;
        activeGames[_game.player1]--;
        activeGames[_game.player2]--;
    }

    /// @dev Checks that the move is a legal one for the provided game
    /// @param _game The game to check move legality for
    /// @param _x the Column the usr is trying to move on
    /// @return true if the move is legal
    function _isLegalMove(Game _game, uint8 _x) private view returns (bool) {
        return !_game.isOver && _x < boardWidth;
    }

    /// @dev Confirms that the x/y co-ordinates provided are within the boundary of the game board
    /// @param _x The column of the move
    /// @param _y The row of the move
    /// @return true if the co-ordinates are within the board boundary
    function _isOnBoard(int8 _x, int8 _y) private view returns (bool) {
        return (_x >= 0 &&
            _x < int8(boardWidth) &&
            _y >= 0 &&
            _y < int8(boardHeight));
    }

    /// @dev Looks along an axis from a starting point to see if any player has the winning number of moves in a row
    /// @param _game The game to check
    /// @param _x The starting column to search from
    /// @param _y The starting row to search from
    /// @param _adjustments The axis to search along
    /// @return true if the required number of moves in a row is along the provided axis
    function _findSame(
        Game _game,
        uint8 _x,
        uint8 _y,
        int8[4] _adjustments
    ) private view returns (bool) {
        uint8 target = _game.usedTiles[_x][_y];
        uint8 count = 1;
        int8 nx = int8(_x) + _adjustments[0];
        int8 ny = int8(_y) + _adjustments[1];

        while (
            _isOnBoard(nx, ny) &&
            _game.usedTiles[uint8(nx)][uint8(ny)] == target
        ) {
            count++;
            nx = nx + _adjustments[0];
            ny = ny + _adjustments[1];
        }

        nx = int8(_x) + _adjustments[2];
        ny = int8(_y) + _adjustments[3];
        while (
            _isOnBoard(nx, ny) &&
            _game.usedTiles[uint8(nx)][uint8(ny)] == target
        ) {
            count++;
            nx = nx + _adjustments[2];
            ny = ny + _adjustments[3];
        }

        return count >= winCount;
    }

    /// @dev Checks to see if either player has won the game
    /// @param _game The game to check
    /// @param _x The most recent column moved
    /// @param _y The most recent row moved
    /// @return true if the game is over
    function _isGameOver(
        Game _game,
        uint8 _x,
        uint8 _y
    ) private view returns (bool) {
        return (_findSame(_game, _x, _y, [int8(-1), 0, 1, 0]) ||
            _findSame(_game, _x, _y, [int8(-1), -1, 1, 1]) ||
            _findSame(_game, _x, _y, [int8(-1), 1, 1, -1]) ||
            _findSame(_game, _x, _y, [int8(0), -1, 0, 1]));
    }

    /// @dev Checks to see if the game is drawn, i.e. the game board is full
    /// @param _game The game to check
    /// @return true if the game is drawn
    function _isGameDrawn(Game _game) private view returns (bool) {
        for (uint8 i = 0; i < boardWidth; i++) {
            for (uint8 j = 0; j < boardHeight; j++) {
                if (_game.usedTiles[i][j] == 0) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Starts a new game of Connect 4
    /// @param _player2 The address of the opposing player
    function newGame(address _player2) public {
        address player1 = msg.sender;
        uint256 initAmount = 0;

        Game memory game;
        game.player1 = player1;
        game.player2 = _player2;
        game.isOver = false;
        game.isPlayer1Next = true;
        game.claimTime = uint32(now + claimWindow);
        game.p1Amount = initAmount;
        game.p2Amount = initAmount;

        uint256 id = games.push(game) - 1;
        activeGames[player1]++;
        activeGames[_player2]++;

        emit NewGame(game.player1, game.player2, id);
    }

    /// @dev Takes a turn on a game of Connect 4. The user provides a game Id and a column. This function will determine which space
    ///      on the game board is filled by the move. It will confirm that the move is legal, checks if the move results in a
    ///      victory or a draw and raises events accordingly.
    /// @param _gameId The ID of the game to move on
    /// @param _x The column to move on
    function takeTurn(uint256 _gameId, uint8 _x)
        public
        payable
        isGameActive(_gameId)
    {
        require(msg.value >= payAmount, "Not enough Ether sent");
        Game storage game = games[_gameId];
        address nextMover = game.isPlayer1Next ? game.player1 : game.player2;
        require(msg.sender == nextMover, "Not your move");
        require(_isLegalMove(game, _x), "Illegal move");

        // Find y axis: first non used tile on column
        uint8 y;
        for (y = 0; y <= boardHeight; y++) {
            if (y == boardHeight || game.usedTiles[_x][y] == 0) {
                break;
            }
        }

        require(y < boardHeight, "Column full");

        if (game.isPlayer1Next) {
            game.p1Amount += msg.value;
        } else {
            game.p2Amount += msg.value;
        }

        game.usedTiles[_x][y] = game.isPlayer1Next ? 1 : 2;
        game.isPlayer1Next = !game.isPlayer1Next;
        game.claimTime = uint32(now + claimWindow);

        emit NextMove(_gameId, msg.sender, game.isPlayer1Next, _x, y);
        // Check game over state, victory or draw
        if (_isGameOver(game, _x, y)) {
            _markGameOver(game);
            _payoutVictory(game, msg.sender);
            emit Victory(_gameId, msg.sender);
        } else if (_isGameDrawn(game)) {
            _markGameOver(game);
            _payoutDraw(game);
            emit Draw(_gameId);
        }

        // If the user sent too much ETH, send the rest back
        if (msg.value > payAmount) {
            msg.sender.transfer(msg.value - payAmount);
        }
    }

    /// @dev Resign from a game
    /// @param _gameId the ID of the game to resign from
    function resignGame(uint256 _gameId) public isGameActive(_gameId) {
        Game storage game = games[_gameId];
        require(
            msg.sender == game.player1 || msg.sender == game.player2,
            "Who are you?"
        );

        _markGameOver(game);
        _payoutVictory(
            game,
            msg.sender == game.player1 ? game.player2 : game.player1
        );
        emit Resigned(_gameId, msg.sender);
    }

    /// @dev Claim a win on a game. Only allowed if the claimTime has elapsed since the last move was made. This
    ///      feature allows users to claim a win when the opponent has stopped moving.
    /// @param _gameId The ID of the game to claim a win on
    function claimWin(uint256 _gameId) public isGameActive(_gameId) {
        Game storage game = games[_gameId];
        address nextMover = game.isPlayer1Next ? game.player1 : game.player2;
        require(msg.sender != nextMover, "Cannot claim win on your move");
        require(game.claimTime <= now, "Cannot claim a win yet");

        _markGameOver(game);
        _payoutVictory(game, msg.sender);
        emit Victory(_gameId, msg.sender);
    }

    /// @dev accessor returns a game board 2D array
    /// @param _gameId the ID of the board to return
    /// @return the selected game board
    function getBoard(uint256 _gameId) public view returns (uint8[6][7]) {
        return games[_gameId].usedTiles;
    }

    /// @dev returns all of the active games for a given player
    function getGamesByPlayer() public view returns (uint256[]) {
        uint256[] memory result = new uint256[](activeGames[msg.sender]);
        Game memory game;
        uint256 counter = 0;
        for (uint256 i = 0; i < games.length; i++) {
            game = games[i];
            if (
                !game.isOver &&
                (game.player1 == msg.sender || game.player2 == msg.sender)
            ) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

    /// @dev returns all active games
    function getActiveGamesIds() public view returns (uint256[]) {
        Game memory game;
        uint256 numberOfActiveGames = 0;

        for (uint256 i = 0; i < games.length; i++) {
            game = games[i];
            if (!game.isOver) {
                numberOfActiveGames++;
            }
        }

        uint256[] memory gameIds = new uint256[](numberOfActiveGames);
        uint256 counter = 0;

        for (uint256 j = 0; j < games.length; j++) {
            game = games[j];
            if (!game.isOver) {
                gameIds[counter] = j;
                counter++;
            }
        }

        return gameIds;
    }
}