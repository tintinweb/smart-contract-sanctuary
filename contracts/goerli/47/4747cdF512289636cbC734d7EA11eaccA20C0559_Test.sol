/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    
    //mapping transferred IDs
    mapping(address => mapping(uint => bool)) transferredIDs;
    
    //flag ID as transferred
    function addID(uint _id) public {
        transferredIDs[msg.sender][_id] = true;
    }
    
    //check if ID has already been transferred
    function isTransferred(uint _id) public view returns(bool) {
        if(transferredIDs[msg.sender][_id] == true) {
            return true;
        } else {
            return false;
        }
    }
}