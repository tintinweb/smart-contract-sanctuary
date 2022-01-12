/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;
contract notarization {

    event NewHashValue(string, string, string, string, address, uint);

    function logHashValue(string memory hashValue, string memory Filename, string memory Remark, string memory Source) public {    
      emit NewHashValue(hashValue, Filename, Remark, Source, msg.sender, block.timestamp);
    }
}