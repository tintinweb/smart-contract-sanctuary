/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyValue {
    uint public yourValue;

    function set(uint  value) public {
        yourValue = value;
    }
    function get() public view returns (uint) {
        return yourValue;
    }
}