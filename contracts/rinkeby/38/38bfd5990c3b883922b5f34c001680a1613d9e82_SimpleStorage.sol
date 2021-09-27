/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
  // init to 0
  uint256 favNumber;
  //uint256 public favNumber;
  //bool public favBool;

  struct People {
      uint256 favNumber;
      string name;
  }
  
  People[] public people;
  //People public person = People({favNumber:2, name: "Patrick"});
  //people[0] = People({favNumber:2, name: "Patrick"});
  mapping(string => uint256) public nameToFavNumber;
  
  function store(uint256 _favNumber) public {
      favNumber = _favNumber;
  }
  
  function get() public view returns(uint256){
      return favNumber;
  }
  
  function addPerson(string memory _name, uint256 _favNumber) public {
    //people.push(People({favNumber:2, name: "Patrick"}));
    //people.push(People({name: _name, favNumber: _favNumber}));
    people.push(People(_favNumber, _name));
    nameToFavNumber[_name] = _favNumber;
  }
}