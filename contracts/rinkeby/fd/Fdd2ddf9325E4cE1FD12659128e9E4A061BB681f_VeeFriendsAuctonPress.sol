// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract VeeFriendsAuctonPress {

  address[] public authors;
  address public owner;

  constructor() public{
    owner = msg.sender;
    authors.push(owner);
  }


  function addAuthor(address author) public restricted returns (uint)  {
    authors.push(author);
    return authors.length - 1;
  }

  function isAuthor(address author) public view returns (bool)  {
    
    if (author == owner) {
      return true;
    }
    
    if (_indexOf(author) > 0) {
      return true;
    }

    return false;
  }

  function _indexOf(address itemInArray) private view returns (uint) {
    
      for (uint i = 0; i < authors.length; i++) {
        if(itemInArray == authors[i]) {
          return i;
        }
      }

      return 0;
  }

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }
}

