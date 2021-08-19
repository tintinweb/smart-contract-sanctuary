// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register { 
    address public admin;

struct Person  {

string name;
string surname;
uint age;

}

constructor()  {
admin = msg.sender;
}

Person[] public people;
mapping(address => uint) public personIndex;
function getPeople() external view returns (Person[] memory) {
return people;

}


function newPerson(string calldata name, string calldata surname, uint age) payable external {
require(msg.value >= 1 ether /10, "payment required");
// someone = Person(name, surname, age);
people.push(Person(name, surname, age));
personIndex[msg.sender] = people.length -1;

}



function updateAge (uint newAge) external {

    uint myIndex = personIndex[msg.sender];
    people[myIndex].age = newAge;
}

function updateAge(address personAddress, uint newAge) external onlyAdmin {

    uint myIndex = personIndex[personAddress];
    people[myIndex].age = newAge;
}



function deletePerson () external onlyAdmin {

    deletePerson (msg.sender);
}

function deletePersonAdmin(address personAddress) external onlyAdmin {

    deletePerson (personAddress);
}

function deletePerson(address personAddress) internal {

    uint myIndex = personIndex[personAddress];
    delete people[myIndex];
}

mapping(address => uint) public balance;
receive() payable external {
    balance [msg.sender] = msg.value;
}

modifier onlyAdmin() {

    require(msg.sender == admin, "NOT AUTHORIZED");
    _;
}

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}