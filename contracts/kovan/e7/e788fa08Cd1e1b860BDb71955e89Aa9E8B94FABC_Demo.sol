/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Demo {
    uint number;
 
    function set(uint _number) public {
        number = _number;
    }

    function get() public view returns(uint) {
        return number;
    }
}