pragma solidity ^0.4.25;

contract ClientReceipt {

    function transfer(address recevier,uint amount)public payable {
        recevier.transfer(amount);
        
    }
   function balanceOf(address _owner) constant public returns (uint256 balance) {
      return _owner.balance;
  }
    
}