/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TicTacToe
 * @dev TicTacToe game
 */

contract TicTacToe {
    enum Symbol {
        EMPTY,
        X,
        O
    }
    enum Status {
        WAITING_FOR_PLAYER,
        PLAYER_ONE_MOVE,
        PLAYER_TWO_MOVE,
        PLAYER_ONE_WON,
        PLAYER_TWO_WON,
        BOT_WON,
        DRAW
    }
    enum GameType {
        BOT,
        PLAYER
    }

    struct Game {
        // Players
        address playerOne;          // Player 1 X
        address playerTwo;          // Player 2 O
        // Symbol
        Symbol playerOneSymbol;
        Symbol playerTwoSymbol;
        // Status
        Status gameStatus;
        GameType gameType;
        uint256 bet;                // converted to wei
        Symbol[9] board;
    }

    struct Player {
        address player;
        uint256 score;
    }

    mapping(address => uint256) public players;     // mapping to store player and the gameId
    mapping(uint256 => Game) public games;          // mapping to store the player's board with gameId
    mapping(address => uint256) public scoreboard;
    mapping(uint256 => Player) public leaderboard;

    address[] public playersArray;
    uint256[] public gamesArray;

    function createGame(uint256 _bet, bool isBot) public {
        uint256 gameId = gamesArray.length;
        uint256 betAmt = _bet * (1 ether);          //in wei, to be used for v2.0
        gamesArray.push(gameId);
        players[msg.sender] = gameId;

        games[gameId] = Game({
            playerOne: msg.sender,
            playerTwo: address(0),
            playerOneSymbol: Symbol.X,
            playerTwoSymbol: Symbol.EMPTY,
            gameStatus: Status.WAITING_FOR_PLAYER,
            gameType: GameType.PLAYER,
            bet: betAmt,
            board: [
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY,
                Symbol.EMPTY
            ]
        });

        Game storage board = games[gameId];

        if (isBot) {
            board.gameType = GameType.BOT;
            board.playerTwoSymbol = Symbol.O;

            if (generateRandomStart() == 1) {       //bot starts if generateRandomStart returns 1
                int256 move = botMove(
                    board.board,
                    board.playerTwoSymbol,
                    board.playerOneSymbol
                );
                board.board[uint256(move)] = board.playerTwoSymbol;
                board.gameStatus = Status.PLAYER_TWO_MOVE;
            } else {
                board.gameStatus = Status.PLAYER_ONE_MOVE;
            }
        }
    }

    // function for player two to join a board
    function joinGame(uint256 _gameId)
        public
        returns (bool success, string memory reason)
    {
        if (gamesArray.length == 0 || _gameId > gamesArray.length) {
            return (false, "No such game exists.");
        }

        address player = msg.sender;
        Game storage game = games[_gameId];

        if (player == game.playerOne) {
            return (false, "You can't play against yourself.");
        }

        players[player] = _gameId;

        // Assign the new player to slot 2 if it is empty.
        if (game.playerTwoSymbol == Symbol.EMPTY) {
            game.playerTwo = player;
            game.playerTwoSymbol = Symbol.O;
            game.gameStatus = Status.PLAYER_ONE_MOVE;
            return (
                true,
                "Joined as player Two player. Player one can make the first move."
            );
        }
        return (false, "All seats taken.");
    }

    // check for win / loss
    function evaluate(
        Symbol[9] memory gameboard,
        Symbol player,
        Symbol opponent
    ) internal pure returns (int256) {
        uint8[3][8] memory winningStates = [
            [0, 1, 2],
            [3, 4, 5],
            [6, 7, 8],
            [0, 3, 6],
            [1, 4, 7],
            [2, 5, 8],
            [0, 4, 8],
            [6, 4, 2]
        ];

        for (uint8 i = 0; i < winningStates.length; i++) {
            uint8[3] memory winningState = winningStates[i];
            if (
                gameboard[winningState[0]] == player &&
                gameboard[winningState[1]] == player &&
                gameboard[winningState[2]] == player
            ) {
                return 1;
            } else if (
                gameboard[winningState[0]] == opponent &&
                gameboard[winningState[1]] == opponent &&
                gameboard[winningState[2]] == opponent
            ) {
                return -1;
            }
        }
        return 0;
    }

    function isMovesLeft(Symbol[9] memory gameboard)
        internal
        pure
        returns (bool)
    {
        for (uint8 i = 0; i < gameboard.length; i++) {
            if (gameboard[i] == Symbol.EMPTY) {
                return true;
            }
        }
        return false;
    }

    function makeMove(uint8 position) public returns (string memory) {
        uint256 gameID = players[msg.sender];
        Game storage _game = games[gameID];

        Symbol playerSymbol;
        Symbol otherPlayerSymbol;
        Symbol boardPosition = _game.board[position];

        // Check that game is still in IN_PROGRESS
        require(
            _game.gameStatus == Status.PLAYER_ONE_MOVE ||
                _game.gameStatus == Status.PLAYER_TWO_MOVE
        );

        // Check if it is a valid position
        require(position >= 0 && position <= 8);

        // Check if a piece is already there
        require(boardPosition == Symbol.EMPTY);

        if (_game.playerOne == msg.sender) {
            playerSymbol = _game.playerOneSymbol;
            otherPlayerSymbol = _game.playerTwoSymbol;
        } else {
            playerSymbol = _game.playerTwoSymbol;
            otherPlayerSymbol = _game.playerOneSymbol;
        }

        // Make the move
        _game.board[position] = playerSymbol;

        if (_game.gameType == GameType.BOT) {
            if (evaluate(_game.board, playerSymbol, otherPlayerSymbol) == 1) {
                _game.gameStatus = Status.PLAYER_ONE_WON;
                updateScoreboard();
                updateLeaderboard();
                return "win";
            }

            //bot move
            int256 move = botMove(_game.board, otherPlayerSymbol, playerSymbol);
            _game.board[uint256(move)] = otherPlayerSymbol;

            if (evaluate(_game.board, otherPlayerSymbol, playerSymbol) == 1) {
                _game.gameStatus = Status.BOT_WON;
                return "lost";
            }

            if (isMovesLeft(_game.board) == false) {
                _game.gameStatus = Status.DRAW;
                return "draw"; //wager goes to bot
            }
        } else if (_game.gameType == GameType.PLAYER) {
            //check win
            if (evaluate(_game.board, playerSymbol, otherPlayerSymbol) == 1) {
                if (playerSymbol == _game.playerOneSymbol) {
                    _game.gameStatus = Status.PLAYER_ONE_WON;
                } else {
                    _game.gameStatus = Status.PLAYER_TWO_WON;
                }

                updateScoreboard();
                updateLeaderboard();

                return "win";
            }

            if (isMovesLeft(_game.board) == false) {
                _game.gameStatus = Status.DRAW;

                return "draw";
            }
        }
        return "next move";
    }

    // returns details about the board the player is on
    function getBoard()
        public
        view
        returns (
            Symbol[9] memory,
            Symbol symbol,
            Status status,
            GameType gameType,
            uint256 gameId,
            address otherPlayer
        )
    {
        uint256 _gameId = players[msg.sender];
        Game storage game = games[_gameId];
        Symbol playerSymbol = (game.playerOne == msg.sender)
            ? game.playerOneSymbol
            : game.playerTwoSymbol;

        address _otherPlayer = (game.playerOne == msg.sender)
            ? game.playerTwo
            : game.playerOne;
        return (
            games[_gameId].board,
            playerSymbol,
            game.gameStatus,
            game.gameType,
            _gameId,
            _otherPlayer
        );
    }

    //=============bot=============
    function generateRandomStart() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        playersArray
                    )
                )
            ) % 2;
    }

    // algorithm for bot to decide next move
    function botMove(
        Symbol[9] memory board,
        Symbol botSymbol,
        Symbol playerSymbol
    ) internal pure returns (int256) {
        // Put centre if possible
        if (board[4] == Symbol.EMPTY) {
            return 4;
        }

        for (int256 i = 0; i < int256(board.length); i++) {
            if (board[uint256(i)] == Symbol.EMPTY) {
                board[uint256(i)] = botSymbol;

                // If can win, win
                int256 score = evaluate(board, botSymbol, playerSymbol);
                if (score == 1) {
                    return i;
                }

                // Remove
                board[uint256(i)] = Symbol.EMPTY;
            }
        }

        // If opponent is 1 away from winning
        for (int256 i = 0; i < int256(board.length); i++) {
            if (board[uint256(i)] == Symbol.EMPTY) {
                // Opponent move
                board[uint256(i)] = playerSymbol;

                int256 oppScore = evaluate(board, playerSymbol, botSymbol);

                // If opponent can win with one more move, block it
                if (oppScore == 1) {
                    return i;
                }
            }
        }

        // Place it somewhere along the path of the opponents move
        for (int256 i = 0; i < int256(board.length); i++) {
            if (board[uint256(i)] == playerSymbol) {
                for (int256 j = -4; i < 5; j++) {
                    if (j + i >= 0 && j + i < 9) {
                        return j + i;
                    }
                }
            }
        }
        return -1;
    }

    //=============leaderboard=============
    function updateScoreboard() internal {
        scoreboard[msg.sender] += 1;
    }

    function getScore(address player) public view returns (uint256) {
        return scoreboard[player];
    }

    function updateLeaderboard() internal {
        uint256 maxLen = 10;
        uint256 playerScore = getScore(msg.sender);

        uint256 numOfPlayers = playersArray.length;
        if (numOfPlayers < 10) {
            bool duplicate = false;
            for (uint256 i = 0; i < numOfPlayers; i++) {
                if (msg.sender == leaderboard[i].player) {
                    leaderboard[i] = Player({
                        player: msg.sender,
                        score: playerScore
                    });
                    duplicate = true;
                }
            }
            if (!duplicate) {
                leaderboard[numOfPlayers] = Player({
                    player: msg.sender,
                    score: playerScore
                });
            }
        } else {
            if (playerScore > leaderboard[maxLen - 1].score) {
                for (uint256 i = 0; i < maxLen; i++) {
                    if (playerScore > leaderboard[i].score) {
                        if (msg.sender == leaderboard[i].player) {
                            leaderboard[i] = Player({
                                player: msg.sender,
                                score: playerScore
                            });
                        } else {
                            //shift down
                            Player memory currPlayer = leaderboard[i];
                            for (uint256 j = i + 1; j < maxLen + 1; j++) {
                                Player memory nextPlayer = leaderboard[j];
                                leaderboard[j] = currPlayer;
                                currPlayer = nextPlayer;
                            }
                            leaderboard[i] = Player({
                                player: msg.sender,
                                score: playerScore
                            });
                        }
                    }
                }
                delete leaderboard[maxLen];
            }
        }
    }

    //=============stats=============
    function getNumofGames() public view returns (uint256) {
        return gamesArray.length;
    }

    function gameStats()
        public
        view
        returns (
            uint256 openGame,
            uint256 gameInProgress,
            uint256 gameComplete
        )
    {
        uint256 open = 0;
        uint256 inProgress = 0;
        uint256 complete = 0;

        for (uint256 i = 0; i < gamesArray.length; i++) {
            Game storage game = games[i];
            if (game.gameStatus == Status.WAITING_FOR_PLAYER) {
                open++;
            } else if (
                game.gameStatus == Status.PLAYER_ONE_MOVE ||
                game.gameStatus == Status.PLAYER_TWO_MOVE
            ) {
                inProgress++;
            } else {
                complete++;
            }
        }
        return (open, inProgress, complete);
    }

    // 10 most recent games that are available
    function availGames()
        public
        view
        returns (
            uint256[] memory gameId,
            uint256[] memory bet,
            address[] memory playerOneId
        )
    {
        (uint256 openGames, , ) = gameStats();
        uint256 maxLen = 10;
        uint256[] memory gameIds = new uint256[](maxLen);
        uint256[] memory bets = new uint256[](maxLen);
        address[] memory playerOneIds = new address[](maxLen);

        uint256 noGames = 0;
        uint256 maxGames = 0;
        if (gamesArray.length < 10) {
            noGames = 0;
            maxGames = gamesArray.length;
        } else {
            noGames = gamesArray.length - 10;
            maxGames = gamesArray.length;
        }

        for (uint256 i = noGames; i < maxGames; i++) {
            uint256 j = 0;
            Game storage game = games[i];
            if (
                game.gameStatus == Status.WAITING_FOR_PLAYER &&
                game.playerOne != address(0)
            ) {
                gameIds[j] = i;
                bets[j] = game.bet;
                playerOneIds[j] = game.playerOne;
                j++;
            }
        }
        return (gameIds, bets, playerOneIds);
    }
}