//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";

contract Clicker is Ownable {
    // initate the Click token and create 1,000,000,000,000 of it 
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;

  address public clickAddress;
  address public slpAddress;
  address public gameMaster;

  uint decimals = 1000000000000000000;
  uint centDecimals = 10000000000000000;

  uint costIncreaseRate = 11; // the % the cost should go up each time, this represents a 10% increase

  Counters.Counter winnerCounter;

  mapping(address => uint) public lastRewardCheckTime;
  mapping(address => uint) public rewardRate;
  mapping(address => uint) public rewardsPaid;
  mapping(Hire => uint) public baseHirePrice;
  mapping(Hire => uint) public hireEarningsRate;
  mapping(address => mapping(Hire => uint)) public hiredCount;
  mapping(address => bool) public boostedStatus;
  mapping(address => bool) public hasWon;

  mapping(address => uint) public winnerIndex;
  mapping(uint => address) public winners;

  uint public winAmount = 100000000000000000000000000000; // 100 billion
  uint public boostPrice = 100000000000000000000;
  uint public boostPriceIncrease = 10000000000000000000;

  enum Hire {
    Intern, Graduate, MBA, PhD, Agency, Factory, Competitor, Country
  }

  constructor(address _click, address _gameMaster) {
    clickAddress = _click;
    gameMaster = _gameMaster;

    baseHirePrice[Hire.Intern] = 10 * decimals;
    hireEarningsRate[Hire.Intern] = 1 * centDecimals;

    baseHirePrice[Hire.Graduate] = 150 * decimals;
    hireEarningsRate[Hire.Graduate] = 8 * centDecimals;
    
    baseHirePrice[Hire.MBA] = 2250 * decimals;
    hireEarningsRate[Hire.MBA] = 72 * centDecimals;
    
    baseHirePrice[Hire.PhD] = 33750 * decimals;
    hireEarningsRate[Hire.PhD] = 648 * centDecimals;
    
    baseHirePrice[Hire.Agency] = 506250 * decimals;
    hireEarningsRate[Hire.Agency] = 5832 * centDecimals;
    
    baseHirePrice[Hire.Factory] = 7593750 * decimals;
    hireEarningsRate[Hire.Factory] = 52488 * centDecimals;
    
    baseHirePrice[Hire.Competitor] = 113906250 * decimals;
    hireEarningsRate[Hire.Competitor] = 472392 * centDecimals;
    
    baseHirePrice[Hire.Country] = 1708593750 * decimals;
    hireEarningsRate[Hire.Country] = 4251528 * centDecimals;
  } 

  // Utility functions

  function clickToken() internal view returns(IERC20) {
    return IERC20(clickAddress);
  }

  function slpToken() internal view returns(IERC20) {
    return IERC20(slpAddress);
  }

  // Modifiers

  modifier hasNotWon {
    require(hasWon[msg.sender] == false, "You've already won!");
    _;
  }

  modifier noBots {
    require(tx.origin == msg.sender, "Bad robot!");
    _;
  }

  // Clicky clicky

  function click() external hasNotWon noBots {
    ERC20PresetMinterPauser(clickAddress).mint(msg.sender, 1 * decimals);
  }

  // Hiring people!

  function hire(Hire _hire) external hasNotWon noBots {
    getRewards();
    uint hireCost = calcCost(_hire, hiredCount[msg.sender][_hire]);
    hiredCount[msg.sender][_hire] = hiredCount[msg.sender][_hire].add(1);
    rewardRate[msg.sender] = rewardRate[msg.sender].add(hireEarningsRate[_hire]);
    clickToken().safeTransferFrom(msg.sender, address(this), hireCost);
    ERC20PresetMinterPauser(clickAddress).burn(hireCost);
  }

  // Deposit SLP for Boost 

  function boost() external hasNotWon noBots {
    getRewards();
    require(boostedStatus[msg.sender] == false, "You've already boosted your earnings!");
    boostedStatus[msg.sender] = true;
    rewardRate[msg.sender] = rewardRate[msg.sender].mul(2);
    uint price = boostPrice;
    boostPrice = boostPrice.add(boostPriceIncrease);
    slpToken().safeTransferFrom(msg.sender, gameMaster, price);
  } 

  // Rewards 

  function getRewards() public noBots{
    uint timePassed = block.timestamp.sub(lastRewardCheckTime[msg.sender]);
    uint rewardsEarned = timePassed.mul(rewardRate[msg.sender]);
    lastRewardCheckTime[msg.sender] = block.timestamp;
    rewardsPaid[msg.sender] = rewardsPaid[msg.sender].add(rewardsEarned);
    ERC20PresetMinterPauser(clickAddress).mint(msg.sender, rewardsEarned);
  }

  // Game Over

  function win() public hasNotWon noBots {
    getRewards();

    uint winCost = winAmount;
    winAmount = (winCost.mul(costIncreaseRate)).div(10);

    winnerCounter.increment();
    uint winnerCount = winnerCounter.current();

    hasWon[msg.sender] = true;
    winnerIndex[msg.sender] = winnerCount;
    winners[winnerCount] = msg.sender;

    rewardsPaid[msg.sender] = 0;

    hiredCount[msg.sender][Hire.Intern] = 0;
    hiredCount[msg.sender][Hire.Graduate] = 0;
    hiredCount[msg.sender][Hire.MBA] = 0;
    hiredCount[msg.sender][Hire.PhD] = 0;
    hiredCount[msg.sender][Hire.Agency] = 0;
    hiredCount[msg.sender][Hire.Factory] = 0;
    hiredCount[msg.sender][Hire.Competitor] = 0;
    hiredCount[msg.sender][Hire.Country] = 0;

    clickToken().safeTransferFrom(msg.sender, address(this), winCost);
    ERC20PresetMinterPauser(clickAddress).burn(winCost);
  }

  // Utility functions

  function calcCost(Hire _hire, uint _increment) public view returns(uint) {
    uint bigMul = costIncreaseRate ** _increment;
    uint bigBase = bigMul.mul(baseHirePrice[_hire]);
    uint newCost = bigBase.div(10 ** _increment);
    return newCost;
  }

  // Admin Functions 

  function setSLPAddress(address _address) public onlyOwner {
    slpAddress = _address;
  }

  function setBoostPrice(uint _price) public onlyOwner {
    boostPrice = _price;
  }

  function setBoostPriceIncrease(uint _increase) public onlyOwner {
    boostPriceIncrease = _increase;
  }

  function updateGameMaster(address _address) public onlyOwner {
    gameMaster = _address;
  }

  // VIEW Functions

  function getClickAddress() public view returns(address) {
    return clickAddress;
  }

  function getRewardRate(address _address) public view returns(uint) {
    return rewardRate[_address];
  }

  function countHires(address _address, Hire _hire) public view returns(uint) {
    return hiredCount[_address][_hire];
  }

  function getLastRewardsTime(address _address) public view returns(uint) {
    return lastRewardCheckTime[_address];
  }

  function getPendingRewards(address _address) public view returns(uint) {
    uint timePassed = block.timestamp.sub(getLastRewardsTime(_address));
    return timePassed.mul(getRewardRate(_address));
  }

  function getNextCost(Hire _hire, address _address) public view returns(uint){
    return calcCost(_hire, hiredCount[_address][_hire]);
  }

  function getWinner(uint _index) public view returns(address) {
    return winners[_index];
  }

  function getWinnerPlace(address _address) public view returns(uint) {
    return winnerIndex[_address];
  }

  function getWinnerCount() public view returns(uint) {
    return winnerCounter.current();
  }
}