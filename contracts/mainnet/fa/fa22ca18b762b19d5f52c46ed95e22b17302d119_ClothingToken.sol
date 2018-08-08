pragma solidity ^0.4.16;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
    
    address[] public owners;
    
    mapping(address => bool) bOwner;
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owners = [ 0x315C082246FFF04c9E790620867E6e0AD32f2FE3 ];
                    
        for (uint i=0; i< owners.length; i++){
            bOwner[owners[i]]=true;
        }
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        
        require(bOwner[msg.sender]);
        _;
    }
    
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */

}


contract ClothingToken is Ownable {
    

    uint256 public totalSupply;
    uint256 public totalSupplyMarket;
    uint256 public totalSupplyYear;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    string public constant name = "ClothingCoin";
    string public constant symbol = "CC";
    uint32 public constant decimals = 0;

    uint256 public constant hardcap = 300000000;
    uint256 public constant marketCap= 150000000;
    uint256 public yearCap=75000000 ;
    
    uint currentyear=2018;
    
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    
    struct DateTime {
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


    function parseTimestamp(uint timestamp) internal returns (DateTime dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        dt.year = ORIGIN_YEAR;

        // Year
        while (true) {
            if (isLeapYear(dt.year)) {
                    buf = LEAP_YEAR_IN_SECONDS;
            }
            else {
                    buf = YEAR_IN_SECONDS;
            }

            if (secondsAccountedFor + buf > timestamp) {
                    break;
            }
            dt.year += 1;
            secondsAccountedFor += buf;
        }

        // Month
        uint8[12] monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(dt.year)) {
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

        uint secondsInMonth;
        for (i = 0; i < monthDayCounts.length; i++) {
            secondsInMonth = DAY_IN_SECONDS * monthDayCounts[i];
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                    dt.month = i + 1;
                    break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 0; i < monthDayCounts[dt.month - 1]; i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                    dt.day = i + 1;
                    break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        for (i = 0; i < 24; i++) {
            if (HOUR_IN_SECONDS + secondsAccountedFor > timestamp) {
                    dt.hour = i;
                    break;
            }
            secondsAccountedFor += HOUR_IN_SECONDS;
        }

        // Minute
        for (i = 0; i < 60; i++) {
            if (MINUTE_IN_SECONDS + secondsAccountedFor > timestamp) {
                    dt.minute = i;
                    break;
            }
            secondsAccountedFor += MINUTE_IN_SECONDS;
        }

        if (timestamp - secondsAccountedFor > 60) {
            __throw();
        }
        
        // Second
        dt.second = uint8(timestamp - secondsAccountedFor);

        // Day of week.
        buf = timestamp / DAY_IN_SECONDS;
        dt.weekday = uint8((buf + 3) % 7);
    }
        
    function __throw() {
        uint[] arst;
        arst[1];
    }
    
    function getYear(uint timestamp) constant returns (uint16) {
        return parseTimestamp(timestamp).year;
    }
    
    modifier canYearMint() {
        if(getYear(now) != currentyear){
            currentyear=getYear(now);
            yearCap=yearCap/2;
            totalSupplyYear=0;
        }
        require(totalSupply <= marketCap);
        require(totalSupplyYear <= yearCap);
        _;
        
    }
    
    modifier canMarketMint(){
        require(totalSupplyMarket <= marketCap);
        _;
    }

    function mintForMarket (address _to, uint256 _value) public onlyOwner canMarketMint returns (bool){
        
        if (_value + totalSupplyMarket <= marketCap) {
        
            totalSupplyMarket = totalSupplyMarket + _value;
            
            assert(totalSupplyMarket >= _value);
             
            balances[msg.sender] = balances[msg.sender] + _value;
            assert(balances[msg.sender] >= _value);
            Mint(msg.sender, _value);
        
            _transfer(_to, _value);
            
        }
        return true;
    }

    function _transfer( address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(!frozenAccount[_to]);

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        Transfer(msg.sender, _to, _value);

    }
    
    function transfer(address _to, uint256 _value) public  returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        //assert(balances[_to] >= _value); no need to check, since mint has limited hardcap
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
    
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    
    function mintForYear(address _to, uint256 _value) public onlyOwner canYearMint returns (bool) {
        require(_to != address(0));
        
        if (_value + totalSupplyYear <= yearCap) {
            
            totalSupply = totalSupply + _value;
        
            totalSupplyYear = totalSupplyYear + _value;
            
            assert(totalSupplyYear >= _value);
             
            balances[msg.sender] = balances[msg.sender] + _value;
            assert(balances[msg.sender] >= _value);
            Mint(msg.sender, _value);
        
            _transfer(_to, _value);
            
        }
        return true;
    }



    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */

    function burn(uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        balances[msg.sender] = balances[msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);   
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(_from, _value);
        return true;
    }
    
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);

    event Burn(address indexed burner, uint256 value);

}