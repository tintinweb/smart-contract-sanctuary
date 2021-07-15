/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

contract RpsGame is SafeMath {
    ///  Constant definition
    uint8 public constant NONE = 0;
    uint8 public constant ROCK = 10;
    uint8 public constant PAPER = 20;
    uint8 public constant SCISSORS = 30;
    uint8 public constant DEALERWIN = 201;
    uint8 public constant PLAYERWIN = 102;
    uint8 public constant DRAW = 101;

    event CreateGame(uint256 gameid, address dealer, uint256 amount);
    event JoinGame(uint256 gameid, address player, uint256 amount);
    event Reveal(uint256 gameid, address player, uint8 choice);
    event CloseGame(
        uint256 gameid,
        address dealer,
        address player,
        uint8 result
    );

    ///  struct of a game
    struct Game {
        uint256 listPointer;
        uint256 gameId;
        uint256 expireTime;
        address dealer;
        uint256 dealerValue;
        bytes32 dealerHash;
        uint8 dealerChoice;
        address player;
        uint8 playerChoice;
        uint256 playerValue;
        uint8 result;
        bool closed;
    }

    // struct of a game
    mapping(uint8 => mapping(uint8 => uint8)) public payoff;
    mapping(uint256 => Game) public games;
    mapping(address => uint256[]) public gameidsOf;

    //Current game maximun id(initial from 0)
    uint256 public maxgame = 0;
    uint256 public expireTimeLimit = 60 minutes;
    uint256[] public gameList;

    // Initialization contract
    constructor() {
        payoff[ROCK][ROCK] = DRAW;
        payoff[ROCK][PAPER] = PLAYERWIN;
        payoff[ROCK][SCISSORS] = DEALERWIN;
        payoff[PAPER][ROCK] = DEALERWIN;
        payoff[PAPER][PAPER] = DRAW;
        payoff[PAPER][SCISSORS] = PLAYERWIN;
        payoff[SCISSORS][ROCK] = PLAYERWIN;
        payoff[SCISSORS][PAPER] = DEALERWIN;
        payoff[SCISSORS][SCISSORS] = DRAW;
        payoff[NONE][NONE] = DRAW;
        payoff[ROCK][NONE] = DEALERWIN;
        payoff[PAPER][NONE] = DEALERWIN;
        payoff[SCISSORS][NONE] = DEALERWIN;
        payoff[NONE][ROCK] = PLAYERWIN;
        payoff[NONE][PAPER] = PLAYERWIN;
        payoff[NONE][SCISSORS] = PLAYERWIN;
    }

    function isGame(uint256 gameId) public view returns (bool isIndeed) {
        if (gameList.length == 0) return false;
        return (gameList[games[gameId].listPointer] == gameId);
    }

    function getGameCount() public view returns (uint256 gameCount) {
        return gameList.length;
    }

    function deleteGame(uint256 gameId) public returns (bool success) {
        require(isGame(gameId));
        uint256 rowToDelete = games[gameId].listPointer;
        uint256 keyToMove = gameList[gameList.length - 1];
        gameList[rowToDelete] = keyToMove;
        games[keyToMove].listPointer = rowToDelete;
        gameList.pop();
        delete games[gameId];

        return true;
    }

    function getAllGames() public view returns (uint256[] memory) {
        return gameList;
    }

    //create a game
    function createGame(bytes32 dealerHash) public payable returns (uint256) {
        require(dealerHash != 0x0);

        //maxgame = gameId
        maxgame += 1;
        require(!isGame(maxgame));

        Game storage game = games[maxgame];
        game.gameId = maxgame;
        gameList.push(maxgame);
        game.listPointer = safeSub(gameList.length, 1);
        game.dealer = msg.sender;
        game.dealerHash = dealerHash;
        game.dealerChoice = NONE;
        game.dealerValue = msg.value;
        game.expireTime = expireTimeLimit + block.timestamp;
        emit CreateGame(maxgame, game.dealer, game.dealerValue);

        return maxgame;
    }

    //join a game
    function joinGame(uint256 gameid, uint8 choice)
        public
        payable
        returns (uint256)
    {
        require(isGame(gameid));
        Game storage game = games[gameid];
        require(
            msg.value == game.dealerValue &&
                game.dealer != address(0) &&
                game.dealer != msg.sender &&
                game.playerChoice == NONE
        );
        require(!game.closed);
        require(block.timestamp < game.expireTime);
        require(checkChoice(choice));
        game.player = msg.sender;
        game.playerChoice = choice;
        game.playerValue = msg.value;
        game.expireTime = expireTimeLimit + block.timestamp;

        emit JoinGame(gameid, game.player, game.playerValue);

        return gameid;
    }

    //game creator reveal his choice that match previous dealerhash
    function revealGame(
        uint256 gameid,
        uint8 choice,
        bytes32 randomSecret
    ) public returns (bool) {
        require(isGame(gameid));
        Game storage game = games[gameid];
        bytes32 proof = getProof(msg.sender, choice, randomSecret);
        game.dealerChoice = choice;
        require(!game.closed);
        require(game.dealerChoice != NONE && game.playerChoice != NONE);
        require(game.dealerHash != 0x0);
        require(checkChoice(choice));
        require(checkChoice(game.playerChoice));
        require((game.dealer == msg.sender && proof == game.dealerHash));

        uint8 result = payoff[game.dealerChoice][game.playerChoice];
        game.result = result;

        emit Reveal(gameid, msg.sender, choice);
        require(close(gameid, result));
        return true;

    }

    //close the gmae and settle rewards
    function close(uint256 gameid, uint8 result) public returns (bool) {
        require(isGame(gameid));
        Game storage game = games[gameid];
        require(!game.closed);
        require(
            block.timestamp > game.expireTime ||
                (game.dealerChoice != NONE && game.playerChoice != NONE)
        );

        if (result == DEALERWIN) {
            require(
                payable(game.dealer).send(
                    safeAdd(game.dealerValue, game.playerValue)
                )
            );
        } else if (result == PLAYERWIN) {
            require(
                payable(game.player).send(
                    safeAdd(game.dealerValue, game.playerValue)
                )
            );
        } else if (result == DRAW) {
            require(
                payable(game.dealer).send(game.dealerValue) &&
                    payable(game.player).send(game.playerValue)
            );
            //send back players money if resulting error
        } else {
            require(
                payable(game.dealer).send(game.dealerValue) &&
                    payable(game.player).send(game.playerValue)
            );
        }
        game.closed = true;

        emit CloseGame(gameid, game.dealer, game.player, result);

        deleteGame(gameid);

        return true;
    }

    //Allow dealer claim back his bet value if no player joins his game
    function claim(uint256 gameid) public returns (bool) {
        require(isGame(gameid));
        Game storage game = games[gameid];
        require(!game.closed);
        require(game.playerChoice == NONE);
        require(game.dealerHash != 0x0);
        require(payable(game.dealer).send(game.dealerValue));

        game.closed = true;
        deleteGame(gameid);

        return true;
    }

    function getProof(
        address sender,
        uint8 choice,
        bytes32 randomSecret
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, choice, randomSecret));
    }

    function checkChoice(uint8 choice) public pure returns (bool) {
        return choice == ROCK || choice == PAPER || choice == SCISSORS;
    }
}