/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2021 0xdev0 - All rights reserved
// https://twitter.com/0xdev0

pragma solidity ^0.8.0;

interface IERC20 {
  function initialize() external;
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

interface IInterestRateModel {
  function systemRate(ILendingPair _pair) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function feeRecipient() external view returns(address);
  function liqMinHealth() external view returns(uint);
  function liqFeePool() external view returns(uint);
  function liqFeeSystem() external view returns(uint);
  function liqFeeCaller() external view returns(uint);
  function liqFeesTotal() external view returns(uint);
  function tokenPrice(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
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
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawRepay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

contract InterestRateModel {

  // Per block
  uint public constant MIN_RATE  = 0;
  uint public constant LOW_RATE  = 8371385083713;   // 20%    / year = 20e18   / 365 / 86400 * 13.2 (block time)
  uint public constant HIGH_RATE = 418569254185692; // 1,000% / year = 1000e18 / 365 / 86400 * 13.2 (block time)

  uint public constant TARGET_UTILIZATION = 80e18; // 80%
  uint public constant SYSTEM_RATE        = 50e18; // share of fees earned by the system

  function supplyRatePerBlock(ILendingPair _pair, address _token) public view returns(uint) {
    return borrowRatePerBlock(_pair, _token) * (100e18 - SYSTEM_RATE) / 100e18;
  }

  function borrowRatePerBlock(ILendingPair _pair, address _token) public view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return MIN_RATE; }

    uint utilization = _max(debt * 100e18 / supply, 100e18);

    if (utilization < TARGET_UTILIZATION) {
      uint rate = LOW_RATE * utilization / 100e18;
      return (rate < MIN_RATE) ? MIN_RATE : rate;
    } else {
      utilization = 100e18 * ( debt - (supply * TARGET_UTILIZATION / 100e18) ) / (supply * (100e18 - TARGET_UTILIZATION) / 100e18);
      utilization = _max(utilization, 100e18);
      return LOW_RATE + (HIGH_RATE - LOW_RATE) * utilization / 100e18;
    }
  }

  function utilizationRate(ILendingPair _pair, address _token) public view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return 0; }

    return _max(debt * 100e18 / supply, 100e18);
  }

  // InterestRateModel can later be replaced for more granular fees per _lendingPair
  function systemRate(ILendingPair _pair) public pure returns(uint) {
    return SYSTEM_RATE;
  }

  function _max(uint _valueA, uint _valueB) internal pure returns(uint) {
    return _valueA > _valueB ? _valueB : _valueA;
  }
}