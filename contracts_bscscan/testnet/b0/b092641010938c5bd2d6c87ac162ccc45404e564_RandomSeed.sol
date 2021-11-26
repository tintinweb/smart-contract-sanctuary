/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: ZAY
pragma solidity >=0.4.22 <0.9.0;

contract RandomSeed {

  address public admin;

  uint256 public seed;

  constructor(address _admin) {
    admin = _admin;
  }

  
    function getRandomSeed(address user,uint _blocktime,uint _blockdiff) external view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(user, seed, _blocktime, _blockdiff)));
    }

    function getBlockTime() external view returns (uint) {
        return block.timestamp;
    }

    function getBlockDiff() external view returns (uint) {
        return block.difficulty;
    }
    
}