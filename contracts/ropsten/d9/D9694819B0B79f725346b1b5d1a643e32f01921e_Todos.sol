/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Todos {
    event Log(address initCaller);

    function callLog() public {
        emit Log(tx.origin);
    }
}