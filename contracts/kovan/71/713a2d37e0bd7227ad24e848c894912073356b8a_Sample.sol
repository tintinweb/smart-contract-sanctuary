/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Sample{
    /*=============== State Variables ========================*/
    uint256 public value;
 
    /*=============== Constructor ========================*/

    constructor() {
        value = 5*10**18;
    }

    function getValue() public view returns(uint256){
        return value;
    }

    function setValue(uint256 _setValue) public {
        value = _setValue;
    }
}