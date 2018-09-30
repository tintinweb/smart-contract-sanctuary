pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract TestMNC {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => uint256) private _freeze;

  uint256 private _totalSupply;

  string public constant name = "TestMNC";
  string public constant symbol = "TMNC";
  uint8 public constant decimals = 18;
  address public owner;

  uint256 private constant _initialSupply = 200000000 * (10 ** uint256(decimals));

  /* This notifies clients about the amount transferred */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  /* This notifies clients about the amount approved */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /* This notifies clients about the amount burnt */
  event Burn(
    address indexed from,
	uint256 value
  );

  /* This notifies clients about the amount frozen */
  event Freeze(
    address indexed from,
	uint256 value
  );

  /* This notifies clients about the amount unfrozen */
  event Unfreeze(
    address indexed from,
	uint256 value
  );

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
	require(msg.sender != 0);
    _totalSupply = _initialSupply;
    _balances[msg.sender] = _initialSupply;
	owner = msg.sender;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }

  /**
   * @dev Total number of tokens in existence
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param account The address to query the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Gets the frozen balance of the specified address.
   * @param account The address to query the frozen balance of.
   * @return An uint256 representing the amount frozen by the passed address.
   */
  function freezeOf(address account) public view returns (uint256) {
    return _freeze[account];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param account address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address account,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[account][spender];
  }

  /**
   * @dev Transfer token for a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
	_burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
	require(value <= _allowed[from][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _burn(from, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Burn(account, amount);
  }

  /**
   * @dev Freezes a specific amount of tokens
   * @param amount uint256 The amount of token to be frozen
   */
  function freeze(uint256 amount) public {
    require(_balances[msg.sender] >= amount);
    require(amount > 0);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _freeze[msg.sender] = _freeze[msg.sender].add(amount);
    emit Freeze(msg.sender, amount);
  }

  /**
   * @dev Unfreezes a specific amount of tokens
   * @param amount uint256 The amount of token to be unfrozen
   */
  function unfreeze(uint256 amount) public {
    require(_freeze[msg.sender] >= amount);
    require(amount > 0);
    _freeze[msg.sender] = _freeze[msg.sender].sub(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    emit Unfreeze(msg.sender, amount);
  }
  
  /**
   * @dev Allows to transfer out the ether balance that was forced into this contract, e.g with `selfdestruct`
   */
  function withdrawEther() public {
	require(msg.sender == owner);
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0);
    owner.transfer(totalBalance);
  }

  /**
   * @dev Contract can receive ether
   */
  function() payable public {
  }
}