/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract demo {
    uint value;

    function setter(uint _value) public {
        value = _value;
    }
    function getter() public view returns(uint) {
        return value;
    }
}