contract Telephone {

  address public owner;
  uint8 test=8;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
  
  function getTest() view public returns(uint8){
      return test;
  }
  
  function destruct() public{
      selfdestruct(msg.sender);
  }
  
  
}