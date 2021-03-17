// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";


contract randtest {

    using SafeMath for uint256;
    
    uint public randNonce = 0;
      constructor() {
   }
    function getrandnumber() public view returns (uint, uint) {
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))).mod(100);
        randNonce.add(1);
        uint random2 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))).mod(100);
        return (random, random2);
    }
}