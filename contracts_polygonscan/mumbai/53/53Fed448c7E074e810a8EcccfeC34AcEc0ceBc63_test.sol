/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{

    uint256 public cash = address(this).balance;
    
    uint256 public prize;

    function payment() public payable{
        prize += msg.value * 3 / 10;
    }
    
    function withdraw() public {
        address payable guy = payable(msg.sender);
        guy.transfer(cash);
    }
}