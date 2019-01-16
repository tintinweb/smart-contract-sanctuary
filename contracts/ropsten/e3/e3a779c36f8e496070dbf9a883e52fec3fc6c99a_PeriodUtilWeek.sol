pragma solidity ^0.4.24;

// File: contracts/PeriodUtil.sol

/**
 * @title PeriodUtil
 * 
 * Interface used for Period calculation to allow better automated testing of Fees Contract
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract PeriodUtil {
    /**
    * @dev calculates the Period index for the given timestamp
    * @return Period count since EPOCH
    * @param timestamp The time in seconds since EPOCH (blocktime)
    */
    function getPeriodIdx(uint256 timestamp) public pure returns (uint256);
    
    /**
    * @dev Timestamp of the period start
    * @return Time in seconds since EPOCH of the Period Start
    * @param periodIdx Period Index to find the start timestamp of
    */
    function getPeriodStartTimestamp(uint256 periodIdx) public pure returns (uint256);

    /**
    * @dev Returns the Cycle count of the given Periods. A set of time creates a cycle, eg. If period is weeks the cycle can be years.
    * @return The Cycle Index
    * @param timestamp The time in seconds since EPOCH (blocktime)
    */
    function getPeriodCycle(uint256 timestamp) public pure returns (uint256);

    /**
    * @dev Amount of Tokens per time unit since the start of the given periodIdx
    * @return Tokens per Time Unit from the given periodIdx start till now
    * @param tokens Total amount of tokens from periodIdx start till now (blocktime)
    * @param periodIdx Period IDX to use for time start
    */
    function getRatePerTimeUnits(uint256 tokens, uint256 periodIdx) public view returns (uint256);

    /**
    * @dev Amount of time units in each Period, for exampe if units is hour and period is week it will be 168
    * @return Amount of time units per period
    */
    function getUnitsPerPeriod() public pure returns (uint256);
}

// File: contracts/PeriodUtilWeek.sol

/**
 * @title PeriodUtilWeek
 * 
 * Used to calculate Weeks and Years
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract PeriodUtilWeek is PeriodUtil {
  
    uint256 public constant HOURS_IN_WEEK = 168;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint16 constant ORIGIN_YEAR = 1970;


    /**
    * @dev calculates the Week index for the given timestamp
    * @return Weeks count since EPOCH
    * @param timestamp The time in seconds since EPOCH (blocktime)
    */
    function getPeriodIdx(uint256 timestamp) public pure returns (uint256) {
        return timestamp / 1 weeks;
    }

    /**
    * @dev Timestamp of the Week start
    * @return Time in seconds since EPOCH of the Period Start
    * @param periodIdx Period Index to find the start timestamp of
    */
    function getPeriodStartTimestamp(uint256 periodIdx) public pure returns (uint256) {
        // Safty for uint overflow (safe till year 2928)
        assert(periodIdx < 50000);
        return 1 weeks * periodIdx;
    }

    /**
    * @dev Returns the Cycle count of the given Periods. A set of time creates a cycle, eg. If period is weeks the cycle can be years.
    * @return The Cycle Index
    * @param timestamp The time in seconds since EPOCH (blocktime)
    */
    function getPeriodCycle(uint256 timestamp) public pure returns (uint256) {
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
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    /**
     * @dev Returns the amount of leap years before the given date
     */
    function leapYearsBefore(uint256 _year) public pure returns (uint256) {
        uint256 year = _year - 1;
        return year / 4 - year / 100 + year / 400;
    }

    /**
     * @dev Is the given year a leap Year
     */
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

    /**
    * @dev Amount of Tokens per time unit since the start of the given periodIdx
    * @return Tokens per Time Unit from the given periodIdx start till now
    * @param tokens Total amount of tokens from periodIdx start till now (blocktime)
    * @param periodIdx Period IDX to use for time start
    */
    function getRatePerTimeUnits(uint256 tokens, uint256 periodIdx) public view returns (uint256) {
        if (tokens <= 0)
          return 0;
        uint256 hoursSinceTime = hoursSinceTimestamp(getPeriodStartTimestamp(periodIdx));
        return tokens / hoursSinceTime;
    }

    /**
    * @dev Hours since given timestamp
    * @param timestamp Timestamp in seconds since EPOCH to calculate hours to
    * @return Retuns the number of hours since the given timestamp and blocktime
    */
    function hoursSinceTimestamp(uint256 timestamp) public view returns (uint256) {
        assert(now > timestamp);
        return (now - timestamp) / 1 hours;
    }

    /**
    * @dev Amount of time units in each Period, for exampe if units is hour and period is week it will be 168
    * @return Amount of time units per period
    */
    function getUnitsPerPeriod() public pure returns (uint256) {
        return HOURS_IN_WEEK;
    }
}