pragma solidity 0.4.20;

library StrUtil {
  function concat(string _a, string _b) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory bab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }

  function bytes32ToString(bytes32 x) internal pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  function uintToBytes(uint v) internal pure returns (bytes32 ret) {
    if (v == 0) {
      ret = &#39;0&#39;;
    }
    else {
      while (v > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
        v /= 10;
      }
    }
    return ret;
  }

  function uintToString(uint v) internal pure returns (string) {
    return bytes32ToString(uintToBytes(v));
  }
}

library DateTime {

  using StrUtil for string;
  /*
   *  Date and Time utilities for ethereum contracts
   *
   */
  struct _DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
  }

  uint constant DAY_IN_SECONDS = 86400;
  uint constant YEAR_IN_SECONDS = 31536000;
  uint constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint constant HOUR_IN_SECONDS = 3600;
  uint constant MINUTE_IN_SECONDS = 60;

  uint16 constant ORIGIN_YEAR = 1970;

  function isLeapYear(uint16 year) public pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint year) public pure returns (uint) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      return 31;
    }
    else if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    }
    else if (isLeapYear(year)) {
      return 29;
    }
    else {
      return 28;
    }
  }

  function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
    uint secondsAccountedFor = 0;
    uint buf;
    uint8 i;

    // Year
    dt.year = getYear(timestamp);
    buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

    // Month
    uint secondsInMonth;
    for (i = 1; i <= 12; i++) {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) {
        dt.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
        dt.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }
  }

  function getYear(uint timestamp) public pure returns (uint16) {
    uint secondsAccountedFor = 0;
    uint16 year;
    uint numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      }
      else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function getMonth(uint timestamp) public pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint timestamp) public pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function monthStr(uint timestamp) internal pure returns (string ret) {
    uint8 month = getMonth(timestamp);

    if (month == 1) { ret = "Jan"; }
    if (month == 2) { ret = "Feb"; }
    if (month == 3) { ret = "Mar"; }
    if (month == 4) { ret = "Apr"; }
    if (month == 5) { ret = "May"; }
    if (month == 6) { ret = "Jun"; }
    if (month == 7) { ret = "Jul"; }
    if (month == 8) { ret = "Aug"; }
    if (month == 9) { ret = "Sept"; }
    if (month == 10) { ret = "Oct"; }
    if (month == 11) { ret = "Nov"; }
    if (month == 12) { ret = "Dec"; }
  }

  function toString(uint timestamp) internal pure returns (string ret) {
    string memory month = monthStr(timestamp);
    string memory day   = StrUtil.uintToString(getDay(timestamp));
    string memory year  = StrUtil.uintToString(getYear(timestamp));

    ret = ret.concat(day)
             .concat(" ")
             .concat(month)
             .concat(" ")
             .concat(year);
  }
}

contract Marriage {

  using StrUtil for string;

  enum Status {
    Affianced,
    SignedByGroom,
    Married
  }

  Status status = Status.Affianced;
  
  address groomAddr;
  address brideAddr;
  
  uint256 public marriedAt = 0;
  uint256 groomSignedAt = 0;
  uint256 deposite = 0;

  string  public groom;
  string  public bride;

  string  public groomVow;
  string  public brideVow;

  function Marriage(address _groomAddr, address _brideAddr, 
                    string _groom, string _bride) public {
    groomAddr = _groomAddr;
    brideAddr = _brideAddr;
    groom = _groom;
    bride = _bride;

    groomVow = groomVow
                    .concat("I, ")
                    .concat(_groom)
                    .concat(", take thee, ")
                    .concat(_bride)
                    .concat(", to be my wedded Wife, to have and to hold from this day forward, for better for worse, for richer for poorer, in sickness and in health, to love and to cherish, till death us do part.");

    brideVow = brideVow
                    .concat("I, ")
                    .concat(_bride)
                    .concat(", take thee, ")
                    .concat(_groom)
                    .concat(", to be my wedded Husband, to have and to hold from this day forward, for better for worse, for richer for poorer, in sickness and in health, to love, cherish, and to obey, till death us do part.");
  }

  function () external payable {
    doMarriage();
  }

  function doMarriage() private {
    if (msg.sender == groomAddr) {
      signByGroom();
    } else if (msg.sender == brideAddr) {
      signByBride();
    } else {
      revert();
    }
  }

  function signByGroom() private onlyGroom {
    require(status == Status.Affianced);
    
    // groom has to deposite at least a half of his balance to initiate marriage
    require(msg.value > 0);
    require(msg.value >= groomAddr.balance);
    
    deposite = msg.value;
    groomSignedAt = now;
    status = Status.SignedByGroom;
  }

  function signByBride() private onlyBride {
    require(status == Status.SignedByGroom);

    marriedAt = now;
    status = Status.Married;

    // just in case if bride sent some funds
    // it&#39;s gonna be added to the family budget :)
    groomAddr.transfer(deposite + msg.value);
  }

  function cancel() external onlyGroom {
    require(status == Status.SignedByGroom);
    require(now - groomSignedAt >= 1 minutes);

    status = Status.Affianced;

    groomAddr.transfer(deposite);
  }

  function getStatus() public view returns (string ret) {
    if (status == Status.Affianced) {
      ret = ret.concat(groom)
         .concat(" and ")
         .concat(bride)
         .concat(" are affianced");
    } else if (status == Status.SignedByGroom) {
      ret = ret.concat(groom)
         .concat(" has signed");
    } else {
      ret = ret.concat(groom)
         .concat(" and ")
         .concat(bride)
         .concat(" got married on ")
         .concat(DateTime.toString(marriedAt));
    }
  }

  modifier onlyGroom() {
    require(msg.sender == groomAddr);
    _; 
  }

  modifier onlyBride() {
    require(msg.sender == brideAddr);
    _; 
  }
}