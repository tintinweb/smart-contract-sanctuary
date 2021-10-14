/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{

    uint256 public cash = address(this).balance;
    
    function withdraw() public {
        address payable guy = payable(msg.sender);
        guy.transfer(cash);
    }
}