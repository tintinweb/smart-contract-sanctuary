/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILoot {
    function claim(uint256 tokenId) external;
}

contract BatchLoot {
    function claim(address loot, uint[] calldata ids) public {
        for (uint i = 0; i < ids.length; i++) {
            ILoot(loot).claim(ids[i]);
        }
    }
}