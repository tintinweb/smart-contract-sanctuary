/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.8.0;

/** 
 * @title TestCon
 * @dev Implements voting process along with vote delegation
 */
contract TestCon{
    uint256 number;
    
    function store(uint256 num) public{
        number = num;
    }
    
    function retrieve() public view returns (uint256){
        return number;
    }
}