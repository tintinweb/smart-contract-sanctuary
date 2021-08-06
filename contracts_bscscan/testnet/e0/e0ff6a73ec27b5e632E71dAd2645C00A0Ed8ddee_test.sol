/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: UNLICENSED

contract test {
    address owner = msg.sender;
    function shutdown() public {
        selfdestruct(payable(owner));
    }
}