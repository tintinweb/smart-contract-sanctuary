/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract SendMoney{
    address private owner;uint public balanceReceived;
    string public currentName;Cart[] private Payments;string private XXX;
    
    struct Cart{
        string _id;
        string _hoten;
        uint _amount;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    function setXXX(string memory xxx) public{
        XXX = xxx;
    }
    function getXXX() public view returns(string memory){
        return XXX;
    }
    
    function cartPay(string memory id, string memory hoten) public payable{
        balanceReceived += msg.value;
        Cart memory thanhtoan = Cart(id, hoten, msg.value);
        Payments.push(thanhtoan);
    }
    
    function getCart() public view returns( Cart[] memory){
        return Payments;
    }
    
    function receiveMoney(string memory tensp) public payable{ 
        balanceReceived += msg.value;
        currentName = tensp;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function get1() public view returns(address){
        return address(this); // Address của Smart Contract
    }
    
    function get2() public view returns(address){
        return msg.sender;   // Address của Account (khách) đang chạy
    }
    
    function getOwner() public view returns(uint){
        return owner.balance; 
    }
    
}