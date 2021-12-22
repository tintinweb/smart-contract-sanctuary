/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract test {

    uint storeData;

    function set(uint x) public {
        storeData = x;
    }

    function get() public view returns (uint){
        return storeData;
    }

    function getTest(uint a, uint b) public pure returns(uint) {
        return a + b;
    }
}