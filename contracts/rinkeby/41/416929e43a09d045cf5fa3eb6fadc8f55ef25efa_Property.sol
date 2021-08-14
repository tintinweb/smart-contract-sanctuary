/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

//SPDX-License-Identifier: GPL-3.0

//Pragma keyword, used to enable certain compiler features or checks
pragma solidity 0.8.0;

contract Property{
    int public value;
    int public price;
    address immutable public owner;
    
    uint8 public overflowX = 255;
    
    uint[3] public numbersArr = [1,2,3];
    
    uint public sentValue;
    
    constructor(int _price){
        price = _price;
        owner = msg.sender;
    }
    
    //AUTOMATICALLY CALLED WHEN SOMEONE SEND BALANCE TO THE CONTRACT
    receive() external payable{} 
    fallback() external payable{}
    
    function incrementOverflowX() public{
        overflowX += 1;
    }
    
    function setValue (int _value) public {
        value = _value;
    }
    
    function f1() public pure returns (int){
        int x = 5;
        x = x * 2;
        return x;
    }
    
    function setPrice(int _price) public {
        price = _price;
    }
    
    function getPrice() public view returns(int){
        return price;
    }
    
    function sendBalance() public payable{
      sentValue = msg.value;   
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    
    function transferBalance(address payable recipient, uint amount) public returns(bool){
        
        require(owner == msg.sender, "Transfer Failed. You are not the owner");
        
        if(amount <= getContractBalance()){
            recipient.transfer(amount);
            return true;
        }else{
            return false;
        }
    }
    
}