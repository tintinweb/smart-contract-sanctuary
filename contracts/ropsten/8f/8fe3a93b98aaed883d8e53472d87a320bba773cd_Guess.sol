/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Guess{
    uint entropy = 0;
    uint round = 1;

    struct player {
        address adr;
        string name;
        uint8 num;
    }

    player[] players;
    player[] winners;

    event RoundPlayer(uint number, address addr, string name, uint num, string result);
    event Round(uint number, uint winNumber);

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
        emit Round(round, num);
        string memory result;
        for (uint i = 0; i < players.length; i++){
            if (players[i].num == num) {
                result = "Won in the round";
                winners.push(players[i]);
            }
            else {
                result = "Lost in the round";
            }
            emit RoundPlayer(round, msg.sender, players[i].name, players[i].num, result);
        }
        round++;
        delete players;
    }

    function getResult() public view returns (player[] memory){
        return winners;
    }
}