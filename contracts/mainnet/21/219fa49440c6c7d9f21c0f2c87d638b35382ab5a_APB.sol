pragma solidity ^0.4.23;

library SafeMathLib {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DateTimeLib {

    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) internal pure returns (bool) {
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

    function leapYearsBefore(uint year) internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
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

        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        dt.hour = getHour(timestamp);
        dt.minute = getMinute(timestamp);
        dt.second = getSecond(timestamp);
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) internal pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

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

    function getMonth(uint timestamp) internal pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) internal pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) internal pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) internal pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) internal pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) internal pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint timestamp) {
        uint16 i;
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            }
            else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
        else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        timestamp += DAY_IN_SECONDS * (day - 1);
        timestamp += HOUR_IN_SECONDS * (hour);
        timestamp += MINUTE_IN_SECONDS * (minute);
        timestamp += second;

        return timestamp;
    }
}

interface IERC20 {
    
    function totalSupply() external constant returns (uint256);
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address _spender, uint256 _value);
}

contract StandardToken is IERC20,DateTimeLib {

    using SafeMathLib for uint256;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;
    
    string public constant symbol = "APB";
    
    string public constant name = "AmpereX Bank";
    
    uint _totalSupply = 10000000000 * 10 ** 6;
    
    uint8 public constant decimals = 6;
    
    function totalSupply() external constant returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return transferInternal(msg.sender, _to, _value);
    }

    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(_value > 0 && balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value > 0 && allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract LockableToken is StandardToken {
    
    address internal developerReservedAddress = 0x80a1B223b944A86e517349CBB414965bC501d104;
    
    uint[8] internal developerReservedUnlockTimes;
    
    uint256[8] internal developerReservedBalanceLimits;
    
    function getDeveloperReservedBalanceLimit() internal returns (uint256 balanceLimit) {
        uint time = now;
        for (uint index = 0; index < developerReservedUnlockTimes.length; index++) {
            if (developerReservedUnlockTimes[index] == 0x0) {
                continue;
            }
            if (time > developerReservedUnlockTimes[index]) {
                developerReservedUnlockTimes[index] = 0x0;
            } else {
                return developerReservedBalanceLimits[index];
            }
        }
        return 0;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return transferInternal(msg.sender, _to, _value);
    }

    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(_from != 0x0 && _to != 0x0 && _value > 0x0);
        if (_from == developerReservedAddress) {
            uint256 balanceLimit = getDeveloperReservedBalanceLimit();
            require(balances[_from].sub(balanceLimit) >= _value);
        }
        return super.transferInternal(_from, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != 0x0 && _to != 0x0 && _value > 0x0);
        if (_from == developerReservedAddress) {
            uint256 balanceLimit = getDeveloperReservedBalanceLimit();
            require(balances[_from].sub(balanceLimit) >= _value);
        }
        return super.transferFrom(_from, _to, _value);
    }
    
    event UnlockTimeChanged(uint index, uint unlockTime, uint newUnlockTime);
    event LockInfo(address indexed publicOfferingAddress, uint index, uint unlockTime, uint256 balanceLimit);
}

contract TradeableToken is LockableToken {

    address internal publicOfferingAddress = 0xdC23333Acb4dAAd88fcF66D2807DB7c8eCDFa6dc;

    uint256 public exchangeRate = 100000;

    function buy(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != 0x0);
        require(publicOfferingAddress != 0x0);
        require(exchangeRate > 0x0);
        require(_weiAmount > 0x0);

        uint256 exchangeToken = _weiAmount.mul(exchangeRate);
        exchangeToken = exchangeToken.div(1 * 10 ** 12);

        publicOfferingAddress.transfer(_weiAmount);
        super.transferInternal(publicOfferingAddress, _beneficiary, exchangeToken);
    }
    
    event ExchangeRateChanged(uint256 oldExchangeRate,uint256 newExchangeRate);
}

contract OwnableToken is TradeableToken {
    
    address internal owner = 0x59923219FEC7dd1Bfc4C14076F4a216b90f3AEdC;
    
    mapping(address => uint) administrators;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdministrator() {
        require(msg.sender == owner || administrators[msg.sender] > 0x0);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
    
    function addAdministrator(address _adminAddress) onlyOwner public {
        require(_adminAddress != address(0));
        require(administrators[_adminAddress] <= 0x0);
        administrators[_adminAddress] = 0x1;
        emit AddAdministrator(_adminAddress);
    }
    
    function removeAdministrator(address _adminAddress) onlyOwner public {
        require(_adminAddress != address(0));
        require(administrators[_adminAddress] > 0x0);
        administrators[_adminAddress] = 0x0;
        emit RemoveAdministrator(_adminAddress);
    }
    
    function setExchangeRate(uint256 _exchangeRate) public onlyAdministrator returns (bool success) {
        require(_exchangeRate > 0x0);
        uint256 oldExchangeRate = exchangeRate;
        exchangeRate = _exchangeRate;
        emit ExchangeRateChanged(oldExchangeRate, exchangeRate);
        return true;
    }
    
    function changeUnlockTime(uint _index, uint _unlockTime) public onlyAdministrator returns (bool success) {
        require(_index >= 0x0 && _index < developerReservedUnlockTimes.length && _unlockTime > 0x0);
        if(_index > 0x0) {
            uint beforeUnlockTime = developerReservedUnlockTimes[_index - 1];
            require(beforeUnlockTime == 0x0 || beforeUnlockTime < _unlockTime);
        }
        if(_index < developerReservedUnlockTimes.length - 1) {
            uint afterUnlockTime = developerReservedUnlockTimes[_index + 1];
            require(afterUnlockTime == 0x0 || _unlockTime < afterUnlockTime);
        }
        uint oldUnlockTime = developerReservedUnlockTimes[_index];
        developerReservedUnlockTimes[_index] = _unlockTime;
        emit UnlockTimeChanged(_index,oldUnlockTime,_unlockTime);
        return true;
    }
    
    function getDeveloperReservedLockInfo(uint _index) public onlyAdministrator returns (uint, uint256) {
        require(_index >= 0x0 && _index < developerReservedUnlockTimes.length && _index < developerReservedBalanceLimits.length);
        emit LockInfo(developerReservedAddress,_index,developerReservedUnlockTimes[_index],developerReservedBalanceLimits[_index]);
        return (developerReservedUnlockTimes[_index], developerReservedBalanceLimits[_index]);
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdministrator(address indexed adminAddress);
    event RemoveAdministrator(address indexed adminAddress);
}

contract APB is OwnableToken {
    
    function APB() public {
        balances[owner] = 5000000000 * 10 ** 6;
        balances[publicOfferingAddress] = 3000000000 * 10 ** 6;

        uint256 developerReservedBalance = 2000000000 * 10 ** 6;
        balances[developerReservedAddress] = developerReservedBalance;
        developerReservedUnlockTimes =
        [
        DateTimeLib.toTimestamp(2018, 6, 1),
        DateTimeLib.toTimestamp(2018, 9, 1),
        DateTimeLib.toTimestamp(2018, 12, 1),
        DateTimeLib.toTimestamp(2019, 3, 1),
        DateTimeLib.toTimestamp(2019, 6, 1),
        DateTimeLib.toTimestamp(2019, 9, 1),
        DateTimeLib.toTimestamp(2019, 12, 1),
        DateTimeLib.toTimestamp(2020, 3, 1)
        ];
        developerReservedBalanceLimits = 
        [
            developerReservedBalance,
            developerReservedBalance - (developerReservedBalance / 8) * 1,
            developerReservedBalance - (developerReservedBalance / 8) * 2,
            developerReservedBalance - (developerReservedBalance / 8) * 3,
            developerReservedBalance - (developerReservedBalance / 8) * 4,
            developerReservedBalance - (developerReservedBalance / 8) * 5,
            developerReservedBalance - (developerReservedBalance / 8) * 6,
            developerReservedBalance - (developerReservedBalance / 8) * 7
        ];
    }
    
    function() public payable {
        buy(msg.sender, msg.value);
    }
}