// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import "./ISample.sol";

contract Sample is ISample{
    /*=============== State Variables ========================*/
    uint256 public value;
 
    /*=============== Constructor ========================*/

    constructor(uint256 _value) {
        value = _value;
    }

    function getValue() public view returns(uint256){
        return value;
    }

    function setValue(uint256 _setValue) external override{
        value = _setValue;
    }
}