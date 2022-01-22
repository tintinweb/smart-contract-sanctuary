/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract time_to_play{
    uint entropy = 0;
    
    struct player{
        address PlayerAddress;
        string name;
        uint8 number;
    }
    player[] players;
    player[] winners;

    function Action(string memory _name, uint8 _number) public{
        require(1 <= _number && _number <= 10);
        players.push(player(msg.sender, _name, _number));
        uint hashBlock = uint(blockhash(block.number-1));
        uint hashName = uint(keccak256(bytes(_name)));
        uint hashNumber = uint(keccak256(abi.encode(_number)));
        entropy += (hashBlock % 1000 + hashName % 1000 + hashNumber % 1000);
        if (players.length == 5){
            game();
        }
    }

    function game()private{
        delete winners;
        uint number = uint8(entropy % 10 + 1);
        for(uint8 i = 0; i < 5; i++){
            if(players[i].number == number){
                winners.push(players[i]);
            }
        }
        delete players;
    }

    function get_winners()public view returns(player[] memory){
        return winners;
    }
}