/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: No-license
pragma solidity 0.8.6;

contract SimpleHello {
    uint public storedData;
   
    function set(uint sd) public {
        storedData = sd;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}