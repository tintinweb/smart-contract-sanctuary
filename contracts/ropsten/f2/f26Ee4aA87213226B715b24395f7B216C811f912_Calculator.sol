/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0;

contract Calculator
{
    uint32[][] public operations;
    
    function add(uint24 _x, uint16 _y) public payable returns(uint24)
    {
        operations.push([_x, _y, _x + _y]);
        return _x + _y;
    }
    
    function sub(uint16 _x, uint16 _y) public payable returns(uint16)
    {
        operations.push([_x, _y, _x - _y]);
        return _x - _y;
    }
    
    function mult(uint32 _x, uint16 _y) public payable returns(uint32)
    {
        operations.push([_x, _y, _x * _y]);
        return _x * _y;
    }
    
    function div(uint16 _x, uint16 _y) public payable returns(uint16)
    {
        operations.push([_x, _y, _x / _y]);
        return _x / _y;
    }
    
    function getOperation(uint num) public view returns(uint32[] memory)
    {
        return operations[num];
    }
}