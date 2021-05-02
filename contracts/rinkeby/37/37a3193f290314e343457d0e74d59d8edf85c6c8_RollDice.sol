/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.4.24;


contract RollDice {

    address public owner;

    struct Game {
        uint amount;
        string uuid;
        bytes32 secretHash;
        address player;
        uint chance;
    }

    mapping(string => Game) games;

    function RollDice() public {
        owner = msg.sender;
    }


    function initializeGame(string uuid, bytes32 secretHash, uint chance) public {
        Game storage game = games[uuid];
        
        bytes32 asd = keccak256(game.uuid);
        bytes32 qwe = keccak256(uuid);
        
        require(asd!= qwe);

        game.amount = msg.value;
        game.uuid = uuid;
        game.secretHash = secretHash;
        game.player = msg.sender;
        game.chance = chance;
    }

    function finalizeGame(string uuid, uint secret) public {
        Game storage game = games[uuid];
        
        bytes32 asd = keccak256(game.uuid);
        bytes32 qwe = keccak256(uuid);
        
        require(asd == qwe);
        

        //require(keccak256(secret) == game.secretHash);

        if ((block.timestamp + uint(blockhash(block.number)) + secret) % 100 + 1 <= game.chance) {
            msg.sender.transfer(msg.value * 99 / game.chance);
        }
    }
}