// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IBOOST.sol";
import "./Ownable.sol";

contract LOOTStakingPool is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor(address _loot, address _silver) {
    LOOT = IERC20(_loot);
    SILVER = IERC20(_silver);
  }

  IERC20 private LOOT;
  IERC20 private SILVER;
  IBOOST private BOOST;

  function setBoostContract(address _address) public onlyOwner {
    BOOST = IBOOST(_address);
  }

  address private feeAddress = 0x4Cf135b4f0236B0fC55DfA9a09B25843416cE023;

  mapping(address => uint256) private stakedBalance;
  mapping(address => uint256) public lastUpdateTime;
  mapping(address => uint256) public reward;

  event Staked(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event Redeem(address indexed user, uint256 amount);

  modifier updateReward(address account) {
    if (account != address(0)) {
      reward[account] = earned(account);
      lastUpdateTime[account] = block.timestamp;
    }
    _;
  }

  function balanceOf(address account) public view returns (uint256) {
    return stakedBalance[account];
  }

  function manualUpdate(address account) public nonReentrant {
    if (account != address(0)) {
      reward[account] = earned(account);
      lastUpdateTime[account] = block.timestamp;
    }
  }

  function earned(address account) public view returns (uint256) {
    uint256 blockTime = block.timestamp;
    uint256 earnedAmount = blockTime.sub(lastUpdateTime[account]).mul(balanceOf(account)).div(432000);
    if (BOOST.hasBoost(account) == true) {
      earnedAmount = earnedAmount.mul(11).div(10);
    }
    return reward[account].add(earnedAmount);
  }

  function stake(uint256 amount) public updateReward(_msgSender()) nonReentrant {
    require(amount >= 100, "Too small stake");
    uint256 fee = amount.div(100);
    uint256 stakeAmount = amount.sub(fee);
    stakedBalance[_msgSender()] = stakedBalance[_msgSender()].add(stakeAmount);
    LOOT.transferFrom(_msgSender(), address(this), amount);
    LOOT.transfer(feeAddress, fee);
    emit Staked(_msgSender(), stakeAmount);
  }

  function withdraw(uint256 amount) public updateReward(_msgSender()) nonReentrant {
    require(amount > 0, "Cannot withdraw 0");
    require(amount <= balanceOf(_msgSender()), "Cannot withdraw more than balance");
    uint256 fee = amount.div(50);
    uint256 stakeAmount = amount.sub(fee);
    LOOT.transfer(_msgSender(), stakeAmount);
    LOOT.transfer(feeAddress, fee);
    stakedBalance[_msgSender()] = stakedBalance[_msgSender()].sub(amount);
    emit Unstake(_msgSender(), stakeAmount);
  }

  function exit() external {
    withdraw(balanceOf(_msgSender()));
  }
    
  function redeem() public updateReward(_msgSender()) nonReentrant {
    require(reward[_msgSender()] > 0, "Nothing to redeem");
    uint256 amount = reward[_msgSender()];
    reward[_msgSender()] = 0;
    SILVER.mint(_msgSender(), amount);
    emit Redeem(_msgSender(), amount);
  }
}