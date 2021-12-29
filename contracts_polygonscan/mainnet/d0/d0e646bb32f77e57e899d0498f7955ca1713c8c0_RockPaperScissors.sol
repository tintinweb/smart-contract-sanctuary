// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.17 <0.9.0;

import "./SafeMath.sol";


contract RockPaperScissors {
    using SafeMath for uint256;

    enum Status {
        STATUS_NOT_STARTED,
        STATUS_SETUP,
        STATUS_PLAYER_JOINED,
        STATUS_BET_PLACED,
        STATUS_BETS_PLACED,
        STATUS_HOST_WIN,
        STATUS_CHALLENGER_WIN,
        STATUS_TIE,
        STATUS_ERROR,
        STATUS_CANCELLED
    }

    uint constant ROCK = 1;
    uint constant PAPER = 2;
    uint constant SCISSORS = 3;

    uint feePercentage = 1;

    address payable constant public contractOwnerAddress = payable(0x6aBF5377E3Aa97ECdbA6aB30DA99cCe7E756DfBD);
    
    uint public GAME_ID = 1;

    struct Game {
        uint gameId;
        uint hostGuess;
        uint challengerGuess;
        Status status;
        uint time;
        uint256 hostBetAmount;
        uint256 challengerBetAmount;
        address payable host;
        address payable challenger;
        string gameName;
    }

    mapping(uint => Game) public gameList; 

    event GameAdded(uint gameId, address indexed sender);
    event GameStatusUpdated(uint gameId, Status status, address indexed sender);
    event BetPlaced(uint gameId, uint guess, address indexed userAddress);
    event BetPaid(uint gameId, uint256 betAmount, address indexed userAddress);

    constructor ()  {

    }
    
    // createa a new game with eth 
    function setupGame(string memory _gameName) public payable {
        require(msg.value > 0, 'Need to send > 0 matic');
        uint gameId = GAME_ID;
        gameList[gameId] = Game(
            gameId, 
            0,
            0,
            Status.STATUS_SETUP,
            block.timestamp,
            msg.value,
            0,
            payable(msg.sender),
            payable(0),
            _gameName
        );
        GAME_ID++;
        emit GameAdded(gameId, msg.sender);
    }

    // challenger joins game here, no eth
    function joinGame(uint _gameId) public {
        Game memory game = gameList[_gameId];
        bool isHost = msg.sender == game.host;
        bool hasChallenger = address(0x00) != game.challenger;
        if (isHost) {
            revert("The host cannot rejoin the game");
        }
        if (hasChallenger) {
            revert("There is already a challenger in this game");
        }
        if (game.status > Status.STATUS_BET_PLACED) {
            revert("The game has already started");
        }
        game.challenger = payable(msg.sender);
        game.status = Status.STATUS_PLAYER_JOINED;
        gameList[_gameId] = game;
        emit GameStatusUpdated(_gameId, game.status, msg.sender);
    } 

    // host or challenger places bet
    // if challenger, eth taken here
    // if both bets placed, determines winner and pays out accordingly
    function takeBet(uint _gameId, uint _guess) public payable {
        Game memory game = gameList[_gameId];
        bool isHost = msg.sender == game.host;
        bool isChallenger = msg.sender == game.challenger;
        if (!isHost && !isChallenger) {
            revert("Must be host or challenger to place bet");
        }
        if (_guess <= 0 || _guess > 3) {
            revert("Must be a valid guess (rock, paper, scissors)");
        }
        if (game.status > Status.STATUS_BETS_PLACED) {
            revert("Bets have been placed");
        }
        
        if (isHost) {
            if (game.hostGuess != 0) {
                revert("host has already placed a bet");
            }
            game.hostGuess = _guess;
            emit BetPlaced(_gameId, game.hostGuess, game.host);
        } else if (isChallenger) {
            if (game.challengerGuess != 0) {
                revert("challenger has already placed a bet");
            }
            if (msg.value != game.hostBetAmount) {
                revert("challenger bet amount must be same as the game bet amount");
            }
            game.challengerBetAmount = msg.value;
            game.challengerGuess = _guess;
            emit BetPlaced(_gameId, game.challengerGuess, game.challenger);
            emit BetPlaced(_gameId, game.challengerGuess, game.challenger);
        } else {
            return revert("invalid take bet option");
        }
        if (game.status == Status.STATUS_BET_PLACED) {
            game.status = Status.STATUS_BETS_PLACED;
        } else {
            game.status = Status.STATUS_BET_PLACED;
        }
        emit GameStatusUpdated(_gameId, game.status, msg.sender);
        if (game.status == Status.STATUS_BETS_PLACED && game.hostGuess > 0 && game.challengerGuess > 0) {
            bool isDraw = game.hostGuess == game.challengerGuess;
            bool hostWins = (game.hostGuess == ROCK && game.challengerGuess == SCISSORS) || (game.hostGuess == PAPER && game.challengerGuess == ROCK) || (game.hostGuess == SCISSORS && game.challengerGuess == PAPER);

            uint total = game.hostBetAmount.add(game.challengerBetAmount);
            uint fee = total.div(100).mul(feePercentage);
            uint remaining = total.sub(fee);
            if (isDraw) {
                game.status = Status.STATUS_TIE;
                sendViaCall(game.host, game.hostBetAmount);
                sendViaCall(game.challenger, game.challengerBetAmount);
                emit BetPaid(_gameId, game.hostBetAmount, game.host);
                emit BetPaid(_gameId, game.challengerBetAmount, game.challenger);
            } else if (hostWins) {
                game.status = Status.STATUS_HOST_WIN;
                sendViaCall(contractOwnerAddress, fee);
                sendViaCall(game.host, remaining);
                emit BetPaid(_gameId, remaining, game.host);
            } else {
                game.status = Status.STATUS_CHALLENGER_WIN;
                sendViaCall(contractOwnerAddress, fee);
                sendViaCall(game.challenger, remaining);
                emit BetPaid(_gameId, game.hostBetAmount.add(game.challengerBetAmount), game.challenger);
            } 
            emit GameStatusUpdated(_gameId, game.status, msg.sender);
        }
        gameList[_gameId] = game;
    }
    
    // host or challenger can cancel game providing both bets haven't been placed
    // refunds happen accordingly eth
    function cancel(uint _gameId) public payable {
        Game memory game = gameList[_gameId];
        if (msg.sender != game.host && msg.sender != game.challenger) {
            revert("only host or challenger can cancel game");
        }
        if (game.status > Status.STATUS_BET_PLACED) {
            revert("game cannot be cancelled once both bets have been placed");
        }
        if (game.host != address(0x00)) {
            sendViaCall(game.host, game.hostBetAmount);
        } 
        if (game.challenger != address(0x00) && game.challengerBetAmount >= 0) {
            sendViaCall(game.host, game.challengerBetAmount);
        } 
        game.status = Status.STATUS_CANCELLED;
        gameList[_gameId] = game;
        emit GameStatusUpdated(_gameId, game.status, msg.sender);
    }

    function getGameStatus(uint _gameId) public view returns (Status) {
        return gameList[_gameId].status;
    }
    
    function getGameById (uint _gameId) public view returns (Game memory _game) {
        Game memory game = gameList[_gameId];
        if (game.status == Status.STATUS_BET_PLACED || game.status == Status.STATUS_BETS_PLACED) {
            if (game.host == msg.sender) {
                game.challengerGuess = 0;
            } else {
                game.hostGuess = 0;
            }
        }
        return game;
    }

    function getBalance() public view returns (uint) {
        uint bal = address(this).balance;
        return bal;
    }

    function withdrawRemainingBalance() public payable {
        uint bal = getBalance();
        if (bal > 0) {
            sendViaCall(contractOwnerAddress, bal);
        }
    }

    function getGames() public view returns (Game[] memory) {
        Game[] memory lGames = new Game[](GAME_ID);
        for (uint i = GAME_ID; i > 0; --i) {
            Game memory lGame = gameList[i];
            // do not return guesses here            
            if (lGame.status == Status.STATUS_SETUP || lGame.host == msg.sender || lGame.challenger == msg.sender) {
                lGame.hostGuess = 0;
                lGame.challengerGuess = 0;
                lGames[i] = lGame;
            }

        }
        return lGames;
    }

    function sendViaCall(address payable _to, uint amount) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}