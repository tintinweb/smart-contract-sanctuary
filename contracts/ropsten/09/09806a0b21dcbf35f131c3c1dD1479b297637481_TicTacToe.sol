/**
 *Submitted for verification at Etherscan.io on 2021-09-17
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
        O,
        WILDCARD
    }
    
    enum PlayerStatus {
        NOT_JOINED,
        JOINED,
        BETTING,
        REVEAL
    }
    
    struct Game {
        // Players
        address playerOne; // Player 1 X
        address playerTwo; // Player 2 O
        PlayerStatus playerOneStatus;
        PlayerStatus playerTwoStatus;
        uint8[9] playerOneBoard;
        uint8[9] playerTwoBoard;
        uint8 playerOneBidPoints;
        uint8 playerTwoBidPoints;
        uint256 bet; // converted to wei
        Symbol[9] board;
    }

    struct Player {
        address player;
        uint256 score;
    }

    mapping(address => uint256) public players;     // mapping to store player and the gameId
    mapping(uint256 => Game) public games;          // mapping to store the player's board with gameId

    address[] public playersArray;
    uint256[] public gamesArray;

    function createGame() external payable {
        uint256 gameId = gamesArray.length;
        uint256 betAmt = msg.value * (1 ether);          
        
        //require(betAmt >= 0.005 ether, "Minimum bet amount is 0.005 ether.");
        //require(approveBet(_bet, msg.sender), "You do not have sufficient funds to place this bet.");
        //require(msg.value == betAmt, "Please transfer the correct amount to pot.");
        //TODO: call send to pot with a msg.value to send amt to contract

        gamesArray.push(gameId);
        players[msg.sender] = gameId;

        games[gameId] = Game({
            playerOne: msg.sender,
            playerTwo: address(0),
            playerOneStatus: PlayerStatus.JOINED,
            playerTwoStatus: PlayerStatus.NOT_JOINED,
            playerOneBoard: [0, 0, 0, 0, 0, 0, 0, 0, 0],
            playerTwoBoard: [0, 0, 0, 0, 0, 0, 0, 0, 0],
            playerOneBidPoints: 90,
            playerTwoBidPoints: 90,
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
    }

    // function for player two to join a board
    function joinGame(uint256 _gameId)
        external payable
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

        //require(approveBet(game.bet, player), "You do not have sufficient funds to match this bet.");
        require(msg.value == game.bet, "Please transfer the correct amount to pot.");

        players[player] = _gameId;

        // Assign the new player to slot 2 if it is empty.
        if (game.playerTwoStatus == PlayerStatus.JOINED) {
            return (false, "All seats taken.");
        }
        game.playerTwo = player;
        game.playerTwoStatus = PlayerStatus.JOINED;
        return (true, "Joined as player Two. You can bid for the cells now.");
    }

    function placeBids(uint8[9] memory bidsPlaced) public {
        uint256 _gameId = players[msg.sender];
        Game storage game = games[_gameId];

        if (msg.sender == game.playerOne) {
            game.playerOneBoard = bidsPlaced;
            game.playerOneStatus = PlayerStatus.BETTING;
        } else if (msg.sender == game.playerTwo) {
            game.playerTwoBoard = bidsPlaced;
            game.playerTwoStatus = PlayerStatus.BETTING;
        }
    }

    //TODO Add in reveal from both parties before evaluate
    function evaluate() public returns (string memory) {
        uint256 _gameId = players[msg.sender];
        Game storage game = games[_gameId];
        if (msg.sender == game.playerOne) {
            // Only can transition from betting -> reveal
            if (game.playerOneStatus != PlayerStatus.BETTING) {
                return "You cannot call this function yet";
            }

            game.playerOneStatus = PlayerStatus.REVEAL;
            if (game.playerTwoStatus != PlayerStatus.REVEAL) {
                return "Waiting player two to reveal";
            }
        } else if (msg.sender == game.playerTwo) {
            // Only can transition from betting -> reveal
            if (game.playerTwoStatus != PlayerStatus.BETTING) {
                return "You cannot call this function yet";
            }

            game.playerTwoStatus = PlayerStatus.REVEAL;
            if (game.playerOneStatus != PlayerStatus.REVEAL) {
                return "Waitng player one to reveal";
            }
        }

        Symbol[9] memory gameboard = game.board;

        for (uint8 i = 0; i < 9; i++) {
            if (game.playerOneBoard[i] > game.playerTwoBoard[i]) {
                gameboard[i] = Symbol.X;
            } else if (game.playerOneBoard[i] < game.playerTwoBoard[i]) {
                gameboard[i] = Symbol.O;
            } else {
                gameboard[i] = Symbol.WILDCARD;
            }
        }

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

        int256 playerOneCount = 0;
        int256 playerTwoCount = 0;

        for (uint8 i = 0; i < winningStates.length; i++) {
            uint8[3] memory winningState = winningStates[i];
            if (
                (gameboard[winningState[0]] == Symbol.X ||
                    gameboard[winningState[0]] == Symbol.WILDCARD) &&
                (gameboard[winningState[1]] == Symbol.X ||
                    gameboard[winningState[1]] == Symbol.WILDCARD) &&
                (gameboard[winningState[2]] == Symbol.X ||
                    gameboard[winningState[2]] == Symbol.WILDCARD)
            ) {
                playerOneCount++;
            } else if (
                ((gameboard[winningState[0]] == Symbol.O ||
                    gameboard[winningState[0]] == Symbol.WILDCARD) &&
                    (gameboard[winningState[1]] == Symbol.O ||
                        gameboard[winningState[1]] == Symbol.WILDCARD) &&
                    (gameboard[winningState[2]] == Symbol.O ||
                        gameboard[winningState[2]] == Symbol.WILDCARD))
            ) {
                playerTwoCount++;
            }
        }

        if (playerOneCount > playerTwoCount) {
            payOutWinnings(payable(game.playerOne), game.bet * 2);
            return "Player One Won";
        } else if (playerOneCount < playerTwoCount) {
            payOutWinnings(payable(game.playerTwo), game.bet * 2);
            return "Player Two Won";
        } else {
            payOutWinnings(payable(game.playerOne), game.bet);
            payOutWinnings(payable(game.playerTwo), game.bet);
            return "Draw";
        }
    }


    //=============wager=============
    function initializePot() external payable {
    }
    
    function getPotAmt() public view returns (uint256) {
        return address(this).balance /(1 ether);
    }
    
    function getPlayerBalance(address player) external view returns(uint256) { //for debugging
        return player.balance / (1 ether) ;
    }

    function approveBet(uint256 bet, address player) public view returns (bool) {
        if (player.balance/(1 ether) >= bet) {
            return true;
        } else {
            return false;
        }
    }
    
    //can only call from outside contract!!!!
    function sendToPot() external payable {
        uint256 _gameId = players[msg.sender];
        uint256 betAmt = games[_gameId].bet;
        require(msg.value == betAmt, "Please transfer the correct amount to pot.");
    }
    
    //send frm smart contract to receipient
    function payOutWinnings(address payable _receiver, uint256 _amount) public {
        _receiver.transfer(_amount * (1 ether));
    }

    //returns details about the board the player is on
    //function getBoard() public view returns(uint256 _bet, address _playerOne, address _playerTwo, PlayerStatus _playerOneStatus, PlayerStatus _playerTwoStatus, uint8[9] memory boardOne, uint8[9] memory boardTwo, Symbol[9] memory board) {
    //    uint256 _gameId = players[msg.sender];
    //    Game storage game = games[_gameId];        
    //}    

    //=============stats=============
    
    /*

    // returns details about the board the player is on
    function getBoard()
        public
        view
        returns (
//            Symbol[9] memory,
            Symbol symbol,
            Status status,
//            GameType gameType,
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
//            games[_gameId].board,
            playerSymbol,
            game.gameStatus,
            _gameId,
            _otherPlayer
        );
    }    

    // returns details about the board the player is on
    function getBoard()
        public
        view
        returns (
//            Symbol[9] memory,
            Symbol symbol,
            Status status,
//            GameType gameType,
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
//            games[_gameId].board,
            playerSymbol,
            game.gameStatus,
            _gameId,
            _otherPlayer
        );
    }
    
    
    
    
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
            } else if (game.gameStatus == Status.BETTING) {
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
    */
    
}