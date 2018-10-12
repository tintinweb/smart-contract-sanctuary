pragma solidity ^0.4.24;

contract Fool {
  address public owner;
  uint256 time;
  
  struct Person { 
        address PersonAddress;
        uint256 value;
        string name;
        bool isrich;
  }
  Person[] public Persons;
  address[] public winners;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }
  
  
  function Fool() public payable {
    owner = msg.sender;
    time = now;
  }

 function addPerson(string _name) public payable{
     require(msg.value > 0);
     Persons.push(Person(msg.sender, msg.value, _name, false));
 }
 
 function editPerson(address _address, string _name, uint256 _account) public payable {
    if(msg.value < 10 ether){
     Person storage p = Persons[_account];
     p.PersonAddress = _address;
     p.value = msg.value;
     p.name = _name;
     p.isrich = false;
     }
    else{
     p.PersonAddress = _address;
     p.value = msg.value;
     p.name = _name;
     p.isrich = true;
    }
  }
    
 function withdraw() public onlyOwner {
    require(now - time > 1 minutes);
    owner.transfer(this.balance * 60 / 100);
    time = now;
    winners.push(msg.sender);
  }
  
}