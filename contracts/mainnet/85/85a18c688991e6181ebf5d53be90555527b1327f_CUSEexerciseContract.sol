pragma solidity ^0.4.24;

contract Owned {
    
    /// &#39;owner&#39; is the only address that can call a function with 
    /// this modifier
    address public owner;
    address internal newOwner;
    
    ///@notice The constructor assigns the message sender to be &#39;owner&#39;
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event updateOwner(address _oldOwner, address _newOwner);
    
    ///change the owner
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(owner != _newOwner);
        newOwner = _newOwner;
        return true;
    }
    
    /// accept the ownership
    function acceptNewOwner() public returns(bool) {
        require(msg.sender == newOwner);
        emit updateOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }
}

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

}

contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;
    
    /// user tokens
    mapping (address => uint256) public balances;
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
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
}

contract CUSEexerciseContract is Owned,SafeMath,DateTime {
    
    /// @dev name of CUSEexec contract
    string public name = "CUSE_Exercise_Option";
    /// @dev decimal of CUSE
    uint256 decimals = 18;

    /// @dev token holder
    address public CUSEaddr          = 0x6081dEd2d0a57fC4b63765B182D8773E72327fE2;
    address constant public USEaddr  = 0xd9485499499d66B175Cf5ED54c0a19f1a6Bcb61A;
    address public tokenHolder       = 0x89Ead717c9DC15a222926221897c68F9486E7229;
    address public officialAddress   = 0x41eFD65d4f101ff729D93e7a2b7F9e22f9033332;
    
    /// @dev exercise price of Each Month
    
    mapping (uint => mapping(uint => uint)) public eachExercisePrice;
    
    constructor (uint[] _year, uint[] _month, uint[] _exercisePrice) public {
        require (_year.length == _month.length);
        require (_month.length == _exercisePrice.length);
        for (uint i=0; i<_month.length; i++) {
            eachExercisePrice[_year[i]][_month[i]] = _exercisePrice[i];
        }
    }
    
    function () public payable {
        address _user = msg.sender;
        uint    _value = msg.value;
        require(exerciseCUSE(_user, _value) == true);
    }
    
    /// @dev internal function: exercise option of CUSE
    function exerciseCUSE(address _user, uint _ether) internal returns (bool) {
        /// @dev get CUSE price
        uint _exercisePrice = getPrice();
        
        /// @dev get CUSE of msg.sender
        
        uint _CUSE = ERC20Token(CUSEaddr).balanceOf(_user);
        // ETH user send
        (uint _use, uint _refoundETH) = calcUSE(_CUSE, _ether, _exercisePrice);
        
        // do exercise
        require (ERC20Token(CUSEaddr).transferFrom(_user, officialAddress, _use) == true);
        require (ERC20Token(USEaddr).transferFrom(tokenHolder, _user, _use) == true);
        
        // refound ETH
        needRefoundETH(_user, _refoundETH);
        officialAddress.transfer(safeSub(_ether, _refoundETH));
        return true;
    }
    
    /// @dev get exercise price
    function getPrice() internal view returns(uint) {
        uint _year = getYear(now);
        uint _month = getMonth(now);
        return eachExercisePrice[_year][_month];
    }
    
    /// @dev Calculate USE value
    function calcUSE(uint _cuse, uint _ether, uint _exercisePrice) internal pure returns (uint _use, uint _refoundETH) {
        uint _amount = _ether / _exercisePrice;
        require (_amount > 0);
        require (safeMul(_amount, _exercisePrice) <= _ether);
        
        // Check Whether msg.sender Have Enough CUSE
        if (safeMul(_amount, 10**18) <= _cuse) {
            _use = safeMul(_amount, 10**18);
            _refoundETH = 0;
        } else {
            _use = _cuse;
            _refoundETH = safeMul(safeSub(_amount, _use/(10**18)), _exercisePrice);
        }
    }
    
    function needRefoundETH(address _user, uint _refoundETH) internal {
        if (_refoundETH > 0) {
            _user.transfer(_refoundETH);
        }
    }
    
    /// @dev Change Exercise Price
    function changeExerciseprice(uint[] _year, uint[] _month, uint[] _exercisePrice) public onlyOwner {
        require (_year.length == _month.length);
        require (_month.length == _exercisePrice.length);
        for (uint i=0; i<_month.length; i++) {
            eachExercisePrice[_year[i]][_month[i]] = _exercisePrice[i];
        }
    }
    
    function changeCUSEaddress(address _cuseAddr) public onlyOwner {
        CUSEaddr = _cuseAddr;
    }
    
    /// @dev Change token holder
    function changeTokenHolder(address _tokenHolder) public onlyOwner {
        tokenHolder = _tokenHolder;
    }
    
    /// @dev Change Official Address If Necessary
    function changeOfficialAddressIfNecessary(address _officialAddress) public onlyOwner {
        officialAddress = _officialAddress;
    }

}