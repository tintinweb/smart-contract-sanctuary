/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract TsurugiTimeLock {
  address public owner;
  IERC20 public token;
    
  mapping(address => uint256) public locked; // account => tier => balance
  mapping(address => uint256) public claimed; // account => tier => claimed
  mapping(uint256 => Tier) public tiers; // tier => Tier
  uint256 public tierCount = 0;

  struct Tier {
      uint256 percent;
      uint256 releaseDate;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "insufficient privilege");
    _;
  }

  constructor() {
    owner = msg.sender;
    setToken(0x604170057349cF31619B990a17a678e167cF9388);
    setTier(0, 5, 1634864400); // 2021-10-22 01:00:00 GMT, 5%
    setTier(1, 5, 1634868000); // 2021-10-22 02:00:00 GMT, 5%
    setTier(2, 20, 1634871600); // 2021-10-22 03:00:00 GMT, 5%
    setTier(3, 30, 1634610955); // 2021-10-22 04:00:00 GMT, 5%
    setTier(4, 20, 1634611255); // 2021-10-22 05:00:00 GMT, 5%
    setTier(5, 20, 1634611255); // 2021-10-22 06:00:00 GMT, 5%

  }

  function setToken(address _token) public onlyOwner returns (bool) {
      token = IERC20(_token);
      return true;
  }

  function setTier(uint256 _tier, uint256 _percent, uint256 _releaseDate) public onlyOwner returns (bool) {
    tiers[_tier] = Tier(_percent, _releaseDate);
    tierCount++;
    return true;
  }
  
  function deposit(address _account, uint256 _amount) external returns (bool) {
    token.transferFrom(msg.sender, address(this), _amount);
    locked[_account] += _amount;
    return true;
  }

  function claim(uint256 _amount) public returns (bool) {
      require(getClaimableAmount(msg.sender) >= _amount, 'TsurugiTimeLock: insufficient claimable balance');
      claimed[msg.sender] += _amount;
      token.transfer(msg.sender, _amount);
      return true;
  }

  receive() external payable  {
      claim(getClaimableAmount(msg.sender));
  }

  function getClaimablePercent(uint256 _timestamp) public view returns (uint256) { // ToDo: make it private
    uint256 claimablePercent = 0;
    for(uint256 i = 0; i < tierCount; i++) {
        if(_timestamp >= tiers[i].releaseDate) claimablePercent += tiers[i].percent;
    }
    return claimablePercent;
  }

  function getClaimableAmount(address _account) public view returns (uint256) {
    uint256 claimableAmount = locked[_account] * getClaimablePercent(block.timestamp) / 100 - claimed[_account];
    return claimableAmount;
  }
 
  function getTimestamp() external view returns (uint256) {
    return block.timestamp; 
  }
}