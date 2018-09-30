pragma solidity ^0.4.24;

//import &#39;./DateTime.sol&#39;;
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

contract ERC20Token {
    function transferFrom(address from, address to, uint _value) public returns (bool);
    function freeze(address spender,uint256 value) public returns (bool success);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract RevStaking {
    struct stakingDetail{
        
        uint256 duration;
        address ownerAddress;
        address stakingAddress;
        uint256 amount;
        uint256 timeStart;
        bool isActive;
        bool completed;    
    }
    
    mapping (address => stakingDetail) stakingDetails;
    mapping (address => uint256) public freezed;
    mapping (address => uint256) balances;
    address [] public stakedAddress;
    uint256 stakingCount;
    
    
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    
    
    function stack(address _stakingAddress, uint256 _amount, uint256 _duration) public{
        require(_amount>10000);
        if(!IsValidAddress(_stakingAddress)) { throw; }
        ERC20Token _token = ERC20Token(0x53981B4004FE67fB3D0Da666D635fDdadeeD5cf8);
        _token.transferFrom(msg.sender, _stakingAddress, _amount);
        //_token.freeze(_stakingAddress,_amount);
        
        var stakingDetail = stakingDetails[_stakingAddress];
        stakingDetail.duration = _duration;
        stakingDetail.ownerAddress = msg.sender;
        stakingDetail.stakingAddress = _stakingAddress;
        stakingDetail.amount = _amount;
        stakingDetail.timeStart = now;
        stakingDetail.isActive = false;
        stakingDetail.completed =false;
        
        stakedAddress.push(_stakingAddress)-1;
        stakingCount++;
    }
    
    function getStakedAddresses() view public returns (address[]){
        return stakedAddress;
    }
    
    function getStakedAddress(address _stakingAddress) view public returns (uint256, address, uint256, uint256){
        return (stakingDetails[_stakingAddress].duration,stakingDetails[_stakingAddress].stakingAddress,stakingDetails[_stakingAddress].amount,stakingDetails[_stakingAddress].timeStart);
    }
    
    function freezeAmount() {
        
    }
    
    function freezeStaking(address _stakingAddress) returns (bool){
        //for(uint256 i =0; i< stakedAddress.length; i++){
            var stakingDetail = stakingDetails[_stakingAddress];
            if((stakingDetail.timeStart + 14 * 1 days)> now){
                stakingDetail.isActive = true;
            }
        //}
    }
    function revokeStaking(address _stakingAddress) returns(bool){
        var stakingDetail = stakingDetails[_stakingAddress];
        if(stakingDetail.ownerAddress != msg.sender)
            return false;
        else
        {
            ERC20Token _token = ERC20Token(0x53981B4004FE67fB3D0Da666D635fDdadeeD5cf8);
            _token.transfer(_stakingAddress, getStakingReward(stakingDetail.duration));
            stakingDetail.completed = true;
            return true;
        }
    }
    function getStakingReward(uint256 _duration) returns (uint256){
        //stakingBonusRewardPercentage
        DateTime dateTime = new DateTime();
        var daysStaked = dateTime.getDay(now - _duration);
        return getReward(daysStaked);
    }
    function  getReward(uint256 daysStaked) returns (uint256){
        //stakingBonusRewardPercentagePerDay
        var percentage = 2;
        if (daysStaked > 1) {
            return 2 * percentage;
        }else{
              return 0;
        }
    }
    function IsValidAddress(address _stakingAddress) returns (bool){
        var stakingDetail = stakingDetails[_stakingAddress];
        if(!stakingDetail.isActive && stakingDetail.completed)
            return true;
        else
            return false;
    }
    function stakingBonus(uint256 ETH_profit, uint256 userToken, uint256 totalToken) {
      
           uint256 bonusETH = ETH_profit * (userToken/totalToken);
    }
}

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
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

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
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
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
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

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
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

contract DateTimeAPI {
        /*
         *  Abstract contract for interfacing with the DateTime contract.
         *
         */
        function isLeapYear(uint16 year) constant returns (bool);
        function getYear(uint timestamp) constant returns (uint16);
        function getMonth(uint timestamp) constant returns (uint8);
        function getDay(uint timestamp) constant returns (uint8);
        function getHour(uint timestamp) constant returns (uint8);
        function getMinute(uint timestamp) constant returns (uint8);
        function getSecond(uint timestamp) constant returns (uint8);
        function getWeekday(uint timestamp) constant returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp);
}