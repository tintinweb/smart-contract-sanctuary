pragma solidity ^0.4.23;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min64(uint64 a, uint64 b) internal pure returns (uint64) 
    {
        return a < b ? a : b;
    }
    
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
 }
 
 /**
 * Date and Time utilities for ethereum contracts
 */
 contract DateTime {

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

        function getYear(uint timestamp) internal pure returns (uint16) {
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

contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
} 
 

contract EdgeSmartToken is ERC20, SafeMath, DateTime {

    uint256  public constant _decimals = 18;
    uint256 public constant _totalSupply = (100000000 * 10**_decimals);
    
    string public constant symbol = &#39;EDUX&#39;;
    string public constant name = &#39;Edgecoin Smart Token&#39;;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) approved;
    address EdgeSmartTokenOwner;

    modifier onlyOwner() {
        require(msg.sender == EdgeSmartTokenOwner);
        _;
    }    
    
    constructor() public {
        EdgeSmartTokenOwner = msg.sender;
        balances[EdgeSmartTokenOwner] = _totalSupply;
    }
   
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != EdgeSmartTokenOwner);      
        EdgeSmartTokenOwner = newOwner;
    }    
    

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer self tokens to given address
     * @param _to destination address
     * @param _value amount of token values to send
     * @notice `_value` tokens will be sended to `_to`
     * @return `true` when transfer done
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(
            balances[msg.sender] >= _value && _value > 0
        );
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer with approvement mechainsm
     * @param _from source address, `_value` tokens shold be approved for `sender`
     * @param _to destination address
     * @param _value amount of token values to send
     * @notice from `_from` will be sended `_value` tokens to `_to`
     * @return `true` when transfer is done
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(
            approved[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0
        );
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        approved[_from][msg.sender] = safeSub(approved[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Give to target address ability for self token manipulation without sending
     * @param _spender target address (future requester)
     * @param _value amount of token values for approving
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        approved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Reset count of tokens approved for given address
     * @param _spender target address (future requester)
     */
    function unapprove(address _spender) public { 
        approved[msg.sender][_spender] = 0; 
    }

    /**
     * @dev Take allowed tokens
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return approved[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Edgecoin is SafeMath, DateTime, EdgeSmartToken {
    
    address owner; 
    uint private totalCollected = 0;
    uint private preSaleCollected = 0;
    uint private ICOCollected = 0;
    
    uint256 public totalTokensCap = (50000000 * 10**_decimals); //50% of total supply
    uint public preSaleTokensLimit = (10000000 * 10**_decimals); //10% of total supply
    
    uint256 public icoSaleSoftCap = (5000000 * 10**_decimals); //5mio EDUX or 1000 ETH
    uint public icoSaleHardCap = (25000000 * 10**_decimals);//25mio EDUX or 5000 ETH
   
    uint256 private preSaleTokenPrice = (10000 * 10**_decimals); //10k
    uint256 private ICOTokenPrice = (5000 * 10**_decimals); //5k
   
    bool ICOActive = true;
   
    uint pre_ICO_end_date = toTimestamp(2017, 12, 6, 20, 0);
   
    uint ICO_end_date = toTimestamp(2018, 1, 1, 20, 0); 
    
    //since ICO date and period are not defined precisely, lets put hardcoded end date 
    uint ICO_hardcoded_expiry_date = toTimestamp(2019, 1, 1, 20, 0); 
   
    uint256 private tokensToBuy;
    
    //multisig withdrawal part
    mapping (address => bool) private isOwner; // immutable state
    mapping (address => bool) private isConfirmed; // immutable state
    mapping (uint => address) private ownersArr; // immutable state
    uint public nonce;                // (only) mutable state
    uint public threshold = 3;            // immutable state
    uint public pendingAmount;
    address public pendingAddress;
    uint public confirmedTimesByOwners = 0;
    //multisig ended

    constructor() public {
       owner = msg.sender;
       isOwner[0x512B431fc06855C8418495ffcc570D246B654f6E] = true; //am
       isOwner[0xb43d2a6fEFEF1260F772EDa4eF4341044C494b48] = true; //kj
       isOwner[0x9016f6fb21F454F294A78AdeFbD700f4B6795C91] = true; //aw
       
       ownersArr[0] = 0x512B431fc06855C8418495ffcc570D246B654f6E;
       ownersArr[2] = 0xb43d2a6fEFEF1260F772EDa4eF4341044C494b48;
       ownersArr[3] = 0x9016f6fb21F454F294A78AdeFbD700f4B6795C91;
       
       //migrated from first version of ICO contract, addr 0x25992f65334b5d23096b912af089ac454c3aabb6
       totalCollected = 366536727590000000000000;
       preSaleCollected = 265029930140000000000000;
       ICOCollected = 101506797450000000000000;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOwners() {
        require(isOwner[msg.sender] == true);
        _;
    }
    
    function initiateWithdrawal(address destination, uint value) public onlyOwners {
        confirmedTimesByOwners = 0;
        for (uint j = 0; j < threshold; j++) {
            isConfirmed[ownersArr[j]] = false;
        }  
            
        pendingAmount = value;
        pendingAddress = destination;

        isConfirmed[msg.sender] = true;
        confirmedTimesByOwners++;
    }

    function confirmAndExecuteWithdrawal() public onlyOwners payable {
        isConfirmed[msg.sender] = true;
        for (uint i = 0; i < threshold; i++) {
            if (isConfirmed[ownersArr[i]]) {
                confirmedTimesByOwners++;
            }
        }
      
        if (confirmedTimesByOwners >= (threshold-1) ) { // 2/3 or 3/3
            nonce = nonce + 1;
            pendingAddress.transfer(pendingAmount);

            //reset withdrawal data
            pendingAmount = 0;
            pendingAddress = 0x0;
            confirmedTimesByOwners = 0;
        
            for (uint j = 0; j < threshold; j++) {
                isConfirmed[ownersArr[j]] = false;
            }  
        }
    }
    
    function getTotalTokensSold() public constant returns (uint) {
        return totalCollected;
    }
    
    function getPreSaleTokensSold() public constant returns (uint) {
        return preSaleCollected;
    } 
    
    function getIcoTokensSold() public constant returns (uint) {
        return ICOCollected;
    }    

    function setICOStatus(bool status) onlyOwner public {
        ICOActive = status;
    }

    function () public payable {
        createTokens(msg.sender);
    }
    
    function createTokens(address recipient) public payable {
        
        if (ICOActive && (now < ICO_hardcoded_expiry_date)) {
            require(msg.value >= 0.1 * (1 ether)); //minimum 0.1 ETH
            tokensToBuy = safeDiv(safeMul(msg.value * 1 ether, ICOTokenPrice), 1000000000000000000 ether);
            require (totalCollected + tokensToBuy <= totalTokensCap); //max sell 50mio, 40mio + rest from preSale
            ICOCollected = safeAdd(ICOCollected, tokensToBuy);
            totalCollected = safeAdd(totalCollected, tokensToBuy);
            
            balances[recipient] = safeAdd(balances[recipient], tokensToBuy);
            balances[owner] = safeSub(balances[owner], tokensToBuy);
            emit Transfer(owner, recipient, tokensToBuy);
        }
        else  {
            revert("Edgecoin ICO has ended.");
        }
    }
}