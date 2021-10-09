/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DemoContract
{
    uint8 _counter;
    
    function incrementCounter() external
    {
        require(_counter < 255, "Counter already has max value and can't be incremented.");
        _counter++;
    }
    
    function decrementCounter() external
    {
        require(_counter > 0, "Counter already has min value and can't be decremented.");
        _counter--;
    }
    
    function getCounter() external view returns (uint8)
    {
        return _counter;
    }
}