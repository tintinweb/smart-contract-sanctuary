/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;


contract GuessTheNumber 
{
    uint entropy = 0;
    uint round = 1;
    struct player{
        address playerAddress;
        string playerName;
        uint8 number;
    }
    
    player[] players;
    player[] winners;

    event winNumberInRound(uint round, uint8 winNumber);
    event playersInRound(uint round, address playerAddress, string playerName, uint8 number, string result);
    
    function playGuessingGame (string memory _playerName, uint8 _number)public{
        require(1 <= _number && _number <= 10);
        players.push(player(msg.sender, _playerName, _number));
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(bytes(_playerName)));
        uint hashNumber = uint(keccak256(abi.encode(_number)));
        entropy += (hashBlock % 1000 + hashName % 1000 + hashNumber % 1000);
        if(players.length == 5){
            game();
        }
    }
   
    function game()private{
        delete winners;
        string memory result;
        uint8 number = uint8(entropy % 10 + 1);
        emit winNumberInRound(round, number);
        for(uint8 i = 0; i < 5; i++){
            if(players[i].number == number){
                winners.push(players[i]);
                result = "Won in the round";
            }
            else{
                result = "Lost in the round";
            }
 
            emit playersInRound(round, players[i].playerAddress, players[i].playerName, players[i].number, result);
        }
        delete players;
        round += 1;
    }
    
    function getWinners()public view returns(player[] memory){
        return winners;
    }
}