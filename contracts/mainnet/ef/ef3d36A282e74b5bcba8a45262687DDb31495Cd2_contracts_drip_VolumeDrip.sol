// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";

import "../external/pooltogether/FixedPoint.sol";
import "../utils/ExtendedSafeCast.sol";

library VolumeDrip {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using ExtendedSafeCast for uint256;

  struct Deposit {
    uint112 balance;
    uint32 period;
  }

  struct Period {
    uint112 totalSupply;
    uint112 dripAmount;
    uint32 endTime;
  }

  struct State {
    mapping(address => Deposit) deposits;
    mapping(uint32 => Period) periods;
    uint32 nextPeriodSeconds;
    uint112 nextDripAmount;
    uint112 __gap;
    uint112 totalDripped;
    uint32 periodCount;
  }

  function setNewPeriod(
    State storage self,
    uint32 _periodSeconds,
    uint112 dripAmount,
    uint32 endTime
  )
    internal
    minPeriod(_periodSeconds)
  {
    self.nextPeriodSeconds = _periodSeconds;
    self.nextDripAmount = dripAmount;
    self.totalDripped = 0;
    self.periodCount = uint256(self.periodCount).add(1).toUint16();
    self.periods[self.periodCount] = Period({
      totalSupply: 0,
      dripAmount: dripAmount,
      endTime: endTime
    });
  }

  function setNextPeriod(
    State storage self,
    uint32 _periodSeconds,
    uint112 dripAmount
  )
    internal
    minPeriod(_periodSeconds)
  {
    self.nextPeriodSeconds = _periodSeconds;
    self.nextDripAmount = dripAmount;
  }

  function drip(
    State storage self,
    uint256 currentTime,
    uint256 maxNewTokens
  )
    internal
    returns (uint256)
  {
    if (_isPeriodOver(self, currentTime)) {
      return _completePeriod(self, currentTime, maxNewTokens);
    }
    return 0;
  }

  function mint(
    State storage self,
    address user,
    uint256 amount
  )
    internal
    returns (uint256)
  {
    if (self.periodCount == 0) {
      return 0;
    }
    uint256 accrued = _lastBalanceAccruedAmount(self, self.deposits[user].period, self.deposits[user].balance);
    uint32 currentPeriod = self.periodCount;
    if (accrued > 0) {
      self.deposits[user] = Deposit({
        balance: amount.toUint112(),
        period: currentPeriod
      });
    } else {
      self.deposits[user] = Deposit({
        balance: uint256(self.deposits[user].balance).add(amount).toUint112(),
        period: currentPeriod
      });
    }
    self.periods[currentPeriod].totalSupply = uint256(self.periods[currentPeriod].totalSupply).add(amount).toUint112();

    return accrued;
  }

  function currentPeriod(State storage self) internal view returns (Period memory) {
    return self.periods[self.periodCount];
  }

  function _isPeriodOver(State storage self, uint256 currentTime) private view returns (bool) {
    return currentTime >= self.periods[self.periodCount].endTime;
  }

  function _completePeriod(
    State storage self,
    uint256 currentTime,
    uint256 maxNewTokens
  ) private onlyPeriodOver(self, currentTime) returns (uint256) {
    // calculate the actual drip amount
    uint112 dripAmount;
    // If no one deposited, then don't drip anything
    if (self.periods[self.periodCount].totalSupply > 0) {
      dripAmount = self.periods[self.periodCount].dripAmount;
    }

    // if the drip amount is not valid, it has to be updated.
    if (dripAmount > maxNewTokens) {
      dripAmount = maxNewTokens.toUint112();
      self.periods[self.periodCount].dripAmount = dripAmount;
    }

    // if we are completing the period far into the future, then we'll have skipped a lot of periods.
    // Here we set the end time so that it's the next period from *now*
    uint256 lastEndTime = self.periods[self.periodCount].endTime;
    uint256 numberOfPeriods = currentTime.sub(lastEndTime).div(self.nextPeriodSeconds).add(1);
    uint256 endTime = lastEndTime.add(numberOfPeriods.mul(self.nextPeriodSeconds));
    self.totalDripped = uint256(self.totalDripped).add(dripAmount).toUint112();
    self.periodCount = uint256(self.periodCount).add(1).toUint16();

    self.periods[self.periodCount] = Period({
      totalSupply: 0,
      dripAmount: self.nextDripAmount,
      endTime: endTime.toUint32()
    });

    return dripAmount;
  }

  function _lastBalanceAccruedAmount(
    State storage self,
    uint32 depositPeriod,
    uint128 balance
  )
    private view
    returns (uint256)
  {
    uint256 accrued;
    if (depositPeriod < self.periodCount && self.periods[depositPeriod].totalSupply > 0) {
      uint256 fractionMantissa = FixedPoint.calculateMantissa(balance, self.periods[depositPeriod].totalSupply);
      accrued = FixedPoint.multiplyUintByMantissa(self.periods[depositPeriod].dripAmount, fractionMantissa);
    }
    return accrued;
  }

  modifier onlyPeriodNotOver(State storage self, uint256 _currentTime) {
    require(!_isPeriodOver(self, _currentTime), "VolumeDrip/period-over");
    _;
  }

  modifier onlyPeriodOver(State storage self, uint256 _currentTime) {
    require(_isPeriodOver(self, _currentTime), "VolumeDrip/period-not-over");
    _;
  }

  modifier minPeriod(uint256 _periodSeconds) {
    require(_periodSeconds > 0, "VolumeDrip/period-gt-zero");
    _;
  }
}
