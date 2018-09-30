pragma solidity ^0.4.18;

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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @title Lockable
 * @dev Base contract which allows children to lock and unlock the ability for addresses to make transfers
 */
contract Lockable is Ownable {

  mapping (address => bool) public lockStates;   // map between addresses and their lock state.

  event Lock(address indexed accountAddress);
  event Unlock(address indexed accountAddress);


  /**
   * @dev Modifier to make a function callable only when the account is in unlocked state
   */
  modifier whenNotLocked(address _address) {
    require(!lockStates[_address]);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the acount is in locked state
   */
  modifier whenLocked(address _address) {
    require(lockStates[_address]);
    _;
  }

  /**
   * @dev called by the owner to lock the ability for an address to make transfers
   */
  function lock(address _address) onlyOwner public {
      lockWorker(_address);
  }

  function lockMultiple(address[] _addresses) onlyOwner public {
      for (uint i=0; i < _addresses.length; i++) {
          lock(_addresses[i]);
      }
  }

  function lockWorker(address _address) internal {
      require(_address != owner);
      require(this != _address);

      lockStates[_address] = true;
      Lock(_address);
  }

  /**
   * @dev called by the owner to unlock an address in order for it to be able to make transfers
   */
  function unlock(address _address) onlyOwner public {
      unlockWorker(_address);
  }

  function unlockMultiple(address[] _addresses) onlyOwner public {
      for (uint i=0; i < _addresses.length; i++) {
          unlock(_addresses[i]);
      }
  }

  function unlockWorker(address _address) internal {
      lockStates[_address] = false;
      Unlock(_address);
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Ownable {
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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
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
  function approve(address _spender, uint256 _value) public returns  (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/*
  ERC20 TAB Token smart contract implementation
*/
contract TabToken is PausableToken, Lockable {

  event Burn(address indexed burner, uint256 value);
  event EtherReceived(address indexed sender, uint256 weiAmount);
  event EtherSent(address indexed receiver, uint256 weiAmount);
  event EtherAddressChanged(address indexed previousAddress, address newAddress);

  
  string public constant name = "TAB";
  string public constant symbol = "TAB";
  uint8 public constant decimals = 18;


  address internal _etherAddress = 0x90CD914C827a12703D485E9E5fA69977E3ea866B;

  //This is already exposed from BasicToken.sol as part of the standard
  uint256 internal constant INITIAL_SUPPLY = 22000000000000000000000000000;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function TabToken() public {
    totalSupply_ = INITIAL_SUPPLY;

    //Give all initial supply to the contract.
    balances[this] = INITIAL_SUPPLY;
    Transfer(0x0, this, INITIAL_SUPPLY);

    //From now onwards, we MUST always use transfer functions
  }

  //Fallback function - just revert any payments
  function () payable public {
    revert();
  }

  //Function which allows us to fund the contract with ether
  function fund() payable public onlyOwner {
    require(msg.sender != 0x0);
    require(msg.value > 0);

    EtherReceived(msg.sender, msg.value);
  }

  //Function which allows sending ether from contract to the hard wallet address
  function sendEther() payable public onlyOwner {
    require(msg.value > 0);
    assert(_etherAddress != address(0));     //This should never happen

    EtherSent(_etherAddress, msg.value);
    _etherAddress.transfer(msg.value);
  }

  //Get the total wei in contract
  function totalBalance() view public returns (uint256) {
    return this.balance;
  }
  
  function transferFromContract(address[] _addresses, uint256[] _values) public onlyOwner returns (bool) {
    require(_addresses.length == _values.length);
    
    for (uint i=0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_values[i] <= balances[this]);

      // SafeMath.sub will throw if there is not enough balance.
      balances[this] = balances[this].sub(_values[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_values[i]);
      Transfer(msg.sender, _addresses[i], _values[i]);

    }
    
    return true;
  }

  function remainingSupply() public view returns(uint256) {
    return balances[this];
  }

  /**
   * @dev Burns a specific amount of tokens from the contract
   * @param amount The amount of token to be burned.
   */
  function burnFromContract(uint256 amount) public onlyOwner {
    require(amount <= balances[this]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = this;
    balances[burner] = balances[burner].sub(amount);
    totalSupply_ = totalSupply_.sub(amount);
    Burn(burner, amount);
  } 

  function etherAddress() public view onlyOwner returns(address) {
    return _etherAddress;
  }

  //Function which enables owner to change address which is storing the ether
  function setEtherAddress(address newAddress) public onlyOwner {
    require(newAddress != address(0));
    EtherAddressChanged(_etherAddress, newAddress);
    _etherAddress = newAddress;
  }
}