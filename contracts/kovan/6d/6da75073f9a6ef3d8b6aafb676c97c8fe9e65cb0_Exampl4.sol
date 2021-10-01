/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    
contract Exampl4 {
    struct Store {
        string id;         
        uint time;         
    }
 
   Store public purchases;
    constructor() {
        
    Store memory sik;
    purchases = sik; 
    }

    function set(string memory _id, uint _time) public returns(bool) {
        purchases.id = _id;
        purchases.time = _time;
        return true;
    }

    function get() public view returns(Store memory) {
        return purchases;
    }
}