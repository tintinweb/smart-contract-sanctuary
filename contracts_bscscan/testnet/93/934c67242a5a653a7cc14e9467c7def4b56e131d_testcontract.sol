/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract testcontract {

uint256 public number;

function bytesTouint(bytes32 b) public returns(uint256){
    
    for(uint i= 0; i<b.length; i++) {
        number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
    }

    return number;
    }
}