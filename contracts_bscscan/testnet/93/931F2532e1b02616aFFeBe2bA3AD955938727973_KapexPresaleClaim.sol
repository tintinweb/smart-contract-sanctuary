//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IKapexPresale.sol";
import "./interfaces/IKapexPresaleBuyRouter.sol";
import "./libraries/BokkyPooBahsDateTimeLibrary.sol";

contract KapexPresaleClaim {
  using BokkyPooBahsDateTimeLibrary for uint256;

  address private owner;
  uint256 private minClaim; // In wei
  uint256 private maxClaimPercentage; // Max Claim that Account can do in a interval (percentage of bought (BNB))
  uint256 public feeDenominator = 10**9; // fee denominator

  address private kapexPresaleAddress;
  address private kapexPresaleBuyRouterAddress;

  IKapexPresale private kapexPresale; // Contract
  IKapexPresaleBuyRouter private kapexPresaleBuyRouter; // Contract

  mapping(address => uint256) public totalClaim;
  mapping(address => uint256) public firstClaimTimestamp;

  bool private claimPaused = true; // Claiming is not available, would be started later

  uint256 private claimIntervalDay; // Date Interval in integer
  uint256 private claimIntervalHour; // Hour Interval in integer

  string private defaultBand;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can access this function");
    _;
  }

  constructor(
    address _kapexPresaleAddress,
    address _kapexPresaleBuyRouterAddress,
    uint256 _minClaim,
    uint256 _maxClaimPercentage,
    uint256 _claimIntervalDay,
    uint256 _claimIntervalHour,
    string memory _defaultBand
  ) {
    owner = msg.sender;
    minClaim = _minClaim;
    maxClaimPercentage = _maxClaimPercentage;

    kapexPresaleAddress = _kapexPresaleAddress;
    kapexPresale = IKapexPresale(_kapexPresaleAddress);

    kapexPresaleBuyRouterAddress = _kapexPresaleBuyRouterAddress;
    kapexPresaleBuyRouter = IKapexPresaleBuyRouter(_kapexPresaleBuyRouterAddress);

    claimIntervalDay = _claimIntervalDay;
    claimIntervalHour = _claimIntervalHour;

    defaultBand = _defaultBand;
  }

  //////////
  // Getters

  function getOwner() external view returns (address) {
    return (owner);
  }

  function getMinClaim() external view returns (uint256) {
    return (minClaim);
  }

  function getMaxClaimPercentage() external view returns (uint256) {
    return (maxClaimPercentage);
  }

  function getKapexPresale() external view returns (address) {
    return (kapexPresaleAddress);
  }

  function getClaimIntervalDay() external view returns (uint256) {
    return (claimIntervalDay);
  }

  function getClaimIntervalHour() external view returns (uint256) {
    return (claimIntervalHour);
  }

  function getDefaultBand() external view returns (string memory) {
    return (defaultBand);
  }

  function isClaimPaused() external view returns (bool) {
    return (claimPaused);
  }

  function calculateBNBToPresaleToken(uint256 _amount) public view returns (uint256) {
    address presaleToken = kapexPresale.getPresaleToken();
    require(presaleToken != address(0), "Presale token not set");

    uint256 tokens = ((_amount * kapexPresale.getPrice()) / 100) /
      (10**(18 - uint256(IERC20(presaleToken).decimals())));

    string memory allocatedBand = kapexPresale.allocatedBand(msg.sender);
    if (bytes(allocatedBand).length == 0) {
      allocatedBand = defaultBand;
    }

    uint256 tokensWithBand = tokens + (tokens * kapexPresale.bandsPercentages(allocatedBand)) / 10**9;

    return (tokensWithBand);
  }

  function getAvailableTokenToClaim() public view returns (uint256) {
    uint256 totalKapex = calculateBNBToPresaleToken(getTotalBought());
    return ((totalKapex * getTotalClaimPercentage()) / feeDenominator) - totalClaim[msg.sender];
  }

  function getTotalClaimPercentage() private view returns (uint256) {
    if (firstClaimTimestamp[msg.sender] == 0) {
      return maxClaimPercentage;
    } else {
      (, , uint256 day, uint256 hour, , ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(block.timestamp);
      uint256 interval = BokkyPooBahsDateTimeLibrary.diffMonths(firstClaimTimestamp[msg.sender], block.timestamp);
      if (day > claimIntervalDay || (day == claimIntervalDay && hour >= claimIntervalHour) || interval == 0) {
        interval += 1;
      }
      uint256 totalIntervalPercentage = interval * maxClaimPercentage > feeDenominator
        ? feeDenominator
        : interval * maxClaimPercentage;
      return totalIntervalPercentage;
    }
  }

  function getTotalBought() public view returns (uint256) {
    return (kapexPresale.bought(msg.sender) + kapexPresaleBuyRouter.bought(msg.sender));
  }

  /////////////
  // Claim tokens

  function claim(uint256 requestedAmount) public {
    require(kapexPresaleAddress != address(0), "Kapex Presale not set");
    require(block.timestamp > kapexPresale.getStartDateClaim(), "Claim hasn't started yet");
    require(!claimPaused, "Claiming is paused");
    require(!kapexPresale.isEnded(), "Sale has ended");
    require(requestedAmount >= minClaim, "msg.value is less than minClaim");

    address presaleToken = kapexPresale.getPresaleToken();
    require(presaleToken != address(0), "Presale token not set");

    uint256 remainingToken = calculateBNBToPresaleToken(getTotalBought()) - totalClaim[msg.sender];
    require(remainingToken >= requestedAmount, "msg.sender don't have enough token to claim");

    require(
      IERC20(presaleToken).balanceOf(address(this)) >= requestedAmount,
      "Contract doesnt have enough presale tokens. Please contact owner to add more supply"
    );
    require(
      (requestedAmount <= getAvailableTokenToClaim()),
      "msg.sender claim more than max claim amount in this interval"
    );

    if (firstClaimTimestamp[msg.sender] == 0) {
      firstClaimTimestamp[msg.sender] = block.timestamp;
    }
    totalClaim[msg.sender] += requestedAmount;

    IERC20(presaleToken).transfer(msg.sender, requestedAmount);
  }

  //////////////////
  // Owner functions

  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function setKapexPresale(address _kapexPresaleAddress) external onlyOwner {
    kapexPresaleAddress = _kapexPresaleAddress;
    kapexPresale = IKapexPresale(_kapexPresaleAddress);
  }

  function setMinClaim(uint256 _minClaim) external onlyOwner {
    minClaim = _minClaim;
  }

  function setMaxClaimPercentage(uint256 _maxClaimPercentage) external onlyOwner {
    maxClaimPercentage = _maxClaimPercentage;
  }

  function setClaimIntervalDay(uint256 _claimIntervalDay) external onlyOwner {
    claimIntervalDay = _claimIntervalDay;
  }

  function setClaimIntervalHour(uint256 _claimIntervalHour) external onlyOwner {
    claimIntervalHour = _claimIntervalHour;
  }

  function setDefaultBand(string memory _defaultBand) external onlyOwner {
    defaultBand = _defaultBand;
  }

  function setClaimPause() external onlyOwner {
    if (claimPaused) {
      require(kapexPresale.getPresaleToken() != address(0), "Presale token not set");

      claimPaused = false;
    } else {
      claimPaused = true;
    }
  }

  function withdrawAllToken() external onlyOwner {
    address presaleToken = kapexPresale.getPresaleToken();
    require(presaleToken != address(0), "Presale token not set");
    uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
    if (contractBal > 0) IERC20(presaleToken).transfer(msg.sender, contractBal);
  }
}

pragma solidity >=0.5.0;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

pragma solidity =0.8.6;

interface IKapexPresale {
  function claim() external;

  function getStartDateClaim() external view returns (uint256);

  function getPresaleToken() external view returns (address);

  function getPrice() external view returns (uint256);

  function isClaimPaused() external view returns (bool);

  function bandsPercentages(string memory) external view returns (uint256);

  function allocatedBand(address) external view returns (string memory);

  function bought(address) external view returns (uint256);

  function isEnded() external view returns (bool);

  function isBuyPaused() external view returns (bool);

  function getStartDateBuy() external view returns (uint256);

  function getHouseToken() external view returns (address);

  function getMinHouseTokenHoldAmount() external view returns (uint256);

  function getMaxPurcase() external view returns (uint256);

  function getMinBNB() external view returns (uint256);

  function getMaxBNB() external view returns (uint256);

  function buy() external payable;
}

pragma solidity =0.8.6;

interface IKapexPresaleBuyRouter {
  function bought(address) external view returns (uint256);

  function getOwner() external view returns (address);

  function getKapexPresaleAddress() external view returns (address);

  function getMinBNB() external view returns (uint256);

  function getMaxBNB() external view returns (uint256);

  function getMaxPurchase() external view returns (uint256);

  function isBuyPaused() external view returns (bool);

  function getTotalBought() external view returns (uint256);

  function buy() external payable;
}

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 constant SECONDS_PER_HOUR = 60 * 60;
  uint256 constant SECONDS_PER_MINUTE = 60;
  int256 constant OFFSET19700101 = 2440588;

  uint256 constant DOW_MON = 1;
  uint256 constant DOW_TUE = 2;
  uint256 constant DOW_WED = 3;
  uint256 constant DOW_THU = 4;
  uint256 constant DOW_FRI = 5;
  uint256 constant DOW_SAT = 6;
  uint256 constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 _days) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (uint256 timestamp) {
    timestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      hour *
      SECONDS_PER_HOUR +
      minute *
      SECONDS_PER_MINUTE +
      second;
  }

  function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
    (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
    (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
    (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
    uint256 secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}