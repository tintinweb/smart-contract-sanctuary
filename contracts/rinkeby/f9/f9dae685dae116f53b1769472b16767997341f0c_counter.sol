/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract counter
{
    uint public count;
    function get() public view returns (uint)
    {
        return count;
    }
    function inc() public {
        count+=1;
    }
}