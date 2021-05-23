/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.4.24;


contract RollDice {

    address public owner;

    uint constant MAX_CHANCE = 98;
    uint constant MIN_CHANCE = 1;
    
    uint constant MIN_BET = 0.01 ether;
    
    uint public MAX_WON;

    uint public potential_loss;

    event Transfer(uint amount_bet, uint amount_won);

    struct Game {
        uint amount;
        string uuid;
        bytes32 secretHash;
        address player;
        uint chance;
        bool finished;
    }

    mapping(string => Game) games;

    function RollDice() payable public {
        owner = msg.sender;
    }


    function setMaxWon(uint max_won) public {
        MAX_WON = max_won;
    }


    function calculate_won(uint amount, uint chance) private returns (uint){
        return amount * 99 / chance;
    }

    function initializeGame(string uuid, bytes32 secretHash, uint chance) payable public {
        Game storage game = games[uuid];
        
        require(keccak256(game.uuid)!= keccak256(uuid), "Bet already in progress!");
        
        require(chance>=MIN_CHANCE && chance<=MAX_CHANCE, "Invalid chance!");
        
        
        
        require(msg.value >= MIN_BET, "Bet should be greater than MIN_BET!");
        
        require( calculate_won(msg.value, chance) <= MAX_WON , "You cannot win more than max won!");
        
        require( msg.value <= chance*(this.balance - potential_loss )/(10*(99-chance)) ,  "You cannot win more than 10 percent!");
        
        

        // We accepted bet!
       

        game.amount = msg.value;
        game.uuid = uuid;
        game.secretHash = secretHash;
        game.player = msg.sender;
        game.chance = chance;
        game.finished = false;
        
         
        potential_loss += calculate_won(game.amount, game.chance);
        
    }

    function finalizeGame(string uuid, uint secret) payable  public {
        Game storage game = games[uuid];
        
        require(keccak256(game.uuid)== keccak256(uuid));
        
        require(keccak256(secret) == game.secretHash);
        
        require(game.finished == false);
        
        game.finished = true;
        
        

        if ((block.timestamp + uint(blockhash(block.number)) + secret) % 100 + 1 <= game.chance) {
            game.player.transfer(calculate_won(game.amount, game.chance));
            emit Transfer(game.amount ,calculate_won(game.amount, game.chance));
        } else {
            emit Transfer(game.amount , 0 );
        }
        
        potential_loss -= calculate_won(game.amount, game.chance);
    
    }
}