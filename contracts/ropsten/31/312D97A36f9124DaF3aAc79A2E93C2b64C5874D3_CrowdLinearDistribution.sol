// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./Ownable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract CrowdLinearDistribution is Ownable {

    event CrowdLinearDistributionCreated(address beneficiary);
    event logEvent(uint256 step);

    event CrowdLinearDistributionInitialized(address from);
    event CrowdLinearDistributionUpdated(uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare);
    event TokensReleased(address beneficiary, uint256 amount);
    event CrowdLinearDistributionRevoked(address beneficiary);

    struct CrowdLinearDistributionStruct {
        uint256 _start;
        uint256 _cliff;
        uint256 _initialShare;
        uint256 _periodicShare;
        uint256 _released;
        uint256 _balance;
        uint256 _vestingType;
        uint256 _factor;
        bool _exist;
    }

    uint256 private allocated;

    mapping(address => CrowdLinearDistributionStruct) public _beneficiaryIndex;
    address[] public _beneficiaries;
    address public _tokenAddress;

    fallback() external {
        revert("ce01");
    }
    
    constructor () {}

    /**
     * @notice initialize contract.
     */
    function initialize(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0) , "CrowdLinearDistribution: token address not valid");
        _tokenAddress = tokenAddress;

        emit CrowdLinearDistributionInitialized(address(msg.sender));
    }
    
    function create(address beneficiary, uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, uint256 vestingType, uint256 factor, uint256 balance) onlyOwner external {
        require(!_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary exists");
        require(_tokenAddress != address(0), "CrowdLinearDistribution: token address not valid");
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(address(this));
        require(contractBalance >= allocated + balance, "CrowdLinearDistribution: Not enough token to distribute");

        _beneficiaries.push(beneficiary);
        _beneficiaryIndex[beneficiary] = CrowdLinearDistributionStruct(start, cliff, initialShare, periodicShare, 0, balance, vestingType, factor, true);
        allocated = allocated + balance;
        
        emit CrowdLinearDistributionCreated(beneficiary);
    }

    /**
     * @notice Returns the releasable amount of token for the given beneficiary
     */
    function getReleasable(address beneficiary) public view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _vestedAmount(beneficiary) - _beneficiaryIndex[beneficiary]._released;
    }
    
    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release(address beneficiary) external {
        require(_tokenAddress != address(0), "CrowdLinearDistribution: token address not valid");
        uint256 unreleased = getReleasable(beneficiary);

        require(unreleased > 0, "CrowdLinearDistribution: releasable amount is zero");

        _beneficiaryIndex[beneficiary]._released = _beneficiaryIndex[beneficiary]._released + unreleased;
        _beneficiaryIndex[beneficiary]._balance = _beneficiaryIndex[beneficiary]._balance - unreleased;
        
        IERC20(_tokenAddress).transfer(beneficiary, unreleased);

        emit TokensReleased(address(beneficiary), unreleased);
    }
    
    /**
    * @notice Allows the owner to revoke the vesting.
    */
    function revoke(address beneficiary) external onlyOwner {
        require(_beneficiaryIndex[beneficiary]._vestingType >= 10, "CrowdLinearDistribution: Distribution is not revocable");
        require(_tokenAddress != address(0), "CrowdLinearDistribution: token address not valid");

        uint256 releasable = getReleasable(beneficiary);
        IERC20(_tokenAddress).transfer(beneficiary, releasable);

        //(getBalance(beneficiary) - releasable) amount, is not released and also is not allocated anymore, so return them to the contract
        allocated = allocated - (getBalance(beneficiary) - releasable);

        delete _beneficiaryIndex[beneficiary];

        emit TokensReleased(beneficiary, releasable);
        emit CrowdLinearDistributionRevoked(beneficiary);
    }

    function getBeneficiaries(uint256 vestingType) external view returns (address[] memory) {
        uint256 j = 0;
        address[] memory beneficiaries = new address[](_beneficiaries.length);

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            if (_beneficiaryIndex[beneficiary]._vestingType == vestingType) {
                beneficiaries[j] = beneficiary;
                j++;
            }

        }
        return beneficiaries;
    }

    function getVestingType(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._vestingType;
    }

    function getBeneficiary(address beneficiary) external view returns (CrowdLinearDistributionStruct memory) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary not exists");

        return _beneficiaryIndex[beneficiary];
    }

    function getInitialShare(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._initialShare;
    }

    function getPeriodicShare(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._periodicShare;
    }

    function getStart(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._start;
    }

    function getCliff(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._cliff;
    }

    function getTotal(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._balance + _beneficiaryIndex[beneficiary]._released;
    }

    function getVested(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _vestedAmount(beneficiary);
    }

    function getReleased(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._released;
    }
    
    function getBalance(address beneficiary) public view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistributionFactory: beneficiary does not exist");

        return uint256(_beneficiaryIndex[beneficiary]._balance);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount(address beneficiary) private view returns (uint256) {
        CrowdLinearDistributionStruct memory tokenVesting = _beneficiaryIndex[beneficiary];
        uint256 currentBalance = tokenVesting._balance;
        uint256 totalBalance = currentBalance + tokenVesting._released;
        uint256 initialRelease = tokenVesting._initialShare;

        if (block.timestamp < tokenVesting._start)
            return 0;

        if (block.timestamp < tokenVesting._cliff)
            return initialRelease;

        uint256 _months = BokkyPooBahsDateTimeLibrary.diffMonths(tokenVesting._cliff, block.timestamp);

        uint256 previousMonth = tokenVesting._periodicShare;
        uint256 sum = tokenVesting._periodicShare;

        for (uint256 i = 1; i <= _months; ++i) {
            previousMonth = previousMonth + (tokenVesting._factor * previousMonth) / (1 ether);
            sum += previousMonth;
        }

        return (sum >= totalBalance) ? totalBalance : sum;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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

library BokkyPooBahsDateTimeLibrary {

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
        require(year >= 1970, "BP01");
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
        require(newTimestamp >= timestamp, "BP02");
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
        require(newTimestamp >= timestamp, "BP02");
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp, "BP02");
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp, "BP02");
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp, "BP02");
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp, "BP02");
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp, "BP03");
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
        require(newTimestamp <= timestamp, "BP03");
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp, "BP03");
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp, 'BP03');
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp, 'BP03');
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp, 'BP03');
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ce30");
        _;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == _pendingOwner, "ce31");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _pendingOwner);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}