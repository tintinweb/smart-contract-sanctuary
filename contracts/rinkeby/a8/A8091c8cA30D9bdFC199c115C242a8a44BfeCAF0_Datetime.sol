/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
 
contract Datetime {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
 
    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;
 
    uint constant ORIGIN_YEAR = 1970;
    uint constant internal OFFSET19700101 = 2440588;
    uint constant internal SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant internal SECONDS_PER_HOUR = 60 * 60;
    function daysToDate(uint timestamp, uint timezone) public pure returns (uint year, uint month, uint day){
        return _daysToDate(timestamp + timezone * uint(SECONDS_PER_HOUR));
    }
    //时间戳转日期，UTC时区
    function _daysToDate(uint timestamp) private pure returns (uint year, uint month, uint day) {
        uint _days = uint(timestamp) / SECONDS_PER_DAY;
 
        uint L = _days + 68569 + OFFSET19700101;
        uint N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * year / 4 + 31;
        month = 80 * L / 2447;
        day = L - 2447 * month / 80;
        L = month / 11;
        month = month + 2 - 12 * L;
        year = 100 * (N - 49) + year + L;
    }

    function getNum(uint timestamp, uint timezone) public pure returns(uint num){
      
      (uint year,uint month,uint day) = daysToDate(timestamp,timezone);
      num = year*10000+month*100+day;
    }
    //判断输入的年份是不是闰年
    function isLeapYear(uint year) public pure returns (bool) {
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
 
    //判断输入的年份 的闰年前
    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }
 
    //输入年year   月month  得到当月的天数
    function getDaysInMonth(uint month, uint year) public pure returns (uint8) {
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
    function getDay(uint _timestamp) public view returns (uint) {
      uint nowTime = _timestamp - delYear(_timestamp);
      uint m;
      uint timeSign = 0;
      for(m = 1;timeSign<getMonth(_timestamp);m++){
        timeSign += getDaysInMonth(m,getYears(_timestamp))*DAY_IN_SECONDS;
      }
      nowTime -= timeSign;
      uint d = nowTime/DAY_IN_SECONDS;
      return d;
    }
    /* function delMonth(uint _timestamp) public view returns (uint) {
      uint m;
      uint timeSign = 0;
      for(m = 1;timeSign<getMonth(_timestamp);m++){
        timeSign += getDaysInMonth(m,getYears(_timestamp))*DAY_IN_SECONDS;
      }
      return delYear(_timestamp) + timeSign;
    } */
    function getMonth(uint _timestamp) public view returns (uint) {
      uint nowTime = _timestamp - delYear(_timestamp);
      uint m;
      uint timeSign = 0;
      for(m = 0;timeSign<=nowTime;m++){
        timeSign += getDaysInMonth(m+1,getYears(_timestamp))*DAY_IN_SECONDS;
      }
      return m;
    }
    function delYear(uint _timestamp) public view returns (uint) {
      uint nowTime = _timestamp;
      uint timeSign = 0;
      uint y;
      for(y=ORIGIN_YEAR;timeSign<=nowTime;y++){
          if(isLeapYear(y)){
            timeSign += LEAP_YEAR_IN_SECONDS;
          }else{
            timeSign += YEAR_IN_SECONDS;
          }
      }
      if(isLeapYear(getYears(_timestamp)+1)){
        timeSign -= LEAP_YEAR_IN_SECONDS;
      }else{
        timeSign -= YEAR_IN_SECONDS;
      }
      return timeSign;
    }
    function getYears(uint _timestamp) public view returns (uint) {
      uint nowTime = _timestamp;
      uint timeSign = 0;
      uint y;
      for(y=ORIGIN_YEAR;timeSign<=nowTime;y++){
          if(isLeapYear(y)){
            timeSign += LEAP_YEAR_IN_SECONDS;
          }else{
            timeSign += YEAR_IN_SECONDS;
          }
      }
      y = y - 1;
      return y;
    }

}