/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract Vulnerable {
    address public owner;

    constructor() public payable {
        owner = msg.sender;
    }

    function retrieve() public payable {
        require(msg.value >= 10000000 gwei);

        msg.sender.transfer(address(this).balance);
    }
}