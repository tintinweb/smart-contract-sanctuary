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
      uint nowTime = _timestamp;
      uint y;
      for(y=getYears(_timestamp);ORIGIN_YEAR<=y;y--){
          if(isLeapYear(y)){
            nowTime -= LEAP_YEAR_IN_SECONDS;
          }else{
            nowTime -= YEAR_IN_SECONDS;
          }
      }
      
      uint m;
      for(m=getMonth(_timestamp);1<=m;m--){
        nowTime -= getDaysInMonth(m,getYears(_timestamp))*DAY_IN_SECONDS;
      }
      
      uint d;
      d = nowTime/DAY_IN_SECONDS;
      return d;
    }
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