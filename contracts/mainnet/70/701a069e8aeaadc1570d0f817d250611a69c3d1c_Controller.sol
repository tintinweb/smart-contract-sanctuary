/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: UNLICENSED

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
  function setFeeRecipient(address _feeRecipient) external;
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

interface IInterestRateModel {
  function systemRate(ILendingPair _pair) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IPriceOracle {
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
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

contract Controller is Ownable {

  IInterestRateModel public interestRateModel;
  IPriceOracle public priceOracle;

  uint public liqMinHealth; // 15e17 = 1.5
  uint public liqFeeSystem; // 5e18  = 5%
  uint public liqFeeCaller; // 5e18  = 5%

  mapping(address => mapping(address => uint)) public depositLimit;

  address public feeRecipient;

  constructor(
    IInterestRateModel _interestRateModel,
    uint _liqMinHealth,
    uint _liqFeeSystem,
    uint _liqFeeCaller
  ) {
    feeRecipient = msg.sender;
    interestRateModel = _interestRateModel;

    setLiqParams(_liqMinHealth, _liqFeeSystem, _liqFeeCaller);
  }

  function setFeeRecipient(address _feeRecipient) public onlyOwner {
    require(_feeRecipient != address(0), 'PairFactory: _feeRecipient != 0x0');
    feeRecipient = _feeRecipient;
  }

  function setLiqParams(
    uint _liqMinHealth,
    uint _liqFeeSystem,
    uint _liqFeeCaller
  ) public onlyOwner {
    // Never more than a total of 20%
    require(_liqFeeSystem + _liqFeeCaller <= 20e18, "PairFactory: fees too high");

    liqMinHealth = _liqMinHealth;
    liqFeeSystem = _liqFeeSystem;
    liqFeeCaller = _liqFeeCaller;
  }

  function setInterestRateModel(IInterestRateModel _value) onlyOwner public {
    interestRateModel = _value;
  }

  function setPriceOracle(IPriceOracle _oracle) onlyOwner public {
    priceOracle = _oracle;
  }

  function setDepositLimit(address _pair, address _token, uint _value) public onlyOwner {
    depositLimit[_pair][_token] = _value;
  }

  function liqFeesTotal() public view returns(uint) {
    return liqFeeSystem + liqFeeCaller;
  }

  function tokenPrice(address _token) public view returns(uint) {
    return priceOracle.tokenPrice(_token);
  }

  function tokenSupported(address _token) public view returns(bool) {
    return priceOracle.tokenSupported(_token);
  }
}