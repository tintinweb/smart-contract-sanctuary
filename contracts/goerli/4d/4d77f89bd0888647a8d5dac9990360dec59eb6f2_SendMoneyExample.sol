/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.5.13;

contract SendMoneyExample {
    
    uint public balanceReceived;
    
    function receiveMoney() public payable{
        balanceReceived += msg.value;
    }
    
    function getBalance() public view returns(uint){
      return address(this).balance;   
    }
    
    function withdrawMoney() public {
        address payable to = msg.sender;
        
        to.transfer(this.getBalance());
    }
}