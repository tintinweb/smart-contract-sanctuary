/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    
contract Example3 {
    struct Store {
        string id;         
        uint time;         
    }
 
    mapping (uint => Store) public purchases;
    Store public sik;

    function set(string memory _id, uint _time) public returns(bool) {
        purchases[1].id = _id;
        purchases[1].time = _time;
        return true;
    }

    function get() public view returns(Store memory) {
        return purchases[1];
    }
}