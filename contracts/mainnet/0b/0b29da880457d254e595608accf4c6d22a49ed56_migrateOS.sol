/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract migrateOS {
    function isValidBubbleBudz(uint id_) public pure returns (bool) {
        if (id_ >> 96 != 0x00000000000000000000000078b21283e86160e943691134aa5f7961cd828630) return false;
		if (id_ & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)  return false;
		return true;
    }
   function bubbleBudsGenesisId(uint tokenId_) public pure returns (uint) {
       uint _rawId = (tokenId_ & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
       uint _fixedId = _rawId - 2;
       return _fixedId;
   }
}