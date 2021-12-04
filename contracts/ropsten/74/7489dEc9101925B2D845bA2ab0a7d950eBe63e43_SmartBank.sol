// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SmartBank
{
    uint public a;
    function updateValue() public
    {
        a+=10;
    }
    function getValue() public view returns(uint)
    {
        return a;
    }
    function sendEther(address payable who) public payable
    {
        who.transfer(msg.value);
    }
}