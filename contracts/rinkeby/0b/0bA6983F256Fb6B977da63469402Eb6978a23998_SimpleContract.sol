/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// File: SimpleContract.sol

contract SimpleContract {
    uint value;

    function setValue(uint _value) external {
        value = _value;
    }

    function getValue() external view returns(uint) {
        return value;
    }
}