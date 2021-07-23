/**
 *Submitted for verification at Etherscan.io on 2021-07-23
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

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract InterestRateModel is Ownable {

  // InterestRateModel can be re-deployed later
  uint private constant BLOCK_TIME = 132e17; // 13.2 seconds

  // Per block
  uint public minRate;
  uint public lowRate;
  uint public highRate;
  uint public targetUtilization; // 80e18 = 80%
  uint public systemRateDefault; // 50e18 - share of fees earned by the system

  event NewMinRate(uint value);
  event NewLowRate(uint value);
  event NewHighRate(uint value);
  event NewTargetUtilization(uint value);
  event NewSystemRateDefault(uint value);

  constructor(
    uint _minRate,
    uint _lowRate,
    uint _highRate,
    uint _targetUtilization,
    uint _systemRateDefault
  ) {
    minRate           = _timeRateToBlockRate(_minRate);
    lowRate           = _timeRateToBlockRate(_lowRate);
    highRate          = _timeRateToBlockRate(_highRate);
    targetUtilization = _targetUtilization;
    systemRateDefault = _systemRateDefault;
  }

  function setMinRate(uint _value) external onlyOwner {
    require(_value < lowRate, "InterestRateModel: _value < lowRate");
    minRate = _timeRateToBlockRate(_value);
    emit NewMinRate(_value);
  }

  function setLowRate(uint _value) external onlyOwner {
    require(_value < highRate, "InterestRateModel: _value < lowRate");
    lowRate = _timeRateToBlockRate(_value);
    emit NewLowRate(_value);
  }

  function setHighRate(uint _value) external onlyOwner {
    highRate = _timeRateToBlockRate(_value);
    emit NewHighRate(_value);
  }

  function setTargetUtilization(uint _value) external onlyOwner {
    require(_value < 99e18, "InterestRateModel: _value < 100e18");
    targetUtilization = _value;
    emit NewTargetUtilization(_value);
  }

  function setSystemRate(uint _value) external onlyOwner {
    require(_value < 100e18, "InterestRateModel: _value < 100e18");
    systemRateDefault = _value;
    emit NewSystemRateDefault(_value);
  }

  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint) {
    return borrowRatePerBlock(_pair, _token) * (100e18 - systemRateDefault) / 100e18;
  }

  function borrowRatePerBlock(ILendingPair _pair, address _token) public view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return minRate; }

    uint utilization = (debt * 100e18 / supply) * 100e18 / targetUtilization;

    if (utilization < 100e18) {
      uint rate = lowRate * utilization / 100e18;
      return Math.max(rate, minRate);
    } else {
      utilization = 100e18 * ( debt - (supply * targetUtilization / 100e18) ) / (supply * (100e18 - targetUtilization) / 100e18);
      utilization = Math.min(utilization, 100e18);
      return lowRate + (highRate - lowRate) * utilization / 100e18;
    }
  }

  function utilizationRate(ILendingPair _pair, address _token) external view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return 0; }

    return Math.min(debt * 100e18 / supply, 100e18);
  }

  // InterestRateModel can later be replaced for more granular fees per _lendingPair
  function systemRate(ILendingPair _pair, address _token) external view returns(uint) {
    return systemRateDefault;
  }

  // _uint is set as 1e18 = 1% (annual) and converted to the block rate
  function _timeRateToBlockRate(uint _uint) private view returns(uint) {
    return _uint / 365 / 86400 * BLOCK_TIME / 1e18;
  }
}