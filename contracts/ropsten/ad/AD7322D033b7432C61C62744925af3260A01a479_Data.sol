/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Data{

    address public creator;

    mapping(address => uint256) public balanceOf;

    constructor(){
        creator = msg.sender;
    }

    function testCall(uint256 amount)
        public
    {
        balanceOf[msg.sender] = amount;
    }

}