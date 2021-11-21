/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Kudos
 * @dev Store & retrieve value in a variable
 */
contract Kudos {
    mapping (address => Kudo[]) allKudos;
    function giveKudos(address who, string memory what, string memory comments) public {
        Kudo memory kudo = Kudo(what, msg.sender, comments);
        allKudos[who].push(kudo);
    }
    function getKudosLenght(address who)public view returns (uint)
    {
       Kudo[] memory allKudosForWho = allKudos[who]; 
       return allKudosForWho.length;
    }
    function getKudosAtIndex(address who, uint idx) public view returns (string memory, address, string memory) {
        Kudo memory kudo1 = allKudos[who][idx];
        return (kudo1.what, kudo1.giver, kudo1.comments);
    }
}

struct Kudo
{
    string what;
    address giver;
    string comments;
}