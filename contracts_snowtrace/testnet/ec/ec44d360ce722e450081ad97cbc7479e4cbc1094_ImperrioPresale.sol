/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ImperrioPresale{
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender==owner,"Only owner is authorized this operation");
        _;
    }

    function addCoins() public payable{}

    function claim() public{
        uint256 amount = 0.1 * 10**18;
        require(address(this).balance>=amount,"Insufficient Contract Balance");
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}