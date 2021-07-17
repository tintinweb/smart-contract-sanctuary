// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {DateTime} from "./DateTime.sol";

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because input values are based on chars arithmetics
// and the results are used solely for display purposes (generating a token SYMBOL).
// Moreover - input data is provided only by contract owners, as creation of tokens is limited to owner only.
library GenSymbol {
    function monthToHex(uint8 m) public pure returns (bytes1) {
        if (m > 0 && m < 10) {
            return bytes1(uint8(bytes1("0")) + m);
        } else if (m >= 10 && m < 13) {
            return bytes1(uint8(bytes1("A")) + (m - 10));
        }
        revert("Invalid month");
    }

    function tsToDate(uint256 _ts) public pure returns (string memory) {
        bytes memory date = new bytes(4);

        uint256 year = DateTime.getYear(_ts);

        require(year >= 2020, "Year cannot be before 2020 as it is coded only by one digit");
        require(year < 2030, "Year cannot be after 2029 as it is coded only by one digit");

        date[0] = bytes1(
            uint8(bytes1("0")) + uint8(year - 2020) // 2020 is coded as "0"
        );

        date[1] = monthToHex(DateTime.getMonth(_ts)); // October = 10 is coded by "A"

        uint8 day = DateTime.getDay(_ts); // Day is just coded as a day of month starting from 1
        require(day > 0 && day <= 31, "Invalid day");

        date[2] = bytes1(uint8(bytes1("0")) + (day / 10));
        date[3] = bytes1(uint8(bytes1("0")) + (day % 10));

        return string(date);
    }

    function RKMconvert(uint256 _num) public pure returns (bytes memory) {
        bytes memory map = "0000KKKMMMGGGTTTPPPEEEZZZYYY";
        uint8 len;

        uint256 i = _num;
        while (i != 0) {
            // Calculate the length of the input number
            len++;
            i /= 10;
        }

        bytes1 prefix = map[len]; // Get the prefix code letter

        uint8 prefixPos = len > 3 ? ((len - 1) % 3) + 1 : 0; // Position of prefix (or 0 if the number is 3 digits or less)

        // Get the leftmost 4 digits from input number or just take the number as is if its already 4 digits or less
        uint256 firstFour = len > 4 ? _num / 10**(len - 4) : _num;

        bytes memory bStr = "00000";
        // We start from index 4 ^ of zero-string and go left
        uint8 index = 4;

        while (firstFour != 0) {
            // If index is on prefix position - insert a prefix and decrease index
            if (index == prefixPos) bStr[index--] = prefix;
            bStr[index--] = bytes1(uint8(48 + (firstFour % 10)));
            firstFour /= 10;
        }
        return bStr;
    }

    function uint2str(uint256 _num) public pure returns (bytes memory) {
        if (_num > 99999) return RKMconvert(_num);

        if (_num == 0) {
            return "00000";
        }
        uint256 j = _num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bStr = "00000";
        uint256 k = 4;
        while (_num != 0) {
            bStr[k--] = bytes1(uint8(48 + (_num % 10)));
            _num /= 10;
        }
        return bStr;
    }

    function genOptionSymbol(
        uint256 _ts,
        string memory _type,
        bool put,
        uint256 _strikePrice
    ) external pure returns (string memory) {
        string memory putCall;
        putCall = put ? "P" : "C";
        return string(abi.encodePacked(_type, tsToDate(_ts), putCall, uint2str(_strikePrice)));
    }
}

// SPDX-License-Identifier: MIT
// Stripped version of the following:
// https://github.com/pipermerriam/ethereum-datetime
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because all of the operations are basic arithmetics
// (we have introduced a limit of year 2100 to definitely fit into uint16, hoping Year2100-problem will not be our problem)
// and the results are used solely for display purposes (generating a token SYMBOL).
// Moreover - input data is provided only by contract owners, as creation of tokens is limited to owner only.
library DateTime {
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
    }

    uint256 constant DAY_IN_SECONDS = 86400; // leap second?
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

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

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp) public pure returns (_DateTime memory dt) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
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

    function getYear(uint256 timestamp) public pure returns (uint16) {
        require(timestamp < 4102444800, "Years after 2100 aren't supported for sanity and safety reasons");
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) external pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) external pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/options/lib/DateTime.sol": {
      "DateTime": "0x5c2487fe4019a1214f9b72a171ce7b74df3a3a44"
    }
  }
}