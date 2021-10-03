/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CRUD {
  struct User {
    uint id;
    string name;
  }

  User[] public users;
  address public admin;
  uint public nextId = 1;

  constructor() {
    admin = msg.sender;
    create("Solidity");
  }

  function create(string memory name) public {
    users.push(User(nextId, name));
    nextId++;
  }

  function read(uint id) view public returns(uint, string memory) {
    uint i = find(id);
    return(users[i].id, users[i].name);
  }

  function update(uint id, string memory name) public {
    uint i = find(id);
    users[i].name = name;
  }

  function destroy(uint id) public {
    uint i = find(id);
    delete users[i];
  }
  function find(uint id) view internal returns(uint)
  {
    for(uint i = 0; i < users.length; i++) {
      if(users[i].id == id) {
        return i;
      }
    }
    revert('User does not exist!');
  }
}