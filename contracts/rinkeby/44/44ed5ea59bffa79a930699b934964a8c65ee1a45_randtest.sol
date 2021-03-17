// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";


contract randtest {

    using SafeMath for uint256;
    
    
    
    
      constructor() {
      }
    function getrandnumber() public view returns (uint, uint) {
        uint _randNonce = uint(keccak256(abi.encodePacked(block.timestamp))).mod(10);
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))).mod(100);
        _randNonce = _randNonce.add(1);
        uint random2 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))).mod(100);
        return (random, random2);
    }
}