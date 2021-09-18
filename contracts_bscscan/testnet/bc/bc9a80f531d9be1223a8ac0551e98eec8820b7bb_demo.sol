/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract demo
{
    uint number;
    function set(uint _number) public
    {
        number=_number;
    }
    function get() public view returns(uint)
    {
        return number;
    }
}