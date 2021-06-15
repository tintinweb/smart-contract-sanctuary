/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

contract Lottery {
    
    string public result;
    // just for test
    string  [10] gift = ['iPhone 12', 'iPhone 12 Pro', 'iPhone SE', 'iPhone 11', 'iPhone XR', 'iPad', 'iPad Air', 'iPad Pro', 'iPad mini', 'Mac Pro'];
    event Result(string);
    
    constructor() public {
    }

    function getRandom() private view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)))%(10);
        return random;
    }
    
    function openLottery() public returns(string memory) {
        uint256 index = getRandom();
        result = gift[index];
        emit Result(result);
        return result;
    }
}