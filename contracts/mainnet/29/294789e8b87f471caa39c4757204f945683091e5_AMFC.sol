pragma solidity ^0.4.21;

// File: contracts/ownership/Ownable.sol

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
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

 

}

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
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

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

}
 
contract AMFC is StandardToken, BurnableToken, Ownable {
    // Constants
    string  public constant name = "Anything Macgic Fans";
    string  public constant symbol = "AMFC";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 500000000 * (10 ** uint256(decimals));

    address constant LOCK_ADDR = 0xF63Fb7657B11B408eEdD263fE0753E1665E7400a;
    uint256 constant LOCK_SUPPLY    = 300000000 * (10 ** uint256(decimals));  
    uint256 constant UNLOCK_2Y    =   200000000 * (10 ** uint256(decimals)); 
    uint256 constant UNLOCK_1Y    =   100000000 * (10 ** uint256(decimals)); 

    uint256 constant OWNER_SUPPLY      = INITIAL_SUPPLY - LOCK_SUPPLY;

    mapping(address => uint256)  balanceLocked;   //地址 - 锁定代币数量
    mapping(address => uint256)  lockAtTime;      //地址 - 锁定起始时间点
    
  
    uint256 public buyPrice = 585;
    bool public crowdsaleClosed;
    bool public transferEnabled = true;


    constructor() public {
      totalSupply_ = INITIAL_SUPPLY;

      balances[msg.sender] = OWNER_SUPPLY;
      emit Transfer(0x0, msg.sender, OWNER_SUPPLY);

      balances[LOCK_ADDR] = LOCK_SUPPLY;
      emit Transfer(0x0, LOCK_ADDR, LOCK_SUPPLY);

      _lock(LOCK_ADDR);
    }

    function _lock(address _owner) internal {
        balanceLocked[_owner] =  balances[_owner];  
        lockAtTime[_owner] = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {     
        require (balances[_from] >= _value);               // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]); // Check for overflows
   
        balances[_from] = balances[_from].sub(_value);                         // Subtract from the sender
        balances[_to] = balances[_to].add(_value);                            // Add the same to the recipient

        emit Transfer(_from, _to, _value);
    }

    function setPrices(bool closebuy, uint256 newBuyPrice) onlyOwner public {
        crowdsaleClosed = closebuy;
        buyPrice = newBuyPrice;
    }

    function () external payable {
        require(!crowdsaleClosed);
        uint amount = msg.value ;               // calculates the amount
 
        _transfer(owner, msg.sender, amount.mul(buyPrice)); 
        owner.transfer(amount);
    }

    //取回eth, 参数设为0 则全部取回, 否则取回指定数量的eth
    function safeWithdrawal(uint _value ) onlyOwner public {
       if (_value == 0) 
           owner.transfer(address(this).balance);
       else
           owner.transfer(_value);
    }

 
    function enableTransfer(bool _enable) onlyOwner external {
        transferEnabled = _enable;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        require(checkLocked(_from, _value));

        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        require(checkLocked(msg.sender, _value));
        
        return super.transfer(_to, _value);
    }    
  
    // 传入要锁定的地址, 锁定数量为地址当前拥有的数量
    //流程:
    //ICO 完成后,  调用此函数设置锁定地址, 然后调用 enableTransfer 函数允许转token
    function lockAddress( address[] _addr ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          _lock(_addr[i]);
        }
    }
    
    // 解锁地址
    function unlockAddress( address[] _addr ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          balanceLocked[_addr[i]] =  0;  
        }
    }
 

   function checkLocked(address _addr, uint256 _value) internal view returns (bool) {
      if (balanceLocked[_addr] > 0) {   //address is locked
         if (now > lockAtTime[_addr] + 3 years) {  
             return true;
         } else if (now > lockAtTime[_addr] + 2 years)   {
             return (balances[_addr] - _value >= UNLOCK_1Y);
         } else if (now > lockAtTime[_addr] + 1 years)   {
             return (balances[_addr] - _value >= UNLOCK_2Y);    
         }  else {
             return false;   
         }  
      }
     
      return true;
   } 
        
}