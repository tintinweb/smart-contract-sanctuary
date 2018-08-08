pragma solidity ^0.4.21;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

library DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct MyDateTime {
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

    function isLeapYear(uint16 year) constant returns (bool) {
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

    function leapYearsBefore(uint year) constant returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) constant returns (uint8) {
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

    function parseTimestamp(uint timestamp) internal returns (MyDateTime dt) {
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
        // Hour
        dt.hour = 0;
        //getHour(timestamp);
        // Minute
        dt.minute = 0;
        //getMinute(timestamp);
        // Second
        dt.second = 0;
        //getSecond(timestamp);
        // Day of week.
        dt.weekday = 0;
        //getWeekday(timestamp);
    }

    function getYear(uint timestamp) constant returns (uint16) {
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

    function getMonth(uint timestamp) constant returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) constant returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) constant returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) constant returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) constant returns (uint8) {
        return uint8(timestamp % 60);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp) {
        uint16 i;
        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            }
            else {
                timestamp += YEAR_IN_SECONDS;
            }
        }
        // Month
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
        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);
        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);
        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);
        // Second
        timestamp += second;
        return timestamp;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint8 public decimals = 18;
    uint public allSupply = 12600000; // 21000000 * 0.6
    uint public freezeSupply = 8400000 * 10 ** uint256(decimals);   // 21000000 * 0.4
    uint256 totalSupply_ = freezeSupply; 

    constructor() public {
        balances[msg.sender] = 0;
        balances[0x0] = freezeSupply;
    }


    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

contract FBToken is ERC20, BasicToken {

    using DateTime for uint256;

    string public name = "FABI";
    string public symbol = "FB";

    address owner;


    uint public lastRelease = 15 * 10000000;   
    uint public lastMonth = 1;                
    uint public divBase = 100 * 10000000;
    uint256 public award = 0;    

    event ReleaseSupply(address indexed receiver, uint256 value, uint256 releaseTime);

    uint256 public createTime;

    struct ReleaseRecord {
        uint256 amount; // release amount
        uint256 releasedTime; // release time
    }

    mapping(uint => ReleaseRecord) public releasedRecords;
    uint public releasedRecordsCount = 0;

    constructor() public {
        owner = msg.sender;
        createTime = now;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }



    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }


    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function releaseToday() public onlyOwner returns (uint256 _actualRelease) {
        return releaseSupply(now);
    }
    
    function releaseSupply(uint256 timestamp) public onlyOwner returns (uint256 _actualRelease) {
        require(timestamp >= createTime && timestamp <= now);
        require(!judgeReleaseRecordExist(timestamp));

        updateAward(timestamp);

        balances[owner] = balances[owner].add(award);
        totalSupply_ = totalSupply_.add(award);
        releasedRecords[releasedRecordsCount] = ReleaseRecord(award, timestamp);
        releasedRecordsCount++;
        emit ReleaseSupply(owner, award, timestamp);
        return award;
    }

    function judgeReleaseRecordExist(uint256 timestamp) internal returns (bool _exist) {
        bool exist = false;
        if (releasedRecordsCount > 0) {
            for (uint index = 0; index < releasedRecordsCount; index++) {
                if ((releasedRecords[index].releasedTime.parseTimestamp().year == timestamp.parseTimestamp().year)
                && (releasedRecords[index].releasedTime.parseTimestamp().month == timestamp.parseTimestamp().month)
                    && (releasedRecords[index].releasedTime.parseTimestamp().day == timestamp.parseTimestamp().day)) {
                    exist = true;
                }
            }
        }
        return exist;
    }

    function updateAward(uint256 timestamp) internal {
        uint passMonth = now.sub(createTime) / 30 days + 1;
        if (passMonth == lastMonth + 1) {
            lastRelease = lastRelease - lastRelease.mul(10).div(100);
            lastMonth = passMonth;
        }
        award = lastRelease.mul(10 ** uint256(decimals)).mul(allSupply).div(30).div(divBase);

    }

}