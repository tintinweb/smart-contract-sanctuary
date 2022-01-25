// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Connect4 is Ownable {
    event NextMove(
        uint256 indexed gameId,
        address indexed player,
        bool isPlayer1Next,
        uint8 x,
        uint8 y
    );
    event Victory(uint256 indexed gameId, address indexed winner);
    event Resigned(uint256 indexed gameId, address indexed resigner);
    event Draw(uint256 indexed gameId);
    event UpdatePlayerAmount(
        address indexed player,
        uint256 amountWon,
        uint256 totalAmount
    );
    event NewGame(
        address indexed player1,
        address indexed player2,
        uint256 indexed gameId
    );
    event NewPlayer(address indexed player);

    uint8 private constant BOARD_WIDTH = 7;
    uint8 private constant BOARD_HEIGHT = 4;
    uint256 private immutable claimWindow;
    uint256 private immutable payAmount;

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

    struct Player {
        address username;
        uint256 amountWon;
    }

    Game[] public games;
    Player[] public players;

    mapping(address => uint256) public activeGames;

    /// @param _claimWindow The numbers of minutes to wait before claiming the winnings.
    /// @param _payAmount The amount of ether to bet each time you play
    constructor(uint32 _claimWindow, uint256 _payAmount) {
        claimWindow = _claimWindow * 1 minutes;
        payAmount = _payAmount * 1 wei;
    }

    /// @dev modifier to allow the function to proceed only if the game is not yet over.
    modifier onlyActiveGame(uint256 _gameId) {
        require(!games[_gameId].isOver, "Game Over");
        _;
    }

    /// @dev Pay funds to the game winner and the contract owner. Contract owner takes a 10% cut.
    /// @param _game The completed game
    /// @param _winner The address of the winning player
    function _payoutVictory(Game memory _game, address _winner) private {
        uint256 prize = _game.p1Amount + _game.p2Amount;
        uint256 ownerCut = (prize * 10) / 100;

        // Save new state before paying out
        _updatePlayerAmount(_winner, prize);

        // Pay out to the winner and send the owner cut
        (bool toOwnerCall, ) = owner().call{value: ownerCut}("");
        (bool toWinnerCall, ) = _winner.call{value: prize - ownerCut}("");

        require(
            toOwnerCall == true && toWinnerCall == true,
            "Failed to pay out"
        );
    }

    /// @dev Repay funds to both players if the game is drawn
    /// @param _game The drawn game
    function _payoutDraw(Game memory _game) private {
        (bool toP1, ) = _game.player1.call{value: _game.p1Amount}("");
        (bool toP2, ) = _game.player2.call{value: _game.p2Amount}("");

        require(toP1 == true && toP2 == true, "Failed to pay out");
    }

    /// @dev Marks the game complete
    /// @param _game The completed game
    function _markGameOver(Game storage _game) private {
        _game.isOver = true;
        activeGames[_game.player1]--;
        activeGames[_game.player2]--;
    }

    /// @dev Save new player
    /// @param _address The player address
    function _savePlayer(address _address) private {
        bool isPlayerAlreadyExists;

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].username == _address) {
                isPlayerAlreadyExists = true;
                break;
            }
        }

        if (isPlayerAlreadyExists == false) {
            Player memory newPlayer;
            newPlayer.username = _address;
            players.push(newPlayer);
            emit NewPlayer(_address);
        }
    }

    /// @dev Update player amountWon
    /// @param _target The player address
    /// @param _amountWon The amount recently won by the player
    function _updatePlayerAmount(address _target, uint256 _amountWon) private {
        bool isPlayerAlreadyExists;

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].username == _target) {
                players[i].amountWon += _amountWon;
                emit UpdatePlayerAmount(
                    _target,
                    _amountWon,
                    players[i].amountWon
                );
                isPlayerAlreadyExists = true;
                break;
            }
        }

        require(isPlayerAlreadyExists == true, "unknown player");
    }

    /// @dev Confirms that the x/y co-ordinates provided are within the boundary of the game board
    /// @param _x The column of the move
    /// @param _y The row of the move
    /// @return true if the co-ordinates are within the board boundary
    function _isOnBoard(int8 _x, int8 _y) private pure returns (bool) {
        return (_x >= 0 &&
            _x < int8(BOARD_WIDTH) &&
            _y >= 0 &&
            _y < int8(BOARD_HEIGHT));
    }

    /// @dev Looks along an axis from a starting point to see if any player has the winning number of moves in a row
    /// @param _game The game to check
    /// @param _x The starting column to search from
    /// @param _y The starting row to search from
    /// @param _adjustments The axis to search along
    /// @return true if the required number of moves in a row is along the provided axis
    function _findSame(
        Game storage _game,
        uint8 _x,
        uint8 _y,
        int8[4] memory _adjustments
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

        return count >= 4;
    }

    /// @dev Checks to see if either player has won the game
    /// @param _game The game to check
    /// @param _x The most recent column moved
    /// @param _y The most recent row moved
    /// @return true if the game is over
    function _isGameOver(
        Game storage _game,
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
    function _isGameDrawn(Game storage _game) private view returns (bool) {
        for (uint8 i = 0; i < BOARD_WIDTH; i++) {
            for (uint8 j = 0; j < BOARD_HEIGHT; j++) {
                if (_game.usedTiles[i][j] == 0) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Starts a new game of Connect 4
    /// @param _player2 The address of the opposing player
    function newGame(address _player2) external {
        Game memory game;
        game.player1 = msg.sender;
        game.player2 = _player2;
        game.isPlayer1Next = true;
        game.claimTime = uint32(block.timestamp + claimWindow);

        games.push(game);
        uint256 id = games.length - 1;

        activeGames[msg.sender]++;
        activeGames[_player2]++;

        _savePlayer(msg.sender);
        _savePlayer(_player2);
        emit NewGame(game.player1, game.player2, id);
    }

    /// @dev Takes a turn on a game of Connect 4. The user provides a game Id and a column. This function will determine which space
    ///      on the game board is filled by the move. It will confirm that the move is legal, checks if the move results in a
    ///      victory or a draw and raises events accordingly.
    /// @param _gameId The ID of the game to move on
    /// @param _x The column to move on
    function takeTurn(uint256 _gameId, uint8 _x)
        external
        payable
        onlyActiveGame(_gameId)
    {
        require(msg.value >= payAmount, "Not enough Ether");
        Game storage game = games[_gameId];
        require(
            msg.sender == (game.isPlayer1Next ? game.player1 : game.player2),
            "Not your move"
        );
        require(!game.isOver && _x < BOARD_WIDTH, "Illegal move");

        // Find y axis: first non used tile on column
        uint8 y;
        for (y = 0; y <= BOARD_HEIGHT; y++) {
            if (y == BOARD_HEIGHT || game.usedTiles[_x][y] == 0) {
                break;
            }
        }

        require(y < BOARD_HEIGHT, "Column full");

        if (game.isPlayer1Next) game.p1Amount += payAmount;
        else game.p2Amount += payAmount;

        game.usedTiles[_x][y] = game.isPlayer1Next ? 1 : 2;
        game.isPlayer1Next = !game.isPlayer1Next;
        game.claimTime = uint32(block.timestamp + claimWindow);

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
            (bool success, ) = msg.sender.call{value: msg.value - payAmount}(
                ""
            );
            require(success, "Failed to send back ETH");
        }
    }

    /// @dev Resign from a game
    /// @param _gameId the ID of the game to resign from
    function resignGame(uint256 _gameId) public onlyActiveGame(_gameId) {
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
    function claimWin(uint256 _gameId) public onlyActiveGame(_gameId) {
        Game storage game = games[_gameId];
        require(
            msg.sender != (game.isPlayer1Next ? game.player1 : game.player2),
            "Cannot claim win on your move"
        );
        require(game.claimTime <= block.timestamp, "Cannot claim a win yet");

        _markGameOver(game);
        _payoutVictory(game, msg.sender);
        emit Victory(_gameId, msg.sender);
    }

    /// @dev accessor returns a game board 2D array
    /// @param _gameId the ID of the board to return
    /// @return the selected game board
    function getBoard(uint256 _gameId)
        public
        view
        returns (uint8[6][7] memory)
    {
        return games[_gameId].usedTiles;
    }

    /// @dev returns all of the active games for a given player
    function getGamesByPlayer() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](activeGames[msg.sender]);
        uint256 counter;

        Game memory game;

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
    function getActiveGamesIds() public view returns (uint256[] memory) {
        Game memory game;
        uint256 numberOfActiveGames;

        for (uint256 i = 0; i < games.length; i++) {
            game = games[i];
            if (!game.isOver) {
                numberOfActiveGames++;
            }
        }

        uint256[] memory gameIds = new uint256[](numberOfActiveGames);
        uint256 counter;

        for (uint256 j = 0; j < games.length; j++) {
            game = games[j];
            if (!game.isOver) {
                gameIds[counter] = j;
                counter++;
            }
        }

        return gameIds;
    }

    /// @dev returns players with their associated amounts
    function getLeaderboard()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        Player memory player;
        uint256[] memory playersAmount = new uint256[](players.length);
        address[] memory playersAddresses = new address[](players.length);

        for (uint256 j = 0; j < players.length; j++) {
            player = players[j];
            playersAmount[j] = players[j].amountWon;
            playersAddresses[j] = players[j].username;
        }

        return (playersAddresses, playersAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}