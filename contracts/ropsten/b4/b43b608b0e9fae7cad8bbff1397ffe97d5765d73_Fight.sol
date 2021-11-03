/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Fight {

    uint256 xpPerMonster;
    uint256 startBlock;
    uint256 private _experience;

    constructor(uint256 _xpPerMonster) {
        xpPerMonster = _xpPerMonster;
        startBlock = block.number;
    }
    
    function experience() public view returns (uint256) {
        return _experience + xpPerMonster * (block.number - startBlock);
    }
    
    function fightNewMonster(uint256 _xpPerMonster) public {
        _experience += xpPerMonster * (block.number - startBlock);
        startBlock = block.number;
        xpPerMonster = _xpPerMonster;
    }
}