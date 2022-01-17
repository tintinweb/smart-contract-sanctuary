//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Fixed.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract ETHPool is AccessControl {
  using SafeMath for uint256;
  using Fixed for uint256;

  mapping(address => uint256) public deposits;
  mapping(address => uint256) public unrewardedDeposits;

  uint256 public totalDeposits;
  uint256 public totalRewards;
  uint256 public rewardPerDeposit;

  event Deposit(
    address indexed sender,
    uint256 amount
  );

  event Withdraw(
    address indexed to,
    uint256 depositAmount,
    uint256 rewardAmount
  );

  event DepositReward(
    address indexed sender,
    uint256 amount
  );

  event AddTeam(
    address indexed user
  );

  event RemoveTeam(
    address indexed user
  );

  constructor() {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function deposit() external payable {
    deposits[msg.sender] += msg.value;
    totalDeposits += msg.value;

    uint256 _unrewardedDeposit = rewardPerDeposit.mul(msg.value).toInt();
    unrewardedDeposits[msg.sender] = unrewardedDeposits[msg.sender].add(_unrewardedDeposit);

    emit Deposit(payable(msg.sender), msg.value);
  }

  function depositReward() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
    require(totalDeposits > 0, "No Deposits");
    totalRewards += msg.value;

    uint256 _rewardRatio = msg.value.toFixed().div(totalDeposits);
    rewardPerDeposit = rewardPerDeposit.add(_rewardRatio);

    emit DepositReward(payable(msg.sender), msg.value);
  }

  function withdraw() public {
    require(deposits[msg.sender] > 0, "No Deposits");

    uint256 _deposit = deposits[msg.sender];
    uint256 _reward = reward();
    uint256 _total = _deposit + _reward;
    payable(msg.sender).transfer(_total);
    
    totalDeposits -= _deposit;
    totalRewards -= _reward;

    deposits[msg.sender] = 0;
    unrewardedDeposits[msg.sender] = 0;

    emit Withdraw(payable(msg.sender), _deposit, _reward);
  }

  function reward() public view returns (uint256 amount) {
    uint256 _deposit = deposits[msg.sender];
    uint256 _reward = _deposit.mul(rewardPerDeposit).toInt();
    uint256 _netReward = _reward - unrewardedDeposits[msg.sender];
    return _netReward;
  }

  function balance() public view returns (uint256 amount) {
    uint256 _deposit = deposits[msg.sender];
    return _deposit;
  }

  function addTeam(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, account);
    emit AddTeam(account);
  }

  function removeTeam(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(DEFAULT_ADMIN_ROLE, account);
    emit RemoveTeam(account);
  }
}