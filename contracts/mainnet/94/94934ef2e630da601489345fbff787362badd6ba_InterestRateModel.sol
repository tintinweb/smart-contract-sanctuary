/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IInterestRateModel {
  function systemRate(ILendingPair _pair, address _token) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IRewardDistribution {
  function distributeReward(address _account, address _token) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function rewardDistribution() external view returns(IRewardDistribution);
  function feeRecipient() external view returns(address);
  function LIQ_MIN_HEALTH() external view returns(uint);
  function minBorrowUSD() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function originFee(address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function setFeeRecipient(address _feeRecipient) external;
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function accrueAccount(address _account) external;
  function accrue() external;
  function accountHealth(address _account) external view returns(uint);
  function totalDebt(address _token) external view returns(uint);
  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function pendingDebtTotal(address _token) external view returns(uint);
  function pendingSupplyTotal(address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute.
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

contract InterestRateModel {

  // Per block
  uint public constant MIN_RATE  = 0;
  uint public constant LOW_RATE  = 8371385083713;   // 20%    / year = 20e18   / 365 / 86400 * 13.2 (block time)
  uint public constant HIGH_RATE = 418569254185692; // 1,000% / year = 1000e18 / 365 / 86400 * 13.2 (block time)

  uint public constant TARGET_UTILIZATION = 80e18; // 80%
  uint public constant SYSTEM_RATE        = 50e18; // share of fees earned by the system

  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint) {
    return borrowRatePerBlock(_pair, _token) * (100e18 - SYSTEM_RATE) / 100e18;
  }

  function borrowRatePerBlock(ILendingPair _pair, address _token) public view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return MIN_RATE; }

    uint utilization = (debt * 100e18 / supply) * 100e18 / TARGET_UTILIZATION;

    if (utilization < 100e18) {
      uint rate = LOW_RATE * utilization / 100e18;
      return Math.max(rate, MIN_RATE);
    } else {
      utilization = 100e18 * ( debt - (supply * TARGET_UTILIZATION / 100e18) ) / (supply * (100e18 - TARGET_UTILIZATION) / 100e18);
      utilization = Math.min(utilization, 100e18);
      return LOW_RATE + (HIGH_RATE - LOW_RATE) * utilization / 100e18;
    }
  }

  function utilizationRate(ILendingPair _pair, address _token) external view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return 0; }

    return Math.min(debt * 100e18 / supply, 100e18);
  }

  // InterestRateModel can later be replaced for more granular fees per _lendingPair
  function systemRate(ILendingPair _pair, address _token) external pure returns(uint) {
    return SYSTEM_RATE;
  }
}