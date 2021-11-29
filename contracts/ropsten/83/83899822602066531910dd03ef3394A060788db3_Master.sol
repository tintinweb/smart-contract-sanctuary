/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Master {
  struct LastWrite {
    uint64 time;
    uint64 blockNum;
  }
  mapping(address => LastWrite) private _lastWrite;
  function test() public view returns(uint256){
      uint256 minted=10;
      uint256 seed = 0;
  LastWrite storage lw = _lastWrite[tx.origin];
  seed = random(seed, lw.time, lw.blockNum);
require((minted <= 15000 || ((seed >> 245) % 10) != 0),"NOOWNER");
require((seed & 0xFFFF) % 10 == 0,"ISWIZARD");
  return seed;
    }
      function random(uint256 seed, uint64 timestamp, uint64 blockNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(blockNumber > 1 ? blockNumber - 2 : blockNumber),
            timestamp,
            seed
        )));
    }
}