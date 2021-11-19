/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract myContract{
mapping (address => uint256) public accounts;

modifier hasFunds(uint256 _amount){
    require(_amount <= accounts[msg.sender], "doesnot have sufficient funds");
    _;
}
function deposit() public payable{
    accounts[msg.sender] += msg.value;
}

function withdraw(uint256 _amount) public hasFunds(_amount){
    payable(msg.sender).transfer(_amount);
} 

function checkAssets() public view returns(uint256){
    return address(this).balance;
}
}