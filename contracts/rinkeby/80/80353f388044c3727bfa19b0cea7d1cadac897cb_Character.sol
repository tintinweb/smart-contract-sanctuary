/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;

contract Character {
    struct Card {
        uint8 level; // up to 256 cap
    }
    Card[] private tokens;

    function store() public {
        uint8 level = 0;

        tokens.push(Card(level));
    }

    function gainXp(uint256 id) public {
        Card storage char = tokens[id];
        char.level += 1;
    }
}