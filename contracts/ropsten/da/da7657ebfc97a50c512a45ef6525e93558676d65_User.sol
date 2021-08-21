/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract User {
  string public user;
  address private _ownerAddress;


  constructor(string memory _user) public {
    user = _user;
  }

  function getUserName() public view returns (string memory) {
      return user;
  }

  function setUserName(string memory _user) public {
      user = _user;
  }
  
  function getBalance(address owner) public view returns(uint accountBalance) {  
            accountBalance = owner.balance;
  }

  /**
  * @dev Returns the address of the current owner.
  */
  function owner() public view virtual returns (address) {
      return _ownerAddress;
  }

}