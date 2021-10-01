/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    
contract Exampl5 {
    struct Store {
        string id;         
        address time;         
    }
 
 
 string a = "ok";
 string b = "ok2";
 string c = "iwr";
 string d = "4343tte";
 
   Store public purchases;
    
    constructor() {
        
    Store memory sik;
    purchases = sik; 
    }

    function out() public view returns (string memory, string memory, string memory, string memory) {
        return (a, b, c, d);
    }
    function set(string calldata _id, address  _time) public returns(bool) {
        purchases.id = _id;
        purchases.time = _time;
        return true;
    }

    function get() public view returns(Store memory) {
        return purchases;
    }
    
}