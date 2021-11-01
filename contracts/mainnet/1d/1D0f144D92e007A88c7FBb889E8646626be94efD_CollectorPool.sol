// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IOre.sol";


contract CollectorPool is Ownable, ReentrancyGuard {
  // Ore token contract interface
  IOre public ore;

  // Determines if collectors can deposit ore to be burnt
  bool private _openForBurning;
  // Keeps track fo the currently active launch counter
  uint256 private _currentLaunch;

  // Keeps track of whitelisted fund sources
  mapping (address => bool) public fundAddresses;
  // Keeps track of when an address last claimed their shares from the pool
  mapping (address => uint256) private _lastClaimedByAddress;
  // Keeps track of the total burnt ore by an address for each launch
  mapping (address => mapping (uint256 => uint256)) private _burntOreByAddress;
  // Keeps track of the total burnt ore in each launch
  mapping (uint256 => uint256) private _totalBurntOreByLaunch;
  // Keeps track of the total funds received in each launch
  mapping (uint256 => uint256) private _totalFundsByLaunch;

  constructor(address _ore) {
    ore = IOre(_ore);
  }

  function currentLaunch() external view returns (uint256) {
    return _currentLaunch;
  }

  function openForBurning() external view returns (bool) {
    return _openForBurning;
  }

  function setBurningState(bool _state) external onlyOwner {
    require(_openForBurning != _state, "Invalid State");
    _openForBurning = _state;
  }

  function setCurrentLaunch(uint256 _launch) external onlyOwner {
    require(_currentLaunch < _launch, "Invalud Launch Number");
    _currentLaunch = _launch;
  }

  function setFundAddress(address _address, bool _state) external onlyOwner {
    require(_address != address(0), "Invalid Address");

    if (fundAddresses[_address] != _state) {
      fundAddresses[_address] = _state;
    }
  }

  function lastClaimedByAddress(address _address) external view returns (uint256) {
    return _lastClaimedByAddress[_address];
  }

  function burntOreByAddress(address _address, uint256 _launch) external view returns (uint256) {
    return _burntOreByAddress[_address][_launch];
  }

  function totalBurntOreByLaunch(uint256 _launch) external view returns (uint256) {
    return _totalBurntOreByLaunch[_launch];
  }

  // Deposits ore to be burned
  function burnOre(uint256 _amount) external nonReentrant {
    require(_openForBurning, "Not Open For Burning");
    require(_amount > 0, "Invalid Ore Amount");
    require(ore.balanceOf(msg.sender) >= _amount, "Insufficient Ore");

    ore.burn(msg.sender, _amount);

    _burntOreByAddress[msg.sender][_currentLaunch] += _amount;
    _totalBurntOreByLaunch[_currentLaunch] += _amount;
  }

  // Calculates and returns the total amount of claimable funds for the specified account
  function totalClaimableByAccount(address _account) public view returns (uint256, uint256) {
    uint256 totalClaimable = 0;
    uint256 lastClaimed = _lastClaimedByAddress[_account];
    uint256 lastAvailableClaim = 0;
    for (uint256 i = lastClaimed + 1; i <= _currentLaunch ; i++) {
      if (_totalBurntOreByLaunch[i] == 0 || _totalFundsByLaunch[i] == 0) {
        continue;
      }

      lastAvailableClaim = i;

      uint256 claimable = (_burntOreByAddress[_account][i] * _totalFundsByLaunch[i]) / _totalBurntOreByLaunch[i];

      if (claimable > 0) {
        totalClaimable += claimable;
      }
    }

    return (totalClaimable, lastAvailableClaim);
  }

  // Can be called by collectors for claiming funds from the ore burning mechanism
  function claim() external nonReentrant {
    uint256 totalClaimable;
    uint256 lastAvailableClaim;
    (totalClaimable, lastAvailableClaim) = totalClaimableByAccount(msg.sender);

    require(totalClaimable > 0, "Insufficient Claimable Funds");
    _lastClaimedByAddress[msg.sender] = lastAvailableClaim;

    payable(msg.sender).transfer(totalClaimable);
  }

  // Handles funds received for the pool
  receive() external payable {
    // Make sure enough funds are sent, and the source is whitelisted
    require(msg.value > 0, "Insufficient Funds");
    require(fundAddresses[msg.sender], "Invalid Fund Address");

    // Update the total received funds for the currently open launch
    _totalFundsByLaunch[_currentLaunch] += msg.value;
  }
}