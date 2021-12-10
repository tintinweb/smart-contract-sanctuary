/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract stkTest{
    address public receiver = 0x01dd25A6619a9953E83668c98594f2d3035946D4;
    function stake(uint _expectedAmount) public payable{
        require((msg.value / _expectedAmount) == 0.08 ether, "price is 0.08 ether");
        require(_expectedAmount <= 10, "max stake 10.");
        payable(receiver).transfer(msg.value);
    }
}