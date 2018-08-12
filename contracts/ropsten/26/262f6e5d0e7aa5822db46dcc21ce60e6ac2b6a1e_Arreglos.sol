pragma solidity ^0.4.8;

contract Arreglos {
address[] public userAddresses;

struct User {
  string name;
  uint level;
}

mapping (address => User) userStructs;

    
function createUser(string name, uint level) {
  
  // set User name using our userStructs mapping
  userStructs[msg.sender].name = name;
  // set User level using our userStructs mapping
  userStructs[msg.sender].level = level;
  // push user address into userAddresses array
  userAddresses.push(msg.sender);
}


function getAllUsers() external view returns (address[]) {
  return userAddresses;
}

}