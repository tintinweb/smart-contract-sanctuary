/**
 *Submitted for verification at polygonscan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Rnd {
    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
}
}