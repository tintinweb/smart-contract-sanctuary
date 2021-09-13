/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract TestMultisigTransfer
{
    function runTest() external
    {
        emit TestEvent(address(this));
    }
    
    event TestEvent(address indexed _current);
}