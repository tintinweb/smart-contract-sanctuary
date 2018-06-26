pragma solidity ^0.4.23;

contract SimpleFund {
  address public owner;
  uint public goalAmount;
  
  event FundsAdded(address indexed _from, uint _amount);
  event Funded();
  
  constructor(uint goal) public {
    owner = msg.sender;
    goalAmount = goal;
  }
  
  function transfer() public payable {
    emit FundsAdded(msg.sender, msg.value);
    
    if (address(this).balance >= goalAmount) {
      emit Funded();
      selfdestruct(owner);
    }
  }
}