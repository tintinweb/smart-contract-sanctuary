/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;


contract Storage {

    uint256 number;

    function setnum(uint256 num) public {
        number = num;
    }

    function getnum() public view returns (uint256){
        return number;
    }
}