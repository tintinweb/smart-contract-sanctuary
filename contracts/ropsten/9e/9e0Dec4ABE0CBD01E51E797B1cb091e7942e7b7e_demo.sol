/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: LICENSED

pragma solidity ^0.8.6;

contract demo
{
    uint number;
    function set(uint _number) public
    {
        number = _number+1;
    }
    function get() public view returns(uint)
    {
        return number;
    }
}