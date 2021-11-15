// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library MathAF{
    
  function random() external view returns (uint256) {
    uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    return randomHash;
  }

  // Picks a value from 0 (inclusive) to range (exclusive)
  function randomRange(uint256 range) external view returns (uint256) {
    if(range == 0)
      return 0;
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % range;
  }

  // Bitshift operator that works on integers
  function shiftLeft(uint32 input, uint32 shift) external pure returns(uint32){
    bytes4 shifted = bytes4(input) << shift;
    return uint32(shifted);
  }

  function repeat(uint256 value, uint256 range) external pure returns(uint256){
    return value % range;
  }
}

