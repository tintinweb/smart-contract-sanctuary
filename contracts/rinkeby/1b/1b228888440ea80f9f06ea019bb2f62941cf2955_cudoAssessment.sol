/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract cudoAssessment {

    uint256 public number;

    function callMe(uint256 _number1, uint256 _number2 ) external returns (uint256){
        number = _number1 + _number2;
        return number;
    }
}