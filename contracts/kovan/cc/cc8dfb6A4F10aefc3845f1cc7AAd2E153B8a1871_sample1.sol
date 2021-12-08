/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract sample1 {
  uint liquifyAmt;
  address owner;

  constructor() {
    liquifyAmt = 1;
    owner = msg.sender;
  }

  struct User{
      string name;
      address _address;
      uint256 created_at;
      uint256 last_awarded;
      uint deposited;
      uint deposited_today;
      uint award;
  }

  mapping (address => User) users;
  address[] public addressUsers;

  function getCount() public view returns(uint count) {
      return addressUsers.length;
  }

  modifier onlyUser {
      require(msg.sender == owner);
      _;
  }

  function registerUser(string memory name) public{
    address _address = msg.sender;
    User storage user = users[_address];

    user.name = name;
    user._address = _address;
    user.created_at = block.timestamp;
    user.deposited = 0;
    user.deposited_today = 0;
    user.award = 0;
    user.last_awarded = block.timestamp;

    addressUsers.push(_address);
  }

  function giveAward(address _address) private{
      User storage user = users[_address];
      require(block.timestamp > user.last_awarded + 1 days, "Try tomorrow");

      user.award += user.deposited_today * 171/10000 * 1/12;
      user.award /= 100;

      user.last_awarded = block.timestamp;
  }

  function deposit() public payable{
      User storage user = users[msg.sender];

      uint256 timestamp = block.timestamp;
      if(timestamp > user.last_awarded + 1 days){
         giveAward(msg.sender);
         user.deposited_today = 0;
      }

      user.deposited_today += msg.value;
      user.deposited += msg.value;
  }

  function liquify() public onlyUser{
     require(address(this).balance > liquifyAmt, "Liquify Amount not reached");

     uint count = getCount();
     uint dist = address(this).balance * 67/100;
     dist /= count;
     for(uint i = 0; i < getCount(); i++) {
        payable(addressUsers[i]).transfer(dist);
     }
  }

  function withdraw() public {
    User storage user = users[msg.sender];
    giveAward(msg.sender);
    payable(msg.sender).transfer(user.award);
  }
}