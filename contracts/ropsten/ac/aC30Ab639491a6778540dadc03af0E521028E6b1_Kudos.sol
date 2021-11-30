/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

struct Kudo {
    address sender;
    string for_what;
    string comment;
}

contract Kudos {
    mapping (address => Kudo[]) allKudos;

    function giveKudo(address to, string memory for_what, string memory comment) public {
        Kudo memory kudo = Kudo(msg.sender, for_what, comment);
        allKudos[to].push(kudo);
    }

    function countKudos(address whose) public view returns (uint) {
        Kudo[] memory kudos = allKudos[whose];
        return kudos.length;
    }
}