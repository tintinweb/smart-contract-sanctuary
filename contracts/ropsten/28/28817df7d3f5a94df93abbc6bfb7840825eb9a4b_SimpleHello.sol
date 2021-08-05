/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: No-license
pragma solidity 0.8.6;

contract SimpleHello {
    event Success(string s, uint u);
    uint public storedData;
   
    constructor(uint sd){
        storedData = sd;
    }
   
    function set(uint sd) public {
        storedData = sd;
        emit Success("OK!", sd);
    }
    function get() public view returns (uint) {
        return storedData;
    }
}