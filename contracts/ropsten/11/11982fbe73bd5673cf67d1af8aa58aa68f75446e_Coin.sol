/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Coin{
    uint entropy = 0;
    uint round = 1;
    
    event luckyNumber(uint, uint8);
    event playersResult(uint, address, string, uint8, string);

    struct player{
        address playerAddress;
        string playerName;
        uint8 number;
    }
    player[] players;
    player[] winners;

    function play(string calldata _name, uint8 _num)public{
        require(_num<=10);
        
        players.push(player(msg.sender, _name, _num));
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(abi.encode(_name)));
        uint hashCoin = uint(keccak256(abi.encode(_num)));
        entropy += hashCoin%1000 + hashName%1000 + hashBlock%1000;
        if(players.length == 5){
            game();
        }
    }
    
    function game()private{
        delete winners;
        uint8 result = uint8(entropy%10 + 1);
        emit luckyNumber(round, result);

        for(uint i=0;i<5;i++){
            if(players[i].number == result){
                winners.push(players[i]);
                emit playersResult(round, players[i].playerAddress, players[i].playerName, players[i].number, "Won in the round");
            }else{
                emit playersResult(round, players[i].playerAddress, players[i].playerName, players[i].number, "Lost in the round");
            }
        }
        round+=1;
        delete players;
    }

    function getWinners()public view returns(player[] memory){
        return winners;
    }
}