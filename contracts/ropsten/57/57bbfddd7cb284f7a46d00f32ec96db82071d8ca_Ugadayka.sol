/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Ugadayka  {
    uint entropy = 0;
    struct player{
        address adr;
        string nickname;
        uint chislo;
    }
    player[] players;
    player[] winners;

    function PlayerMove(string memory name, uint chislo) public {
        require(chislo>=1 && chislo<=10, "SIKE. THAT S THE WRONG NUMBER");
        players.push(player(msg.sender, name, chislo));

        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(abi.encode(name)));
        uint hashNum = uint(keccak256(abi.encode(chislo)));

        entropy += uint(keccak256(abi.encode(hashBlock % 1000 + hashName % 1000 + hashNum % 1000)));
        if (players.length == 5) game();
    }

    function game()private{
        delete winners;
        uint ch = entropy % 10 + 1;
        for(uint i = 0; i <= players.length; i++){
            if (ch == players[i].chislo) {
                winners.push(players[i]);
            }
        }
        delete players;

    }

    function getRes() public view returns(player[] memory){
        return winners;
    }

}