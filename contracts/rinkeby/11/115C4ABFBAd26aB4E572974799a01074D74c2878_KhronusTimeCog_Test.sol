/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: Khronus-Project/[email protected]/KhronusTimeCog

library KhronusTimeCog {

     /* 
    Reference Constants
    MONTH_NORMALIZER_MULTIPLIER = 153;
    MONTH_NORMALIZER_COMPLEMENT = 2;
    MONTH_NORMALIZER_DIVISOR = 5;
    NORMAL_YEAR_DAYS = 365;
    */
    
    //Used Constants
    uint constant DAYS_IN_ERA = 146097;
    uint constant DAYS_TO_UNIXEPOCH = 719468;
    uint constant LIMIT_YEAR = 2200;
    uint constant LIMET_DAY_TIMESTAMP = 84006;
    uint constant BASE_YEAR = 1740;
    //Main Library Functions

    /*  
        Time format conversion functions 
        The functions below transform date formats either from date format to unix timestamp or from unix timestamp to date format.
    */

    //Get a timestamp in days since begining of unix epoch from a Civil Date to make it a Unix Timestamp multiply by number of seconds in day or solidity (1 days)
    function getDayTimestamp(uint _year, uint _month, uint _day) internal pure returns (uint _timestamp, uint _direction){
       require (isValidDate(_year, _month, _day), "not a valid date as input as date object");
       uint serializedDate = _serializeDate(_eralizeYear(_year, _month), _eralizeMonth(_month), _day);
       (serializedDate >= DAYS_TO_UNIXEPOCH) ? (_timestamp = serializedDate - DAYS_TO_UNIXEPOCH, _direction = 0):(_timestamp = DAYS_TO_UNIXEPOCH - serializedDate, _direction = 1);
    }
    
    //Get a Unix Timestamp from a full date-time object expressed as an array of 5 integers Year, Month, Day, Hour, Minute.
    function getDateObject(uint _timestamp, uint _direction) internal pure returns (uint[5] memory _result) {
        require (isValidTimestamp(_timestamp), "Not a valid day timestamp");
        (_result[0],_result[1],_result[2]) = _deserializeDate(_timestamp/1 days, _direction);
        _result[3] = (_timestamp % 1 days) / 1 hours;
        _result[4] = (_timestamp % 1 hours) / 1 minutes;
    }
    //Get a day Timestamp from a full date object expressed as an array of 3 integers Year, Month, Day, to make it a Unix Timestamp multiply by number of seconds in day or solidity (1 days)
    function getDateObjectShort(uint _timestampDays, uint _direction) internal pure returns (uint[3] memory _result) {
        require (isValidDayTimestamp(_timestampDays), "Not a valid day timestamp");
        (_result[0],_result[1],_result[2]) = _deserializeDate(_timestampDays, _direction);
    }
    
    //Time Delta
    function timeDelta(uint[3] memory _baseDate,uint[3] memory _comparedDate) internal pure returns (uint _timestampDays, uint _direction){
        require (isValidDate(_baseDate[0], _baseDate[1], _baseDate[2]) && isValidDate(_comparedDate[0], _comparedDate[1], _comparedDate[2]), "One of the dates is not valid");
        uint[2] memory baseT;
        (baseT[0], baseT[1])  = getDayTimestamp(_baseDate[0],_baseDate[1],_baseDate[2]);
        uint[2] memory comparedT;
        (comparedT[0], comparedT[1]) = getDayTimestamp(_comparedDate[0],_comparedDate[1],_comparedDate[2]);
        if (baseT[1] == comparedT[1]) {
            if (baseT[1] == 0){
                (baseT[0] >= comparedT[0]) ? (_timestampDays = baseT[0] - comparedT[0], _direction = 0): (_timestampDays = comparedT[0] - baseT[0], _direction = 1);
            }
            else{
                (baseT[0] >= comparedT[0]) ? (_timestampDays = baseT[0] - comparedT[0], _direction = 1): (_timestampDays = comparedT[0] - baseT[0], _direction = 0);
            }
        }
        else{
            (baseT[1] == 0) ? (_timestampDays = baseT[0] + comparedT[0], _direction = 0): (_timestampDays = baseT[0] + comparedT[0], _direction = 1);  
        }
    }

    //Next Unit of time

    function nextMinute(uint _timestamp) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        _result = _roundTimeUnit(_timestamp, 1 minutes) + 1  minutes;
    }

    function nextHour(uint _timestamp) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        _result = _roundTimeUnit(_timestamp, 1 hours) + 1 hours;
    }

    function nextDay(uint _timestamp) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        _result = _roundTimeUnit(_timestamp, 1 days) + 1 days;
    }

    
    function nextMonth(uint _timestamp) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        uint[3] memory dateObject;
        uint flag;
        (dateObject[0],dateObject[1],dateObject[2]) = _deserializeDate(_timestamp / 1 days,0);
        dateObject[2] = 1;
        (dateObject[1] + 1 > 12) ? (dateObject[1]=1,dateObject[0] +=1): (dateObject[1] += 1, dateObject[0] =dateObject[0]);
        (_result, flag) = getDayTimestamp(dateObject[0],dateObject[1],dateObject[2]);
        _result = (_result * 1 days);
    }

    //Add Units of Time

    function addMinutes(uint _timestamp, uint _minutes) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        _result = _timestamp + (_minutes * 1 minutes);
    }

    function addHours(uint _timestamp, uint _hours) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        _result = _timestamp + (_hours * 1 hours);
    }

    function addDays(uint _timestamp, uint _days) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        _result = _timestamp + (_days * 1 days);
    }

    function addMonths(uint _timestamp, uint _months) internal pure returns (uint _result) {
        require (isValidTimestamp(_timestamp), "Not a valid timestamp");
        uint[3] memory dateObject;
        uint remainder = _timestamp % 1 days;
        uint flag;
        (dateObject[0],dateObject[1],dateObject[2]) = _deserializeDate(_timestamp / 1 days,0);
        (dateObject[0],dateObject[1],dateObject[2]) = _addMonths(dateObject[0],dateObject[1],dateObject[2], _months);
        (_result, flag) = getDayTimestamp(dateObject[0],dateObject[1],dateObject[2]);
        _result = (_result * 1 days) + remainder;
    }

    //utility functions for Civil Dates
    function isLeapYear(uint _year) internal pure returns(bool _result) {
        _result = _result = (_year % 4 == 0 &&( _year % 100 > 0 ||  _year % 400 == 0)) ? true:false;
    }
    
    function getDaysInMonth(uint _year,uint _month)internal pure returns(uint _result) {
        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        _result = (isLeapYear(_year) && _month == 2) ? 29: daysInMonth[_month - 1];
    }

    function isValidDate(uint _year, uint _month, uint _day) internal pure returns(bool _result) {
        if (_year >= LIMIT_YEAR || _year < BASE_YEAR || _month < 1 || _month > 12 || _day < 1) {_result = false;}
        else{
            _result = (_day <= getDaysInMonth(_year, _month)) ? true: false;
        }
    }

    function isValidTimestamp(uint _timestamp) internal pure returns(bool _result) {
      return (_timestamp <= (LIMET_DAY_TIMESTAMP* 1 days));
    }

    function isValidDayTimestamp(uint _timestamp) internal pure returns(bool _result) {
       return _timestamp <= (LIMET_DAY_TIMESTAMP);
    }

    // Private Functions

    //Algorithm private functions for library use
    
    function _eralizeYear(uint _year, uint _month) private pure returns(uint _result){
        _result = (_month > 2) ? _year: _year -1;
    }

    function _eralizeMonth(uint _month) private pure returns (uint _result) {
        _result = (_month > 2) ? _month - 3: _month + 9;  
    }


    function _getBaseMonthDay(uint _eralizedMonth) private pure returns (uint _result) {
        _result = ((_eralizedMonth * 153) + 2) / 5;
    }
    
    function _serializeDate(uint _eralizedYear, uint _eralizedMonth, uint _day) private pure returns (uint _result) {
        uint eras = _eralizedYear / 400;
        uint yearOfEra = _eralizedYear % 400;
        uint dayOfYear = _getBaseMonthDay(_eralizedMonth) + _day -1;
        uint dayOfEra = (yearOfEra * 365) + ((yearOfEra)/4) - (yearOfEra/100) + dayOfYear;
        uint serializedDay = (eras* DAYS_IN_ERA) + dayOfEra;
        _result = serializedDay;
    }

    function _deserializeDate(uint _daysTimestamp, uint _direction) private pure returns (uint _year, uint _month, uint _day) {
        uint daysSinceBOT = (_direction == 0) ? DAYS_TO_UNIXEPOCH + _daysTimestamp:  DAYS_TO_UNIXEPOCH - _daysTimestamp;
        uint eras = daysSinceBOT/DAYS_IN_ERA;
        uint dayOfEra = daysSinceBOT % DAYS_IN_ERA;
        uint yearOfEra = (dayOfEra - (dayOfEra/1460) + (dayOfEra/36524) - (dayOfEra/146096))/365;
        uint eralizedYear = (eras * 400) + yearOfEra;
        uint eralizedDayOfYear = dayOfEra - ((yearOfEra*365) + (yearOfEra/4) - (yearOfEra/100));
        uint eralizedMonth = ((eralizedDayOfYear*5) + 2) /153;
        _month = (eralizedMonth < 10) ? eralizedMonth + 3: eralizedMonth - 9;
        _year = (_month < 3) ? eralizedYear + 1: eralizedYear; 
        _day = eralizedDayOfYear - _getBaseMonthDay(eralizedMonth) +1;
    }

    function _roundTimeUnit (uint _timestamp, uint _secondsUnit) private pure returns (uint _result) {
        _result = _timestamp - (_timestamp % _secondsUnit);
    }

    function _addMonths (uint _year, uint _month, uint _day, uint _months) private pure returns (uint _rYear, uint _rMonth, uint _rDay){
    uint yearsToAdd = _months/12;
    uint monthsToAdd = _months % 12;
    _rMonth = ((_month + monthsToAdd) % 12 == 0 ) ?  12: (_month + monthsToAdd) % 12;
    _rYear = (_month + monthsToAdd > 12)  ? _year + yearsToAdd + 1: _year + yearsToAdd;
    _rDay = _day > getDaysInMonth(_rYear, _rMonth) ? getDaysInMonth(_rYear, _rMonth): _day;
    }

}

// File: KhronusTimeCog_TestContract.sol

contract KhronusTimeCog_Test {

    /*  
        This is a contract implementation aimed to allow the testing of the TimeCog library. 
    */

    //Get a timestamp in days since begining of unix epoch from a Civil Date to make it a Unix Timestamp multiply by number of seconds in day or solidity (1 days)
    function getDayTimestamp(uint _year, uint _month, uint _day) external pure returns (uint _timestamp, uint _direction){
       (_timestamp, _direction) = KhronusTimeCog.getDayTimestamp(_year, _month, _day);
    }
    
    //Get a Unix Timestamp from a full date-time object expressed as an array of 5 integers Year, Month, Day, Hour, Minute.
    function getDateObject(uint _timestamp, uint _direction) external pure returns (uint[5] memory _result) {
        _result = KhronusTimeCog.getDateObject(_timestamp, _direction);
    }
    
    //Get a day Timestamp from a full date object expressed as an array of 3 integers Year, Month, Day, to make it a Unix Timestamp multiply by number of seconds in day or solidity (1 days)
    function getDateObjectShort(uint _timestampDays, uint _direction) external pure returns (uint[3] memory _result) {
        _result = KhronusTimeCog.getDateObjectShort(_timestampDays, _direction);
    }
    
    //Time Delta
    function timeDelta(uint[3] memory _baseDate,uint[3] memory _comparedDate) external pure returns (uint _timestampDays, uint _direction){
        (_timestampDays, _direction) = KhronusTimeCog.timeDelta(_baseDate, _comparedDate);
    }

    //Next Unit of time, these functions return the unix timestamp of the next unit of time, the returned timestamp is always rounded to the 0 value.
    function nextMinute(uint _timestamp) external pure returns (uint _result) {
        _result = KhronusTimeCog.nextMinute(_timestamp);
    }

    function nextHour(uint _timestamp) external pure returns (uint _result) {
        _result = KhronusTimeCog.nextHour(_timestamp);
    }

    function nextDay(uint _timestamp) external pure returns (uint _result) {
        _result = KhronusTimeCog.nextDay(_timestamp);
    }

    
    function nextMonth(uint _timestamp) external pure returns (uint _result) {
        _result = KhronusTimeCog.nextMonth(_timestamp);
    }

    //Add Units of Time

    function addMinutes(uint _timestamp, uint _minutes) external pure returns (uint _result) {
        _result = KhronusTimeCog.addMinutes(_timestamp, _minutes);
    }

    function addHours(uint _timestamp, uint _hours) external pure returns (uint _result) {
        _result = KhronusTimeCog.addHours(_timestamp, _hours);
    }
    
    function addDays(uint _timestamp, uint _days) external pure returns (uint _result) {
        _result = KhronusTimeCog.addDays(_timestamp, _days);
    }

    function addMonths(uint _timestamp, uint _months) external pure returns (uint _result) {
        _result = KhronusTimeCog.addMonths(_timestamp, _months);
    }
    
    //utility functions for Civil Dates
    function isLeapYear(uint _year) external pure returns(bool _result) {
        _result = KhronusTimeCog.isLeapYear(_year);
    }
    
    function getDaysInMonth(uint _year,uint _month)external pure returns(uint _result) {
        _result = KhronusTimeCog.getDaysInMonth(_year, _month);
    }

    function isValidDate(uint _year, uint _month, uint _day) external pure returns(bool _result) {
        _result = KhronusTimeCog.isValidDate(_year, _month, _day);
    }

    function isValidTimestamp(uint _timestamp) external pure returns(bool _result) {
        _result = KhronusTimeCog.isValidTimestamp(_timestamp);
    }

    function isValidDayTimestamp(uint _timestamp) external pure returns(bool _result) {
        _result = KhronusTimeCog.isValidDayTimestamp(_timestamp);
    }

}