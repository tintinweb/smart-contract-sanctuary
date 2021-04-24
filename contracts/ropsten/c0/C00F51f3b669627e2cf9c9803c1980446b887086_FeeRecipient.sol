/**
 *Submitted for verification at Etherscan.io on 2021-04-24
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
  function supplyRate(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRate(ILendingPair _pair, address _token) external view returns(uint);
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function feeRecipient() external view returns(address);
  function priceDelay() external view returns(uint);
  function slowPricePeriod() external view returns(uint);
  function slowPriceRange() external view returns(uint);
  function liqMinHealth() external view returns(uint);
  function liqFeePool() external view returns(uint);
  function liqFeeSystem() external view returns(uint);
  function liqFeeCaller() external view returns(uint);
  function liqFeesTotal() external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
}


interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function totalDebt(address _token) external view returns(uint);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawRepay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function swapTokenToToken(
    address  _fromToken,
    address  _toToken,
    address  _recipient,
    uint     _inputAmount,
    uint     _minOutput,
    uint     _deadline
  ) external returns(uint);
}

interface IFeeConverter {

  function convert(
    address _sender,
    ILendingPair _pair,
    address[] memory _path,
    uint _supplyTokenAmount
  ) external;
}


contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract FeeRecipient is Ownable {

  IFeeConverter public feeConverter;

  constructor(IFeeConverter _feeConverter) {
    feeConverter = _feeConverter;
  }

  function convert(
    ILendingPair _pair,
    address[] memory _path
  ) public {
    IERC20 lpToken = IERC20(_pair.lpToken(_path[0]));
    uint supplyTokenAmount = lpToken.balanceOf(address(this));
    lpToken.transfer(address(feeConverter), supplyTokenAmount);
    feeConverter.convert(msg.sender, _pair, _path, supplyTokenAmount);
  }

  function setFeeConverter(IFeeConverter _value) onlyOwner public {
    feeConverter = _value;
  }
}