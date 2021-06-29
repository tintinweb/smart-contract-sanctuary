/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract destroy {
    function j(address payable a) public {
        selfdestruct(a);
    }
}