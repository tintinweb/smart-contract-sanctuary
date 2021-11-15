// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract EmitStorageNoAddr {
  struct UserInfo {
    uint256 chainId;
    uint256 amount;
  }

  mapping(address => UserInfo) public user;

  event Deposit(uint256 indexed chainID, uint256 amount);

  function deposit(uint256 _chainId, uint256 _amount) external {
    user[msg.sender] = UserInfo(_chainId, _amount);
     emit Deposit(_chainId, _amount);
  }
}

