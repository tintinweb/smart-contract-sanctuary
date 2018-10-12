pragma solidity ^0.4.13;

library SafeMath {

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
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract TokenDestructible is Ownable {

  constructor() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param _tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] _tokens) public onlyOwner {

    // Transfer tokens to owner
    for (uint256 i = 0; i < _tokens.length; i++) {
      ERC20Basic token = ERC20Basic(_tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract IndividualLockableToken is PausableToken{

  using SafeMath for uint256;



  event LockTimeSetted(address indexed holder, uint256 old_release_time, uint256 new_release_time);

  event Locked(address indexed holder, uint256 locked_balance_change, uint256 total_locked_balance, uint256 release_time);



  struct lockState {

    uint256 locked_balance;

    uint256 release_time;

  }



  // default lock period

  uint256 public lock_period = 24 weeks;



  mapping(address => lockState) internal userLock;



  // Specify the time that a particular person&#39;s lock will be released

  function setReleaseTime(address _holder, uint256 _release_time)

    public

    onlyOwner

    returns (bool)

  {

    require(_holder != address(0));

	require(_release_time >= block.timestamp);



	uint256 old_release_time = userLock[_holder].release_time;



	userLock[_holder].release_time = _release_time;

	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);

	return true;

  }

  

  // Returns the point at which token holder&#39;s lock is released

  function getReleaseTime(address _holder)

    public

    view

    returns (uint256)

  {

    require(_holder != address(0));



	return userLock[_holder].release_time;

  }



  // Unlock a specific person. Free trading even with a lock balance

  function clearReleaseTime(address _holder)

    public

    onlyOwner

    returns (bool)

  {

    require(_holder != address(0));

    require(userLock[_holder].release_time > 0);



	uint256 old_release_time = userLock[_holder].release_time;



	userLock[_holder].release_time = 0;

	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);

	return true;

  }



  // Increase the lock balance of a specific person.

  // If you only want to increase the balance, the release_time must be specified in advance.

  function increaseLockBalance(address _holder, uint256 _value)

    public

    onlyOwner

    returns (bool)

  {

	require(_holder != address(0));

	require(_value > 0);

	require(balances[_holder] >= _value);

	

	if (userLock[_holder].release_time == 0) {

		userLock[_holder].release_time = block.timestamp + lock_period;

	}

	

	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).add(_value);

	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);

	return true;

  }



  // Decrease the lock balance of a specific person.

  function decreaseLockBalance(address _holder, uint256 _value)

    public

    onlyOwner

    returns (bool)

  {

	require(_holder != address(0));

	require(_value > 0);

	require(userLock[_holder].locked_balance >= _value);



	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).sub(_value);

	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);

	return true;

  }



  // Clear the lock.

  function clearLock(address _holder)

    public

    onlyOwner

    returns (bool)

  {

	require(_holder != address(0));

	require(userLock[_holder].release_time > 0);



	userLock[_holder].locked_balance = 0;

	userLock[_holder].release_time = 0;

	emit Locked(_holder, 0, userLock[_holder].locked_balance, userLock[_holder].release_time);

	return true;

  }



  // Check the amount of the lock

  function getLockedBalance(address _holder)

    public

    view

    returns (uint256)

  {

    if(block.timestamp >= userLock[_holder].release_time) return uint256(0);

    return userLock[_holder].locked_balance;

  }



  // Check your remaining balance

  function getFreeBalance(address _holder)

    public

    view

    returns (uint256)

  {

    if(block.timestamp >= userLock[_holder].release_time) return balances[_holder];

    return balances[_holder].sub(userLock[_holder].locked_balance);

  }



  // transfer overrride

  function transfer(

    address _to,

    uint256 _value

  )

    public

    returns (bool)

  {

    require(getFreeBalance(msg.sender) >= _value);

    return super.transfer(_to, _value);

  }



  // transferFrom overrride

  function transferFrom(

    address _from,

    address _to,

    uint256 _value

  )

    public

    returns (bool)

  {

    require(getFreeBalance(_from) >= _value);

    return super.transferFrom(_from, _to, _value);

  }



  // approve overrride

  function approve(

    address _spender,

    uint256 _value

  )

    public

    returns (bool)

  {

    require(getFreeBalance(msg.sender) >= _value);

    return super.approve(_spender, _value);

  }



  // increaseApproval overrride

  function increaseApproval(

    address _spender,

    uint _addedValue

  )

    public

    returns (bool success)

  {

    require(getFreeBalance(msg.sender) >= allowed[msg.sender][_spender].add(_addedValue));

    return super.increaseApproval(_spender, _addedValue);

  }

  

  // decreaseApproval overrride

  function decreaseApproval(

    address _spender,

    uint _subtractedValue

  )

    public

    returns (bool success)

  {

	uint256 oldValue = allowed[msg.sender][_spender];

	

    if (_subtractedValue < oldValue) {

      require(getFreeBalance(msg.sender) >= oldValue.sub(_subtractedValue));	  

    }    

    return super.decreaseApproval(_spender, _subtractedValue);

  }

}

contract EthereumRed is IndividualLockableToken, TokenDestructible {

  using SafeMath for uint256;



  string public constant name = "Ethereum Red";

  string public constant symbol = "ERED";

  uint8  public constant decimals = 18;



  // 24,000,000,000 YRE

  uint256 public constant INITIAL_SUPPLY = 500000000 * (10 ** uint256(decimals));



  constructor()

    public

  {

    totalSupply_ = INITIAL_SUPPLY;

    balances[msg.sender] = totalSupply_;

  }

}