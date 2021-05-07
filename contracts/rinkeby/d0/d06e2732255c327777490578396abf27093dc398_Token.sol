// SPDX-License-Identifier: UNLICENSED
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.4;
import "./DateTime.sol";

// Hardhat exposes a console.log which is very useful in development
// but make sure to remove it before deployment
// import "hardhat/console.sol";

// This is the main building block for smart contracts.
contract Token {
    using DateTime for uint;

    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    // 'private' means that the variable cannot be seen form outside,
    // but getter functions have been provided for each to return their value
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 private _totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
    address private _owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) private _balances;

    // Here is a mapping that gives how much accounts have been approved to spend 
    // from other accounts
    mapping(address => mapping(address => uint256)) private _allowances;

    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address sender, address recipient, uint256 amount);

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }

    function getTimes() public view returns(uint year, uint month, uint day, uint hour, uint minute, uint second) {
         (year, month, day, hour, minute, second) = DateTime._nowDateTime();
         return (year, month, day, hour, minute, second);
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external returns(bool) {
        // console.log("Sender balance is %s tokens", _balances[msg.sender]);
        // console.log("Trying to send %s tokens to %s", amount, to);
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(_balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev returns the allowance the spender has been approved to spend 
     * from the owner
     * @param owner_ address: the address of the owner of the funds
     * @param spender address: the address of the spender
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    /**
     * Read-only function to retrieve the total supply at the time queried
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Read-only function to retrieve the decimals of the token
     */
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    /**
     * Read-only function to retrieve the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Read-only function to retrieve the name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * Read-only function to retrieve the symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * Allows a user to approve another account to spend their funds
     *
     * @param spender address: the address to be approved
     * @param amount uint256: the amount to approve
     */
    function approve(address spender, uint256 amount) public returns(bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * If approved, allows the user to send funds from another account
     *
     * @param from address: the address to send the funds from
     * @param to address: the address to send the funds to
     * @param amount uint256: the amount to send
     */
    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        require(_allowances[from][msg.sender] >= amount);
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * Mints tokens to a target address
     *
     * @param recipient address: the address to mint the token to
     * @param amount uint256: the amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) public {
        _totalSupply += amount;
        _balances[recipient] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    /**
     * Burns tokens from the user's account
     *
     * @param amount uint256: the amount of tokens to burn
     */
    function burn(uint256 amount) public {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * If approved, allows a user to burn another user's tokens
     *
     * @param from address: the address to burn from
     * @param amount uint256: the amount of token to burn
     */
    function burnFrom(address from, uint256 amount) public {
        require(_allowances[from][msg.sender] >= amount);
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _totalSupply += amount;

        emit Transfer(from, address(0), amount);
    }
}

pragma solidity ^0.8.4;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
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
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

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
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
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
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00 - Contract Instance
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

library DateTime {
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant SECONDS_PER_HOUR = 60 * 60;
    uint public constant SECONDS_PER_MINUTE = 60;
    int public constant OFFSET19700101 = 2440588;

    uint public constant DOW_MON = 1;
    uint public constant DOW_TUE = 2;
    uint public constant DOW_WED = 3;
    uint public constant DOW_THU = 4;
    uint public constant DOW_FRI = 5;
    uint public constant DOW_SAT = 6;
    uint public constant DOW_SUN = 7;

    function _now() public view returns (uint timestamp) {
        timestamp = block.timestamp;
    }
    function _nowDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = DateTimeLibrary.timestampToDateTime(block.timestamp);
    }
    function _daysFromDate(uint year, uint month, uint day) public pure returns (uint _days) {
        return DateTimeLibrary._daysFromDate(year, month, day);
    }
    function _daysToDate(uint _days) public pure returns (uint year, uint month, uint day) {
        return DateTimeLibrary._daysToDate(_days);
    }
    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        return DateTimeLibrary.timestampFromDate(year, month, day);
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        return DateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
    }
    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = DateTimeLibrary.timestampToDate(timestamp);
    }
    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = DateTimeLibrary.timestampToDateTime(timestamp);
    }

    function isValidDate(uint year, uint month, uint day) public pure returns (bool valid) {
        valid = DateTimeLibrary.isValidDate(year, month, day);
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (bool valid) {
        valid = DateTimeLibrary.isValidDateTime(year, month, day, hour, minute, second);
    }
    function isLeapYear(uint timestamp) public pure returns (bool leapYear) {
        leapYear = DateTimeLibrary.isLeapYear(timestamp);
    }
    function _isLeapYear(uint year) public pure returns (bool leapYear) {
        leapYear = DateTimeLibrary._isLeapYear(year);
    }
    function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
        weekDay = DateTimeLibrary.isWeekDay(timestamp);
    }
    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = DateTimeLibrary.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint timestamp) public pure returns (uint daysInMonth) {
        daysInMonth = DateTimeLibrary.getDaysInMonth(timestamp);
    }
    function _getDaysInMonth(uint year, uint month) public pure returns (uint daysInMonth) {
        daysInMonth = DateTimeLibrary._getDaysInMonth(year, month);
    }
    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = DateTimeLibrary.getDayOfWeek(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        year = DateTimeLibrary.getYear(timestamp);
    }
    function getMonth(uint timestamp) public pure returns (uint month) {
        month = DateTimeLibrary.getMonth(timestamp);
    }
    function getDay(uint timestamp) public pure returns (uint day) {
        day = DateTimeLibrary.getDay(timestamp);
    }
    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = DateTimeLibrary.getHour(timestamp);
    }
    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = DateTimeLibrary.getMinute(timestamp);
    }
    function getSecond(uint timestamp) public pure returns (uint second) {
        second = DateTimeLibrary.getSecond(timestamp);
    }

    function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addYears(timestamp, _years);
    }
    function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addMonths(timestamp, _months);
    }
    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addDays(timestamp, _days);
    }
    function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addHours(timestamp, _hours);
    }
    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addMinutes(timestamp, _minutes);
    }
    function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addSeconds(timestamp, _seconds);
    }

    function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subYears(timestamp, _years);
    }
    function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subMonths(timestamp, _months);
    }
    function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subDays(timestamp, _days);
    }
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subHours(timestamp, _hours);
    }
    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subMinutes(timestamp, _minutes);
    }
    function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
        _years = DateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
        _months = DateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = DateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        _hours = DateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
        _minutes = DateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
        _seconds = DateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
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
    "contracts/DateTime.sol": {
      "DateTime": "0xed3d336c0894f85a0964c8af305eee41292ce3c8"
    }
  }
}