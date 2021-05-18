/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//SPDX-License-Identifier: QLIPIT.io
pragma solidity ^0.6.2;

contract PrivateTokenSale {
    
    struct SaleRegistration{
        uint value;
        address walletAddress;
    }
   
    address public owner;
    uint public balance;
    
    SaleRegistration[] public registrations;
    
    constructor() public payable {
        owner = msg.sender;
        balance = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function depositFunds() public payable {
        require(msg.value > 0.15e18, "Cannot buy for less than 100$");
        registrations.push(SaleRegistration(msg.value, msg.sender));
        balance = balance+ msg.value;
    }
    
    function withdrawFunds() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        payable(owner).transfer(contractBalance);
    }
    
    function getBalance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }
    
    function totalRegistration() public onlyOwner view returns(uint) {
        return registrations.length;
    }
    
    
}