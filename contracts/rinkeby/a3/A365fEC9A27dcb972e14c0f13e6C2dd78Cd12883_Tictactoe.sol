// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';


contract Tictactoe {

    
    struct Game {
        // game Id (unique) increamenting from 0
        uint gameId;

        // 3x3 board with 0,1,2 for empty, X, O
        uint8[3][3] board;

        // 0 for X, 1 for O
        uint8 turn;

        // 0 for not finished, 1 for player 1 win, 2 for player 2 win, 3 for draw
        uint8 winner;

        // 0 for not started, 1 for joined, 2 for started, 3 for quit, 4 for finished
        uint8 gameState;

        // address of player 1
        address player1;

        // address of player 2
        address player2;

        // total number of moves played in the game
        uint stepsPlayed;
    }

    Game[] public gameList;


    event GameCreated(uint gameId);
    event GameJoined(uint gameId, address player, uint8 playerNumber);
    event GameStarted(uint gameId);
    event GameFinished(uint gameId, uint8 winner, uint stepsPlayed);
    event GameStep(uint gameId, uint8 playerNumber, uint8 x, uint8 y, uint step);


    constructor() {}

    function getGame(uint _gameId) public view returns (Game memory) {
        return gameList[_gameId];
    }

    function getBoard(uint _gameId) public view returns (uint8[3][3] memory) {
        return gameList[_gameId].board;
    }

    function getBoardItem(uint _gameId, uint8 _x, uint8 _y) public view returns (uint8) {
        return gameList[_gameId].board[_x][_y];
    }

    function getTurn(uint _gameId) public view returns (uint8) {
        return gameList[_gameId].turn;
    }

    function getStepsPlayed(uint _gameId) public view returns (uint) {
        return gameList[_gameId].stepsPlayed;
    }

    function getGamePlayerNumber(uint _gameId, address _player) public view returns (uint8 playerNumber) {
        Game memory game = gameList[_gameId];
        if (game.player1 == _player) {
            return 1;
        } else if (game.player2 == _player) {
            return 2;
        } else {
            revert("Player not found");
        }
    }

    function getGamePlayerAddress(uint _gameId, uint8 _playerNumber) public view returns (address player) {
        Game memory game = gameList[_gameId];
        if (_playerNumber == 1) {
            return game.player1;
        } else if (_playerNumber == 2) {
            return game.player2;
        } else {
            revert("Player not found");
        }
    }


    function createNewGame() public returns (uint) {
        Game memory game = Game({
            gameId: gameList.length,
            board: [
                [0, 0, 0],
                [0, 0, 0],
                [0, 0, 0]
            ],
            turn: 0,
            winner: 0,
            player1: msg.sender,
            player2: address(0),
            stepsPlayed: 0,
            gameState: 0
        });

        gameList.push(game);

        emit GameCreated(game.gameId);

        return game.gameId;
    }

    function joinGame(uint _gameId) public returns (uint) {
        require(_gameId < gameList.length);
        require(gameList[_gameId].gameState == 0);
        require(gameList[_gameId].player2 == address(0));

        Game memory game = gameList[_gameId];

        game.player2 = msg.sender;
        game.gameState = 1;

        gameList[_gameId] = game;

        emit GameJoined(game.gameId, msg.sender, 2);

        return game.gameId;
    }

    function startGame(uint _gameId) public returns (uint) {
        require(_gameId < gameList.length);
        require(gameList[_gameId].gameState == 1);
        require(gameList[_gameId].player2 != address(0));

        Game memory game = gameList[_gameId];

        game.gameState = 2;
        game.turn = 1;

        gameList[_gameId] = game;

        emit GameStarted(game.gameId);

        return game.gameId;
    }

    // this has not been tested
    function checkWin(uint _gameId) public view returns (uint8 winner) {
        require(_gameId < gameList.length);
        // require(gameList[_gameId].gameState == 2);

        Game memory game = gameList[_gameId];
        uint8[3][3] memory board = game.board;

        // check rows
        if (board[0][0] == board[0][1] && board[0][1] == board[0][2]) return board[0][0];
        if (board[1][0] == board[1][1] && board[1][1] == board[1][2]) return board[1][0];
        if (board[2][0] == board[2][1] && board[2][1] == board[2][2]) return board[2][0];
    
        // check columns
        if (board[0][0] == board[1][0] && board[1][0] == board[2][0]) return board[0][0];
        if (board[0][1] == board[1][1] && board[1][1] == board[2][1]) return board[0][1];
        if (board[0][2] == board[1][2] && board[1][2] == board[2][2]) return board[0][2];
        
        // check diagonals
        if (board[0][0] == board[1][1] && board[1][1] == board[2][2]) return board[0][0];  
        if (board[0][2] == board[1][1] && board[1][1] == board[2][0]) return board[0][2];

        return 0;
    }

    // player number problem
    function move(uint _gameId, uint8 _playerNumber, uint8 x, uint8 y) public returns (uint) {
        require(_gameId < gameList.length);

        Game memory game = gameList[_gameId];

        require(game.gameState == 2);

        if (_playerNumber == 1) {
            require(game.player1 == msg.sender);
            require(game.turn == 1);
        } else if (_playerNumber == 2) {
            require(game.player2 == msg.sender);
            require(game.turn == 2);
        } else {
            revert("Player not found");
        }

        require(gameList[_gameId].board[x][y] == 0);

        game.board[x][y] = _playerNumber;
        game.stepsPlayed++;

        emit GameStep(game.gameId, _playerNumber, x, y, game.stepsPlayed);

        uint8 winner = checkWin(_gameId);

        // if no winner, switch turn
        if (winner == 0) {
            game.turn = 3 - _playerNumber;

            if (game.stepsPlayed == 9) {
                game.gameState = 4;
                game.winner = 3;

                emit GameFinished(game.gameId, winner, game.stepsPlayed);
            }

        } else {
            game.winner = winner;
            game.gameState = 4;

            emit GameFinished(game.gameId, winner, game.stepsPlayed);
        }

        gameList[_gameId] = game;
        return game.gameId;
    }

    function quitGame(uint _gameId) public returns (uint) {
        require(_gameId < gameList.length);
        require(gameList[_gameId].gameState == 2);
        require(gameList[_gameId].player1 == msg.sender || gameList[_gameId].player2 == msg.sender);

        Game memory game = gameList[_gameId];

        game.gameState = 3;
        game.winner = 0;

        emit GameFinished(game.gameId, game.winner, game.stepsPlayed);

        gameList[_gameId] = game;
        return game.gameId;
    }

    // fallback
    fallback() external payable {
        revert("Don't send money here");
    }

    // receive ETH
    receive() external payable {
        revert("Don't send money here");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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