/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.5.17;

contract sendMoneySolidity{
    
    uint public ReceivedBalance;
    
    function receiveMoney() public payable{
        ReceivedBalance = msg.value;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function withdrawMoney() public {
      address payable to = msg.sender;
      
      to.transfer(this.getBalance());
    }
    
    function withdrawMoneyTo(address payable _to) public {
      _to.transfer(this.getBalance());
    }
}