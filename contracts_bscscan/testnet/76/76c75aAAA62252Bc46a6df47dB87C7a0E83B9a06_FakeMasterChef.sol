// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakeMasterChef {

  function poolInfo(uint256 pool_id) public returns(address, uint256, uint256, uint256) {

    return (address(this), 10, 10, 10);
  }

  function pendingCake(uint256 _pid, address _user) public returns(uint256) {

    return 10;
  }

  function userInfo(uint256, address) public returns(uint256, uint256) {

    return (10, 10);
  }

  function withdraw(uint256 _pid, uint256 _amount) public returns(bool) {

    return true;
  }

  function deposit(uint256 _pid, uint256 _amount) public returns(bool) {

    return true;
  }
  
}