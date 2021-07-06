/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract Faunet {
    function withdraw(uint amount) public {
        require(amount <= 100000000000000000);
        payable(msg.sender).transfer(amount);
    }
//    function () public payable{}
    fallback() external payable {}
}