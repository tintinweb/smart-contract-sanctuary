/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract dateAndTime {
    struct Date {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
        uint256 weekDays;
    }

    uint256 constant Year_In_Seconds = 31536000;
    uint256 constant Leap_year_In_Seconds = 31622400;
    uint256 constant Day_In_Seconds = 86400;
    uint256 constant Hour_In_Seconds = 3600;
    uint256 constant MInute_In_Seconds = 60;
    uint256 constant Origin_Year = 1970;

    function isLeapYear(uint256 _year) public pure returns (bool) {
        if (_year % 4 != 0) {
            return false;
        }
        if (_year % 100 != 0) {
            return true;
        }
        if (_year % 400 != 0) {
            return false;
        }
        return true;
    }

    function TotalLeapYearTillNow(uint256 _year) public pure returns (uint256) {
        _year -= 1;
        return _year / 4 - _year / 100 + _year / 400;
    }

    function getDaysInMonth(uint256 _month, uint256 _year)
        public
        pure
        returns (uint256)
    {
        require(_month <= 12, "Error:Invalid Argument Count");
        if (
            _month == 1 ||
            _month == 3 ||
            _month == 5 ||
            _month == 7 ||
            _month == 8 ||
            _month == 10 ||
            _month == 12
        ) {
            return 31;
        } else if (_month == 4 || _month == 6 || _month == 9 || _month == 11) {
            return 30;
        } else if (isLeapYear(_year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function getYear(uint256 timeStamp) public pure returns (uint256) {
        uint256 secondsAccountedFor = 0;
        uint256 year;
        uint256 leapYears;
        year = (Origin_Year + timeStamp / Year_In_Seconds);
        leapYears =
            TotalLeapYearTillNow(year) -
            TotalLeapYearTillNow(Origin_Year);
        secondsAccountedFor += leapYears * Leap_year_In_Seconds;
        secondsAccountedFor +=
            Year_In_Seconds *
            (year - Origin_Year - leapYears);
        while (secondsAccountedFor > timeStamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= Leap_year_In_Seconds;
            } else {
                secondsAccountedFor -= Leap_year_In_Seconds;
            }
            year -= 1;
        }
        return year;
    }

    function parseTimeStamp(uint256 timeStamp)
        public
        pure
        returns (Date memory DAT)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint256 i;

        DAT.year = getYear(timeStamp);
        buf =
            TotalLeapYearTillNow(DAT.year) -
            TotalLeapYearTillNow(Origin_Year);
        secondsAccountedFor += Leap_year_In_Seconds * buf;
        secondsAccountedFor += Year_In_Seconds * (DAT.year - Origin_Year - buf);

        uint256 secondsInMonth;
        for (i = 0; i <= 12; i++) {
            secondsInMonth = Day_In_Seconds * getDaysInMonth(i, DAT.year);
            if (secondsInMonth + secondsAccountedFor > timeStamp) {
                DAT.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        for (i = 0; i < getDaysInMonth(DAT.month, DAT.year); i++) {
            if (Day_In_Seconds + secondsAccountedFor > timeStamp) {
                DAT.day = 1;
                break;
            }
            secondsAccountedFor += Day_In_Seconds;
        }

        DAT.hour = getHour(timeStamp);
        DAT.minute = getMinute(timeStamp);
        DAT.second = getSecond(timeStamp);
        DAT.weekDays = getWeekDays(timeStamp);
    }

    function getMonth(uint256 timeStamp) public pure returns (uint256) {
        return parseTimeStamp(timeStamp).month;
    }

    function getDay(uint256 timeStamp) public pure returns (uint256) {
        return parseTimeStamp(timeStamp).day;
    }

    function getHour(uint256 timeStamp) public pure returns (uint256) {
        return uint256((timeStamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timeStamp) public pure returns (uint256) {
        return uint256((timeStamp / 60) % 60);
    }

    function getSecond(uint256 timeStamp) public pure returns (uint256) {
        return uint256(timeStamp % 60);
    }

    function getWeekDays(uint256 timeStamp) public pure returns (uint256) {
        return uint256((timeStamp / Day_In_Seconds + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimeStamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimeStamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimeStamp(year, month, day, hour, minute, 0);
    }

    function toTimeStamp(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) public pure returns (uint256 timeStamp) {
        uint256 i;

        for (i = Origin_Year; i < year; i++) {
            if (isLeapYear(i)) {
                timeStamp += Leap_year_In_Seconds;
            } else {
                timeStamp += Year_In_Seconds;
            }
        }

        uint256[12] memory daysInMonth;
        daysInMonth[0] = 31;
        if (isLeapYear(year)) {
            daysInMonth[1] = 29;
        } else {
            daysInMonth[1] = 28;
        }
        daysInMonth[2] = 31;
        daysInMonth[3] = 30;
        daysInMonth[4] = 31;
        daysInMonth[5] = 30;
        daysInMonth[6] = 31;
        daysInMonth[7] = 31;
        daysInMonth[8] = 30;
        daysInMonth[9] = 31;
        daysInMonth[10] = 30;
        daysInMonth[11] = 31;

        for (i = 1; i < month; i++) {
            timeStamp += Day_In_Seconds * daysInMonth[i - 1];
        }
        timeStamp += Day_In_Seconds * (day - 1);
        timeStamp += Hour_In_Seconds * (hour);
        timeStamp += MInute_In_Seconds * minute;
        timeStamp += second;
        return timeStamp;
    }
}