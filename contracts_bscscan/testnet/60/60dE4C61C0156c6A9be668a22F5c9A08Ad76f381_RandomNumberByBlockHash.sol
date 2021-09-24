/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract RandomNumberByBlockHash{

  function getBlockHash(uint256 blockNumber) external view returns (bytes32){
        
      return blockhash(blockNumber);
  }

  function getCurrentBlockNumber() external view returns(uint256){
      return block.number;
  }

  
}