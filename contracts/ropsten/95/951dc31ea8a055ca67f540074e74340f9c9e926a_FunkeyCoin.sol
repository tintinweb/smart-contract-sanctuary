pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// @Name SafeMath
// @Desc Math operations with safety checks that throw on error
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------
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
// ----------------------------------------------------------------------------
// @title ERC20Basic
// @dev Simpler version of ERC20 interface
// See https://github.com/ethereum/EIPs/issues/179
// ----------------------------------------------------------------------------
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
// ----------------------------------------------------------------------------
// @title ERC20 interface
// @dev See https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool); 
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
// ----------------------------------------------------------------------------
// @title Basic token
// @dev Basic version of StandardToken, with no allowances.
// ----------------------------------------------------------------------------
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
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
// ----------------------------------------------------------------------------
// @title Ownable
// @dev The Ownable contract has an owner address, and provides basic authorization control
// functions, this simplifies the implementation of &quot;user permissions&quot;.
// ----------------------------------------------------------------------------
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    
    emit OwnershipTransferred(owner, _newOwner);
    
    owner = _newOwner;
  }
}
// ----------------------------------------------------------------------------
// @title BlackList
// @dev Base contract which allows children to implement an emergency stop mechanism.
// ----------------------------------------------------------------------------
contract BlackList is Ownable {

    /**
    * Black List On Off
    */
    event Lock(address indexed LockedAddress);
    event Unlock(address indexed UnLockedAddress);

    mapping( address => bool ) public blackList;
    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
     modifier CheckBlackList {
        require(blackList[msg.sender] != true);
        _;
    }

    function SetLockAddress(address _lockAddress) external onlyOwner returns (bool) {
        require(_lockAddress != address(0));
        require(_lockAddress != owner);
        require(blackList[_lockAddress] != true);
        
        blackList[_lockAddress] = true;
        
        emit Lock(_lockAddress);

        return true;
    }

    function UnLockAddress(address _unlockAddress) external onlyOwner returns (bool) {
        require(_unlockAddress != address(0));
        require(_unlockAddress != owner);
        require(blackList[_unlockAddress] != false);
        
        blackList[_unlockAddress] = false;
        
        emit Unlock(_unlockAddress);

        return true;
    }
}
// ----------------------------------------------------------------------------
// @title Pausable
// @dev Base contract which allows children to implement an emergency stop mechanism.
// ----------------------------------------------------------------------------
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

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
}
// ----------------------------------------------------------------------------
// @title Standard ERC20 token
// @dev Implementation of the basic standard token.
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
// ----------------------------------------------------------------------------
// @title MultiTransfer Token
// @dev Only Admin
// ----------------------------------------------------------------------------
contract MultiTransferToken is StandardToken, Ownable {

  function MultiTransfer(address[] _to, uint256[] _amount) onlyOwner public returns (bool) {
    require(_to.length == _amount.length);

    uint256 ui;
    uint256 amountSum = 0;
    
    for (ui = 0; ui < _to.length; ui++) {
      require(_to[ui] != address(0));

      amountSum = amountSum.add(_amount[ui]);
    }

    require(amountSum <= balances[msg.sender]); // msg.sender == owner

    for (ui = 0; ui < _to.length; ui++) {
        balances[msg.sender] = balances[msg.sender].sub(_amount[ui]);
        balances[_to[ui]] = balances[_to[ui]].add(_amount[ui]);
        
        emit Transfer(msg.sender, _to[ui], _amount[ui]);
    }
    
    return true;
  }
}
// ----------------------------------------------------------------------------
// @title Burnable Token
// @dev Token that can be irreversibly burned (destroyed).
// ----------------------------------------------------------------------------
contract BurnableToken is StandardToken, Ownable {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) onlyOwner public {
    require(_value <= balances[owner]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[owner] = balances[owner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    
    emit Burn(owner, _value);
    emit Transfer(owner, address(0), _value);
  }
}
// ----------------------------------------------------------------------------
// @title Mintable token
// @dev Simple ERC20 Token example, with mintable token creation
// Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
// ----------------------------------------------------------------------------
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    
    emit MintFinished();
    
    return true;
  }
}
// ----------------------------------------------------------------------------
// @title Pausable token
// @dev StandardToken modified with pausable transfers.
// ----------------------------------------------------------------------------
contract PausableToken is StandardToken, Pausable, BlackList {

  function transfer(address _to, uint256 _value) public whenNotPaused CheckBlackList returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused CheckBlackList returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused CheckBlackList returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused CheckBlackList returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused CheckBlackList returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
// ----------------------------------------------------------------------------
// @Project FunkeyCoin (FKC)
// @Creator Funkey Admin Ryu
// @Source Code Verification ()
// ----------------------------------------------------------------------------
contract FunkeyCoin is PausableToken, MintableToken, BurnableToken, MultiTransferToken {
  string public name = &quot;FunkeyCoin&quot;;
  string public symbol = &quot;FKC&quot;;
  uint256 public decimals = 18;
}