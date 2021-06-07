/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Bitmap {
  mapping(uint256 => uint256) public claimed_bitmap;             // #claimers/256 #claimers%25   source: Uniswap
  uint256 public weird_fraction;
  string regina;

  constructor(string memory _regina) {
      regina = _regina;
  }

  function set_claimed(uint256 index) internal {
        claimed_bitmap[index/256] = (1 << (index%256)) | (claimed_bitmap[index/256]);
        weird_fraction = index/256;
    }
}