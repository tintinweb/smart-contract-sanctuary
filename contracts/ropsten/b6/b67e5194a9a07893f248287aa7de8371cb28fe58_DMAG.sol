/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity >=0.4.21 <0.6.0;


library SafeMath
{
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
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

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
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
}



contract DMAG is DateTime{
    using SafeMath for uint;

    uint256 constant TIME_LAG = 28800;

    struct MarketDetails {
        bool bull;
        uint256 openingPrice;
        uint256 closingPrice; 
        uint256 support;
        uint256 resistance;
        uint256 amplitude;
        uint256 maketime;
        uint256 position;           
    }

    
    address public owner;
    bool public stopFlag;
    mapping(uint256 => mapping(address => MarketDetails)) public marketPredict;
    mapping(uint256 => address[]) public participants;
    mapping(uint256 => address[]) public donator;

    event MakePredict(uint256 _time, address _player);
    event ChangeOwner(address _rawOwner, address _newOwer);
    event Donate(address _donator, uint256 _value);
    event Withdraw(uint256 _value);
    event SetStopFlag(bool _flag);

    constructor ()public {
        owner = msg.sender;
    }



    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function() external payable{

    }

    function parseTime(uint256 timestamp)private pure returns(uint256 _date){
        uint256 yea = getYear(timestamp);
        uint256 month = getMonth(timestamp);
        uint256 date = getDay(timestamp);

        _date = yea.mul(10000).add(month.mul(100)).add(date);
    }

    function makePredict(bool _bull, uint256 _opening, uint256 _closing, uint256 _support, uint256 _resistance, uint256 _amlitude)public{
        require(stopFlag == false);
        uint256 period = parseTime(block.timestamp.add(TIME_LAG));
        require(marketPredict[period][msg.sender].openingPrice == 0);
        //require(getHour(block.timestamp < 8));
        uint256 pos = participants[period].length.add(1);
        uint256 hour = getHour(block.timestamp.add(TIME_LAG));
        uint256 min = getMinute(block.timestamp.add(TIME_LAG));
        uint256 sec = getSecond(block.timestamp.add(TIME_LAG));
        uint256 _maketime = sec.add(min.mul(100)).add(hour.mul(10000));

        MarketDetails memory myDetails = MarketDetails({
            bull: _bull,
            openingPrice: _opening,
            closingPrice: _closing,
            support: _support,
            resistance: _resistance,
            amplitude: _amlitude,
            maketime: _maketime,
            position: pos
        });

        marketPredict[period][msg.sender] = myDetails;
        participants[period].push(msg.sender);

        emit MakePredict(block.timestamp, msg.sender);
    }

    function checkParticipants(uint256 _period)public view returns(address[] memory _player){
        return participants[_period];
    }

    function numbersOf(uint256 _period)public view returns(uint256 _total){
        return participants[_period].length;
    }

    function setStopFlage(bool _flag)public onlyOwner{
        stopFlag = _flag;

        emit SetStopFlag(_flag);
    }

    function changeOwner(address _newOwner)public onlyOwner{
        owner = _newOwner;
        emit ChangeOwner(msg.sender, _newOwner);
    }

    function donate()public payable {
        uint256 period = parseTime(block.timestamp.add(TIME_LAG));
        donator[period].push(msg.sender);
        emit Donate(msg.sender, msg.value);
    } 

    function withdraw()public onlyOwner{
        uint256  value = address(this).balance;

        msg.sender.transfer(value);

        emit Withdraw(value);
    }
}