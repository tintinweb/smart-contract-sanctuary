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

  
    function getSeed_1(address user, uint256 _blocktime,uint256 _blockdiff) external view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(user, seed, _blocktime, _blockdiff)));
    }

    function getSeed_2(address user,uint256 _blocknumber, uint256 _blocktime,  uint256 _blockgaslimit, uint256 _blockdiff) external view returns (uint256) {
       return uint256(keccak256(abi.encodePacked(user, seed, _blocktime, _blocknumber, _blockgaslimit, _blockdiff)));
    }

    function setSeed(uint256 seedNumber) external {
        seed = seedNumber;
    }

    function getBlockTime(uint256 _zero) external view returns (uint256) {
        return block.timestamp+_zero;
    }

    function getBlockNumber(uint256 _zero) external view returns (uint256) {
        return block.number+_zero;
    }

     function getBlockGaslimit(uint256 _zero) external view returns (uint256) {
        return block.gaslimit+_zero;
    }

    function getBlockDiff(uint256 _zero) external view returns (uint256) {
        return block.difficulty+_zero;
    }
    
}