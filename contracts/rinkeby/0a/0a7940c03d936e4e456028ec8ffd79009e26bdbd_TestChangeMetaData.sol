/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestChangeMetaData {
    struct Hero {
        uint256 eyes;
        bool used;
    }

    mapping(uint256 => Hero) public tokenIdToHero;
    uint256[] public heros;

    function createAndAssignHero() public {
        Hero storage hero1  = tokenIdToHero[1];
        hero1.eyes = 1;
        hero1.used = false;
    }

    function changeToUsed(uint256 _tokenId) public {
        tokenIdToHero[_tokenId].used = true;
    }

}