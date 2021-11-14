// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ReadWrite {
  struct User {
    uint id;
    string name;
  }
  User[] public users;
  uint public nextId;

  function create(string memory name) public {
    users.push(User(nextId, name));
    nextId++;
  }

  function read(uint id) view public returns(uint, string memory) {
    for(uint i = 0; i < users.length; i++) {
      if(users[i].id == id) {
        return(users[i].id, users[i].name);
      }
    }
  }
}