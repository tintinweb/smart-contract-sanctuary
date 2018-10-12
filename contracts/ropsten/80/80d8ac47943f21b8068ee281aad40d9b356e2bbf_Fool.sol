pragma solidity ^0.4.24;

contract Fool {
  address public owner;
  uint256 time;
  
  struct Person { 
        address PersonAddress;
        uint256 value;
        bytes32 name;
  }
  Person[] public Persons;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  function Fool() public payable {
    owner = msg.sender;
    time = now;
  }

 function addPerson(bytes32 _name, address _PersonAddress) public payable {
    require(msg.value > 10 ether);
    Person p;
    p.PersonAddress = _PersonAddress;
    p.value = msg.value;
    p.name = _name;
    Persons.push(p);
  }
    
 function withdraw() public onlyOwner {
    require(now - time > 1 minutes);
    owner.transfer(this.balance * 60 / 100);
    time = now;
  }
}