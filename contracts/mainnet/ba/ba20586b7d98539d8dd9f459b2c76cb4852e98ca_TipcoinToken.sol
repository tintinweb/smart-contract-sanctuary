pragma solidity ^0.4.24;

// File: contracts/zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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

/**
 *  @title ERC223 interface
 **/
contract ERC223Interface {
    function transfer(address to, uint value, bytes data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title ERC223 token handler
 **/
contract ERC223Receiver {
    function tokenFallback(address _fromm, uint256 _value, bytes _data) public pure;
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  address public newOwner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
  
  event OwnershipTransferred(address oldOwner, address newOwner);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

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
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev Modified by function &#39;finalUnpause&#39; 
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event FinalUnpause();
  
  bool public paused = false;
  // finalUnpaused always false, not sure its purpose
  bool public finalUnpaused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    require (!finalUnpaused);
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  /**
  * func unpause and finalUnpause are doing same stuff except from event.
  * didn&#39;t see any effect.
  */  
  function finalUnpause() onlyOwner public {
    paused = false;
    emit FinalUnpause();
  }
}

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
    // not required, sub method will take care of this.
    // require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Tipcoin contract
 **/
contract TipcoinToken is StandardToken, Pausable, BurnableToken, ERC223Interface {
    
  using SafeMath for uint256;
  
  string public constant name = "Tipcoin";
  
  string public constant symbol = "TIPC";
  
  uint8 public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 1000000000;
  
  constructor() public {
    // owner is already initiated in ownable constructor.
    // owner = msg.sender;   
    totalSupply_ = INITIAL_SUPPLY * 10 ** 18;
    balances[owner] = totalSupply_;
    emit Transfer(address(0), owner, INITIAL_SUPPLY);
  }    
  
  /**
  * @dev transfer token for a specified address with call custom function external data
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @param _data The data to call tokenFallback function.
  * @param _fallback The function name and params to call external function
  */
  function transfer(address _to, uint256 _value, bytes _data, string _fallback) public whenNotPaused returns (bool) {
    require( _to != address(0));
    
    if (isContract(_to)) {            
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_fallback))), msg.sender, _value, _data));
      
      if (_data.length == 0) {
        emit Transfer(msg.sender, _to, _value);
      } else {
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
      }
      return true;
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }

  /**
  * @dev transfer token for a specified address with external data
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @param _data The data to call tokenFallback function 
  */
  function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
    if (isContract(_to)) {
      return transferToContract(msg.sender, _to, _value, _data);
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
      bytes memory empty;
      if (isContract(_to)) {
          return transferToContract(msg.sender, _to, _value, empty);
      } else {
          return transferToAddress(msg.sender, _to, _value, empty);
      }
  }

  /**
  * @dev Transfer tokens from one address to another
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amount of tokens to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){      
    require( _to != address(0));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    bytes memory empty;

    if (isContract(_to)) {
        return transferToContract(_from, _to, _value, empty);
      } else {
        return transferToAddress(_from, _to, _value, empty);
      }
  }

  //@dev internal part
  function isContract(address _addr) internal view returns (bool) {
    uint length;
    
    assembly {
      length := extcodesize(_addr)
    }
    
    return (length >0);
  }
  
  function transferToAddress(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (_data.length == 0) {
      emit Transfer(_from, _to, _value);
    } else {
      emit Transfer(_from, _to, _value);
      emit Transfer(_from, _to, _value, _data);
    }    
    return true;
  }
  
  function transferToContract(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    ERC223Receiver receiver = ERC223Receiver(_to);
    receiver.tokenFallback(_from, _value, _data);
    if (_data.length == 0) {
      emit Transfer(_from, _to, _value);
    } else {
      emit Transfer(_from, _to, _value);
      emit Transfer(_from, _to, _value, _data);
    }    
    return true;   
  }
}