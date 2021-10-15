//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../SafeERC20.sol";
import "../SafeMath.sol";
import "../Ownable.sol";
import "../Pausable.sol";

contract Reset is Ownable, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint public weekStart; // Timestamp for when the start of a week should be
  uint public baseCost; // How much in AURUM it costs to reset at the start of the week
  uint public costMultiplier; // How much we increase the AURUM cost by times 100, so be sure to divide it by that later!

  address aurumAddress;
  address public treasury;
  
  mapping(uint => uint) tokenRecentResetWeek; // This tracks what week the token most recently did a reset on, so we can clear their reset count
  mapping(uint => uint) tokenWeeklyResetCount; // Lets us track how many resets they've done so we can adjust their price accordingly
  mapping(uint => uint) tokenResetCount; // Total reset count, might be better for data validation
  mapping(uint => uint) public weeklySpendTracker;

  constructor(address _aurum, uint _baseCost, uint _multiplier, address _treasury) {
    aurumAddress = _aurum;
    weekStart = block.timestamp;
    baseCost = _baseCost;
    costMultiplier = _multiplier;
    treasury = _treasury;
  }

  function aurum() internal view returns(IERC20) {
    return IERC20(aurumAddress);
  }

  function reset(uint _token) public whenNotPaused {
    uint week = calcWeek();

    if (tokenRecentResetWeek[_token] < week) {
      tokenWeeklyResetCount[_token] = 0;
      tokenRecentResetWeek[_token] = week;
    }

    uint resetCost = calcReset(_token);
    tokenWeeklyResetCount[_token] = tokenWeeklyResetCount[_token].add(1);
    tokenResetCount[_token] = tokenResetCount[_token].add(1);
    weeklySpendTracker[week] = weeklySpendTracker[week].add(resetCost);

    aurum().safeTransferFrom(msg.sender, treasury, resetCost);
  }


  // ----------- INTERNAL FUNCTIONS -----------


  function calcReset(uint _token) internal view returns(uint) {
    uint week = calcWeek();

    uint count = tokenWeeklyResetCount[_token];

    uint cost;

    if (count == 0 || tokenRecentResetWeek[_token] < week) {
      cost = baseCost;
    } else if (count > 0) {
      cost = baseCost.mul((costMultiplier ** count).div(100 ** count));
    }

    return cost;
  }

  function calcWeek() public view returns(uint) {
    uint timePassed = (block.timestamp).sub(weekStart);
    return timePassed.div(604800);
  }

  // ----------- VIEW FUNCTIONS ----------- 

  function checkResets(uint _token) external view returns(uint) {
    return tokenResetCount[_token];
  }

  function nextReset(uint _token) external view returns(uint) {
    return calcReset(_token);
  }

  // ----------- ADMIN FUNCTIONS -----------

  function updateTreasury(address _address) external onlyOwner {
    treasury = _address;
  }

  function updateMultiplier(uint _multiplier) external onlyOwner {
    costMultiplier = _multiplier;
  }

  function updateBase(uint _base) external onlyOwner {
    baseCost = _base;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}