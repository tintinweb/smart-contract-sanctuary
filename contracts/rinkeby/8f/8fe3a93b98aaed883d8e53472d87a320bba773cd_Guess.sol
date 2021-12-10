/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Guess{
    uint entropy = 0;

    struct player {
        address adr;
        string name;
        uint8 num;
    }

    player[] players;
    player[] winners;

    function Step(string memory name, uint8 num) public {
        require(num >= 1 && num <= 10);
        players.push(player(msg.sender, name, num));
        uint hashBlock = uint(blockhash(block.number));
        uint hashName = uint(keccak256(bytes(name)));
        uint hashNum = uint(keccak256(abi.encode(num)));
        entropy += hashBlock % 1000 + hashName % 1000 + hashNum % 1000;
        if (players.length == 5) game();
    } 

    function game() private {
        delete winners;
        uint num = entropy % 10 + 1;
        for (uint i = 0; i < players.length; i++){
            if (players[i].num == num) winners.push(players[i]);
        }
        delete players;
    }

    function getResult() public view returns (player[] memory){
        return winners;
    }
}