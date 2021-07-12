/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

contract AddressArray {
    address[] public addresses;
    
    function setNames(address[] memory addressValues) public {
        for(uint i = 0; i < addressValues.length; i++) {
             addresses.push(addressValues[i]);
        }
    }
}