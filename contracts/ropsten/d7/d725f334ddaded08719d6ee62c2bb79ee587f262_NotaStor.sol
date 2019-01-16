pragma solidity ^0.4.18;

contract NotaStor {

  address public owner;
  uint public cost;

  function NotaStor() public {
    owner = msg.sender;
    cost = 1 finney;
  }

  event Entry(
    address indexed signer,
    bytes32 indexed documentHash
  );

  modifier costs {
    require(msg.value >= cost);
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  /**
    create a new Entry in the logs.
   */
  function create(bytes32 documentHash) public payable costs {
    Entry(msg.sender, documentHash);
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(this.balance);
  }

  function setOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function setCost(uint newCost) public onlyOwner {
    cost = newCost;
  }

}