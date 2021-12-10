// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2021 0xdev0 - All rights reserved
// https://twitter.com/0xdev0

pragma solidity 0.8.6;

import "IInterestRateModel.sol";
import "ILendingPair.sol";

import "Math.sol";
import "Ownable.sol";

contract InterestRateModel is IInterestRateModel, Ownable {

  // InterestRateModel can be re-deployed later
  uint private constant BLOCK_TIME = 13.2e18; // 13.2 seconds
  uint private constant LP_RATE = 50e18; // 50%

  // Per block
  uint public minRate;
  uint public lowRate;
  uint public highRate;
  uint public targetUtilization; // 80e18 = 80%

  event NewRates(uint minRate, uint lowRate, uint highRate);
  event NewTargetUtilization(uint value);

  constructor(
    uint _minRate,
    uint _lowRate,
    uint _highRate,
    uint _targetUtilization
  ) {

    setRates(_minRate, _lowRate, _highRate);
    setTargetUtilization(_targetUtilization);
  }

  function setRates(
    uint _minRate,
    uint _lowRate,
    uint _highRate
  ) public onlyOwner {

    require(_minRate < _lowRate,  "InterestRateModel: _minRate < _lowRate");
    require(_lowRate < _highRate, "InterestRateModel: _lowRate < highRate");

    minRate  = _timeRateToBlockRate(_minRate);
    lowRate  = _timeRateToBlockRate(_lowRate);
    highRate = _timeRateToBlockRate(_highRate);

    emit NewRates(_minRate, _lowRate, _highRate);
  }

  function setTargetUtilization(uint _value) public onlyOwner {
    require(_value > 0, "InterestRateModel: _value > 0");
    require(_value < 100e18, "InterestRateModel: _value < 100e18");
    targetUtilization = _value;
    emit NewTargetUtilization(_value);
  }

  // InterestRateModel can later be replaced for more granular fees per _pair
  function interestRatePerBlock(
    address _pair,
    address _token,
    uint    _totalSupply,
    uint    _totalDebt
  ) external view override returns(uint) {
    if (_totalSupply == 0 || _totalDebt == 0) { return minRate; }

    // Same as: (_totalDebt * 100e18 / _totalSupply) * 100e18 / targetUtilization
    uint utilization = _totalDebt * 100e18 * 100e18 / _totalSupply / targetUtilization;

    if (utilization < 100e18) {
      uint rate = lowRate * utilization / 100e18;
      return Math.max(rate, minRate);
    } else {
      utilization = 100e18 * ( _totalDebt - (_totalSupply * targetUtilization / 100e18) ) / (_totalSupply * (100e18 - targetUtilization) / 100e18);
      utilization = Math.min(utilization, 100e18);
      return lowRate + (highRate - lowRate) * utilization / 100e18;
    }
  }

  // Helper view function used only by the UI
  function utilizationRate(
    address _pair,
    address _token
  ) external view returns(uint) {
    ILendingPair pair = ILendingPair(_pair);
    uint totalSupply = pair.totalSupplyAmount(_token);
    uint totalDebt = pair.totalDebtAmount(_token);
    if (totalSupply == 0 || totalDebt == 0) { return 0; }
    return Math.min(totalDebt * 100e18 / totalSupply, 100e18);
  }

  // InterestRateModel can later be replaced for more granular fees per _pair
  function lpRate(address _pair, address _token) external view override returns(uint) {
    return LP_RATE;
  }

  // _uint is set as 1e18 = 1% (annual) and converted to the block rate
  function _timeRateToBlockRate(uint _uint) private view returns(uint) {
    return _uint * BLOCK_TIME / (365 * 86400 * 1e18);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IInterestRateModel {
  function lpRate(address _pair, address _token) external view returns(uint);
  function interestRatePerBlock(address _pair, address _token, uint _totalSupply, uint _totalDebt) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface ILendingPair {

  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(address);
  function deposit(address _account, address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function withdrawAll(address _token) external;
  function transferLp(address _token, address _from, address _to, uint _amount) external;
  function supplySharesOf(address _token, address _account) external view returns(uint);
  function totalSupplyShares(address _token) external view returns(uint);
  function totalSupplyAmount(address _token) external view returns(uint);
  function totalDebtShares(address _token) external view returns(uint);
  function totalDebtAmount(address _token) external view returns(uint);
  function supplyOf(address _token, address _account) external view returns(uint);

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

contract Ownable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 12 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}