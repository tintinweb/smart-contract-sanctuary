/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Safe {
    function randN(uint8 _length,uint256 dyna) public view returns(uint256) {
        uint256 randomN = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp,dyna)));
        return randomN%_length;
    }
}