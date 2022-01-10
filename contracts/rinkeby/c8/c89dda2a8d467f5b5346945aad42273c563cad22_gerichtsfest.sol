/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;
contract gerichtsfest {

    event NewHashValue(string, string, address, uint);

    function logHashValue(string memory hashValue, string memory Value) public {    
      emit NewHashValue(hashValue, Value, msg.sender, block.timestamp);
    }
}