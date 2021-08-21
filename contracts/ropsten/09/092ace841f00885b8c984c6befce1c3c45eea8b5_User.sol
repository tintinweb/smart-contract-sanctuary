/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

pragma solidity 0.8.7;

contract User {
  string public user;


  constructor(string memory _user) public {
    user = _user;
  }

  function getUserName() public view returns (string memory) {
      return user;
  }

  function setUserName(string memory _user) public {
      user = _user;
  }  
}