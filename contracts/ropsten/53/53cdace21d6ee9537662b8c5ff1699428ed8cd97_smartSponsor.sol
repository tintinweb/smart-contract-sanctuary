pragma solidity ^0.4.18;
contract smartSponsor {
  address public owner;
  address public benefactor;
  bool public refunded;
  
  uint public numPledges;
  
  struct Pledge {
    uint amount;
    address eth_address;
    bytes32 message;
  }
  mapping(uint => Pledge) public pledges;

  // constructor
  function smartSponsor(address _benefactor) {
    owner = msg.sender;
    numPledges = 0;
    refunded = false;
    
    benefactor = _benefactor;
  }

  // add a new pledge
  function pledge(bytes32 _message) payable {
    if (msg.value == 0  || refunded) throw;
    pledges[numPledges] = Pledge(msg.value, msg.sender, _message);
    numPledges++;
  }

  function getPot() constant returns (uint) {
    return this.balance;
  }

  // refund the backers
  function refund() {
    if (msg.sender != owner  || refunded) throw;
    for (uint i = 0; i < numPledges; ++i) {
      pledges[i].eth_address.send(pledges[i].amount);
    }
    refunded = true;
   
  }

  // send funds to the contract benefactor
  function drawdown() {
    if (msg.sender != owner  || refunded) throw;
    benefactor.send(this.balance);
    
  }
}