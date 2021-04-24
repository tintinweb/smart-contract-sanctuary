/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.8.0;

contract TestPayable{
    
  
    address payable public owner;
  //  address payable withdrawAddr;
     
     modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    uint public all;//总量
    
    constructor() public{
        owner = payable(msg.sender);
    }
    
      fallback()  external payable {
         //payable(msg.sender).transfer(address(this).balance);
         all=all+msg.value;//总量累加
        
    }
    
    //constructor(address payable _withdrawAddr) payable public {
    //   withdrawAddr = _withdrawAddr;
  //  }
    
    function getBalance() public view returns(uint,uint,uint,uint){
        address _ac = msg.sender;
        return (_ac.balance,owner.balance,all,address(this).balance);
    }
     function withdraw() public payable onlyOwner returns(bool) {
      //owner.transfer(address(this).balance);
      payable(msg.sender).transfer(all);
       //payable(address(this)).transfer(msg.value);
        return true;

    }
     function withdraw2() public payable onlyOwner returns(bool) {
      payable(address(this)).transfer(all);
        return true;

    }
}