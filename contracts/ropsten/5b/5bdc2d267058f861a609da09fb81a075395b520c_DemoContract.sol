/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DemoContract
{
    uint256 number;
    
    function getNumber() external view returns (uint256)
    {
        return number;
    }
    
    function setNumber(uint256 num) external
    {
        number = num;
    }
    
    function increment() external
    {
        number++;
    }
    
    function decrement() external
    {
        if (number > 0)
        {
            number--;
        }
    }
}