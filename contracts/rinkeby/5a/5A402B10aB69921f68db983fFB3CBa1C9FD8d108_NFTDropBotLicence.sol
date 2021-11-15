// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NFTDropBotLicence {
  // User Address => Referral Address
  mapping(address => address) private _users;

  // Referral Address => Commision
  mapping(address => uint256) private _referrals;

  uint256 private _totalComission = 0;

  address private _owner;

  constructor() {
    _owner = msg.sender;
    _users[msg.sender] = msg.sender;
  }

  function addUser(address userAddress)
    public
    payable
    onlyUnregisteredUser(userAddress)
  {
    require(msg.value >= 0.01 ether, 'Not enough Ether');
    _users[userAddress] = msg.sender;

    // Give 10% commission to referral (msg.sender)
    uint256 commission = (msg.value * 10) / 100;
    _referrals[msg.sender] = _referrals[msg.sender] + commission;
    _totalComission += commission;
  }

  function getComission() public view returns (uint256) {
    return _referrals[msg.sender];
  }

  function isValid() public view onlyRegisteredUser(msg.sender) returns (bool) {
    return true;
  }

  function withdrawAllWithoutCommission() public onlyOwner {
    uint256 balance = address(this).balance - _totalComission;

    require(payable(_owner).send(balance), 'Failed to send Ether');
  }

  function withdrawCommission() public {
    uint256 commission = _referrals[msg.sender];

    require(
      commission >= 0.01 ether,
      'Needs minimum 0.01 ETH in comission to withdraw'
    );

    require(payable(msg.sender).send(commission), 'Failed to send Ether');

    // Clear commission amounts
    _referrals[msg.sender] = _referrals[msg.sender] - commission;
    _totalComission -= commission;
  }

  modifier onlyRegisteredUser(address userAddress) {
    require(_users[userAddress] != address(0x0), 'Not a valid user address');
    _;
  }

  modifier onlyUnregisteredUser(address userAddress) {
    require(
      _users[userAddress] == address(0x0),
      'User address already registered'
    );
    _;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, 'Caller is not the owner');
    _;
  }
}

