/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Wallet{
    function pay(address payable to) public payable{
        to.transfer(msg.value);
    }
}