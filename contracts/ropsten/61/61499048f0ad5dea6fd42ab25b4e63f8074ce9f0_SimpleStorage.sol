/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

contract SimpleStorage {
    uint public storedData;


    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint retVal) {
        return storedData;
    }
    
    function getset(uint _n) public returns(uint){
        storedData=_n;
        return storedData;
    }
}