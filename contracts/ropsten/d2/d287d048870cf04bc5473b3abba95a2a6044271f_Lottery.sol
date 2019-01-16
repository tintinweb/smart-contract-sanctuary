// Nathan Tokala
// nct217
// Lottery Example

pragma solidity ^0.4.0;
contract Lottery{

    struct Player {
        address playerAddress;
        uint weight;
        bool playing;
        uint betAmount;
    }
    struct Game {
        uint playerCount;
        uint totalBet;
        uint minBet;
    }

    address owner;
    mapping(uint => Player) players;
    Game game;

    /// Create a new lottery with minBet of betAmount
    function Lottery(uint betAmount) public payable {
        owner = msg.sender;
        game.playerCount = 0;
        game.minBet = betAmount;
        game.totalBet =  0;
    }

    /// enter the game, address of entering user, and the bet sent
    function enterGame(address inPlayer, uint inBet) public payable returns(bool) {
        require(inBet >= game.minBet);
        
        // make sure that the inBet matches the value of the message
        require(msg.value ==  inBet);
        
        // make the user a player
        players[game.playerCount].playing = true;
        players[game.playerCount].betAmount = inBet;
        players[game.playerCount].playerAddress = inPlayer;
        game.totalBet += inBet;
        game.playerCount += 1;
        
        // if theres 5 players, roll the dice
        if (game.playerCount >= 5) {
            endGame();
            return true;
        }
        return true;
    }
    
    function endGame() private returns(uint) {
        
        // pay out to user;
        uint rand = uint(keccak256(block.difficulty, now, game.playerCount))%(game.playerCount+1);
        players[rand].playerAddress.transfer(game.totalBet);
        
        // reset game
        // dont need to selfdestruct, wastes gas, just reset and move on
        game.playerCount = 0;
        game.totalBet =  0;
        return rand;
    }

}