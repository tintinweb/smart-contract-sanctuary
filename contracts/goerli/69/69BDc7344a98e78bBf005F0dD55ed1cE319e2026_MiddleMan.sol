//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract MiddleMan {
  address payable public owner;
  mapping(address => uint256) deposits;
  mapping(address => User) investors;

  struct User {
    address addr;
    bool exists;
  }

  event UserCreated(address _addr, uint _amount);
  event UserDeposit(address _addr, uint _amount);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, 'Just only owner can add new user');
    _;
  }

  modifier userNotExists(address _addr) {
    require(!investors[_addr].exists, "User already exists");
    _;
  }

  modifier userExists(address _addr) {
    require(investors[_addr].exists, "User doesn't already exists");
    _;
  }

  function addUser(address _addr) public onlyOwner userNotExists(msg.sender) {
    investors[_addr] = User(_addr, true);
    deposits[_addr] = 0;

    emit UserCreated(_addr, 0);
  }

  function deposit() public payable userExists(msg.sender) {
    require(msg.value > 0 ether, 'Not enough ether provided');
    deposits[msg.sender] += msg.value;
    emit UserDeposit(msg.sender, msg.value);
  }

}