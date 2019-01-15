pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c4a0a5b2a184a5afaba9a6a5eaa7aba9">[email&#160;protected]</a>
// released under Apache 2.0 licence
// input  /Users/chae/dev/colorcoin/coin-ver2/color-erc20.sol
// flattened :  Thursday, 10-Jan-19 03:27:25 UTC
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
          return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
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


contract ERC20 {
 
    // Get the total token supply
    function totalSupply() public constant returns (uint256);

    // Get the account balance of another account with address _owner   
    function balanceOf(address who) public view returns (uint256);
    
    // Send _value amount of tokens to address _to
    function transfer(address to, uint256 value) public returns (bool);
    
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality   
    function approve(address spender, uint256 value) public returns (bool);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address owner, address spender) public view returns (uint256);
 
    // Triggered when tokens are transferred. 
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Triggered whenever approve(address _spender, uint256 _value) is called. 
    event Approval(address indexed owner,address indexed spender,uint256 value);
 
}

//
// Color Coin v2.0
// 
contract ColorCoin is ERC20 {

    // Time Lock and Vesting
    struct accountData {
      uint256 init_balance;
      uint256 balance;
      uint256 unlockTime1;
      uint256 unlockTime2;
      uint256 unlockTime3;
      uint256 unlockTime4;
      uint256 unlockTime5;

      uint256 unlockPercent1;
      uint256 unlockPercent2;
      uint256 unlockPercent3;
      uint256 unlockPercent4;
      uint256 unlockPercent5;
    }
    
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private allowed;
    
    mapping(address => accountData) private accounts;
    
    mapping(address => bool) private lockedAddresses;
    
    address private admin;
    
    address private founder;
    
    bool public isTransferable = false;
    
    string public name;
    
    string public symbol;
    
    uint256 public __totalSupply;
    
    uint8 public decimals;
    
    constructor(string _name, string _symbol, uint256 _totalSupply, uint8 _decimals, address _founder, address _admin) public {
        name = _name;
        symbol = _symbol;
        __totalSupply = _totalSupply;
        decimals = _decimals;
        admin = _admin;
        founder = _founder;
        accounts[founder].init_balance = __totalSupply;
        accounts[founder].balance = __totalSupply;
        emit Transfer(0x0, founder, __totalSupply);
    }
    
    // define onlyAdmin
    modifier onlyAdmin {
        require(admin == msg.sender);
        _;
    }
    
    // define onlyFounder
    modifier onlyFounder {
        require(founder == msg.sender);
        _;
    }
    
    // define transferable
    modifier transferable {
        require(isTransferable);
        _;
    }
    
    // define notLocked
    modifier notLocked {
        require(!lockedAddresses[msg.sender]);
        _;
    }
    
    // ERC20 spec.
    function totalSupply() public constant returns (uint256) {
        return __totalSupply;
    }

    // ERC20 spec.
    function balanceOf(address _owner) public view returns (uint256) {
        return accounts[_owner].balance;
    }
        
    // ERC20 spec.
    function transfer(address _to, uint256 _value) transferable notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= accounts[msg.sender].balance);

        if (!checkTime(msg.sender, _value)) return false;

        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // ERC20 spec.
    function transferFrom(address _from, address _to, uint256 _value) transferable notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= accounts[_from].balance);
        require(_value <= allowed[_from][msg.sender]);
        require(!lockedAddresses[_from]);

        if (!checkTime(_from, _value)) return false;

        accounts[_from].balance = accounts[_from].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // ERC20 spec.
    function approve(address _spender, uint256 _value) transferable notLocked public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // ERC20 spec.
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // Founder distributes initial balance
    function distribute(address _to, uint256 _value) onlyFounder public returns (bool) {
        require(_to != address(0));
        require(_value <= accounts[msg.sender].balance);
        
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        accounts[_to].init_balance = accounts[_to].init_balance.add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Change founder
    function changeFounder(address who) onlyFounder public {   
        founder = who;
    }

    // show founder address
    function getFounder() onlyFounder public view returns (address) {
        return founder;
    }

    // Change admin
    function changeAdmin(address who) onlyAdmin public {
        admin = who;
    }

    // show founder address
    function getAdmin() onlyAdmin public view returns (address) {
        return admin;
    }

    
    // Lock individual transfer flag
    function lock(address who) onlyAdmin public {
        
        lockedAddresses[who] = true;
    }

    // Unlock individual transfer flag
    function unlock(address who) onlyAdmin public {
        
        lockedAddresses[who] = false;
    }
    
    // Check individual transfer flag
    function isLocked(address who) public view returns(bool) {
        
        return lockedAddresses[who];
    }

    // Enable global transfer flag
    function enableTransfer() onlyAdmin public {
        
        isTransferable = true;
    }
    
    // Disable global transfer flag 
    function disableTransfer() onlyAdmin public {
        
        isTransferable = false;
    }

    // check unlock time and init balance for each account
    function checkTime(address who, uint256 _value) public view returns (bool) {
        uint256 total_percent;
        uint256 total_vol;

        total_vol = accounts[who].init_balance.sub(accounts[who].balance);
        total_vol = total_vol.add(_value);

        if (accounts[who].unlockTime1 > now) {
           return false;
        } else if (accounts[who].unlockTime2 > now) {
           total_percent = accounts[who].unlockPercent1;

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        } else if (accounts[who].unlockTime3 > now) {
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;

        } else if (accounts[who].unlockTime4 > now) {
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);
           total_percent = total_percent.add(accounts[who].unlockPercent3);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        } else if (accounts[who].unlockTime5 > now) {
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);
           total_percent = total_percent.add(accounts[who].unlockPercent3);
           total_percent = total_percent.add(accounts[who].unlockPercent4);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        } else { 
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);
           total_percent = total_percent.add(accounts[who].unlockPercent3);
           total_percent = total_percent.add(accounts[who].unlockPercent4);
           total_percent = total_percent.add(accounts[who].unlockPercent5);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        }
        
        return true; 
       
    }

    // Founder sets unlockTime1
    function setTime1(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime1 = value;
        return true;
    }

    function getTime1(address who) public view returns (uint256) {
        return accounts[who].unlockTime1;
    }

    // Founder sets unlockTime2
    function setTime2(address who, uint256 value) onlyFounder public returns (bool) {

        accounts[who].unlockTime2 = value;
        return true;
    }

    function getTime2(address who) public view returns (uint256) {
        return accounts[who].unlockTime2;
    }

    // Founder sets unlockTime3
    function setTime3(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime3 = value;
        return true;
    }

    function getTime3(address who) public view returns (uint256) {
        return accounts[who].unlockTime3;
    }

    // Founder sets unlockTime4
    function setTime4(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime4 = value;
        return true;
    }

    function getTime4(address who) public view returns (uint256) {
        return accounts[who].unlockTime4;
    }

    // Founder sets unlockTime5
    function setTime5(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime5 = value;
        return true;
    }

    function getTime5(address who) public view returns (uint256) {
        return accounts[who].unlockTime5;
    }

    // Founder sets unlockPercent1
    function setPercent1(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent1 = value;
        return true;
    }

    function getPercent1(address who) public view returns (uint256) {
        return accounts[who].unlockPercent1;
    }

    // Founder sets unlockPercent2
    function setPercent2(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent2 = value;
        return true;
    }

    function getPercent2(address who) public view returns (uint256) {
        return accounts[who].unlockPercent2;
    }

    // Founder sets unlockPercent3
    function setPercent3(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent3 = value;
        return true;
    }

    function getPercent3(address who) public view returns (uint256) {
        return accounts[who].unlockPercent3;
    }

    // Founder sets unlockPercent4
    function setPercent4(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent4 = value;
        return true;
    }

    function getPercent4(address who) public view returns (uint256) {
        return accounts[who].unlockPercent4;
    }

    // Founder sets unlockPercent5
    function setPercent5(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent5 = value;
        return true;
    }

    function getPercent5(address who) public view returns (uint256) {
        return accounts[who].unlockPercent5;
    }

    // get init_balance
    function getInitBalance(address _owner) public view returns (uint256) {
        return accounts[_owner].init_balance;
    }
}