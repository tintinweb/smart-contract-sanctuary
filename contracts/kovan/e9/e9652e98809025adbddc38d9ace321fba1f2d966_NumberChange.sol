/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract NumberChange {

    uint256 number;
    
    event NumberChanged(uint256 number);
    
    function setNumber(uint256 _number) public {
        number = _number;
        emit NumberChanged(number);
    }
    
    function getCurrentNumber() public view returns (uint256) {
        return number;
    }

}