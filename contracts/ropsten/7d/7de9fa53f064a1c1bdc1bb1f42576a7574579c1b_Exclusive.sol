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
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
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
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

/**
 * @title ERC20Escrow
 * @dev Base ERC20 token escrow contract, holds funds designated for a payee
 * until they withdraw them.
 * @dev Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all ERC20 tokens will be handled according to
 * the Escrow rules, and there is no need to check for
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * staking method should be its owner, and provide public methods redirecting
 * to the escrow&#39;s deposit and withdraw.
 */
contract ERC20Escrow is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) internal _deposits;

  ERC20 internal _token;

  constructor(address contractAddress) public {
      require(contractAddress != address(0));
      _token = ERC20(contractAddress);
  }

  /**
   * @dev Returns total deposit of the payee.
   * @param payee The address whom to return the deposit from.
   */
  function depositsOf(address payee) external view returns (uint256) {
    return _deposits[payee];
  }

  /**
   * @dev Stores the sent tokens as credit to be withdrawn.
   * @param payee The destination address of the tokens.
   * @param payee Amount of tokens.
   */
  function deposit(address payee, uint256 amount) external onlyOwner {
    _deposit(payee, amount);
  }

  /**
  * @dev Internal function to store the sent tokens as credit to be withdrawn.
  * @param payee The destination address of the tokens.
  * @param payee Amount of tokens.
  */
  function _deposit(address payee, uint256 amount) internal {
    require(_token.allowance(payee, this) >= amount
      && (_token.balanceOf(payee) >= amount) );

    _token.safeTransferFrom(payee, this, amount);

    _deposits[payee] = _deposits[payee].add(amount);

    emit Deposited(payee, amount);
  }

  /**
   * @dev Withdraw accumulated tokens for a payee.
   * @param payee The address whose tokens will be withdrawn and transferred to.
   */
  function withdraw(address payee) external onlyOwner {
    _withdraw(payee);
  }

  /**
   * @dev Internal function to withdraw accumulated tokens for a payee.
   * @param payee The address whose tokens will be withdrawn and transferred to.
   */
  function _withdraw(address payee) internal {
    uint256 _deposit = _deposits[payee];

    _deposits[payee] = 0;

    _token.safeTransfer(payee, _deposit);

    emit Withdrawn(payee, _deposit);
  }
}



/**
 * @title Exclusive
 */
contract Exclusive is ERC20Escrow {

  enum State { Active, Refunding, Closed }

  event RefundsClosed();
  event RefundsEnabled();

  State private _state;

  string private _name;

  uint256 private _minStake;

  address[] private _stakers;

  constructor(address contractAddress, string name, uint256 minStake)
    public
    ERC20Escrow(contractAddress)
  {
      _name = name;
      _minStake = minStake;

      _state = State.Active;
  }

  /**
   * @return the current state of the exclusive.
   */
  function state() public view returns (State) {
    return _state;
  }

  /**
   * @return the name of the exclusive.
   */
  function name() external view returns(string) {
    return _name;
  }

  /**
   * @return the minimum stake required to participate to the exclusive.
   */
  function minStake() external view returns(uint256) {
    return _minStake;
  }

  /**
   * @dev the minimum stake required to participate to the exclusive.
   * @param newMinStake The new minimum stake required to participate to the exclusive.
   */
  function setMinStake(uint256 newMinStake) external onlyOwner {
    _minStake = newMinStake;
  }

  /**
   * @return the minimum stake required to participate to the exclusive.
   * @param payee The address of the potential staker.
   */
  function canAccessExclusive(address payee) external view returns(bool) {
    return _deposits[payee] >= _minStake;
  }

  /**
   * @dev Deposit tokens to participate to the exclusive.
   * @param amount Amount of tokens to stake in the exclusive contract.
   */
  function beneficiaryDeposit(uint256 amount) external {
    require(_state == State.Active);
    _deposit(msg.sender, amount);
  }

  /**
   * @dev Withdraw funds once the exclusive is over.
   */
  function beneficiaryWithdraw() external {
    require(_state == State.Refunding || _state == State.Closed);
    _withdraw(msg.sender);
  }

  /**
   * @dev End the exclusive.
   */
  function endExclusive() external onlyOwner {
    require(_state == State.Active);
    _state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @dev Close the exclusive contract by refunding all remaining stakers.
   */
  function close() external onlyOwner {
    require(_state == State.Active || _state == State.Refunding);
    _state = State.Closed;
    for (uint i = 0; i<_stakers.length; i++) {
      if(_deposits[_stakers[i]] != 0) {
        _withdraw(_stakers[i]);
      }
    }
    emit RefundsClosed();
  }

  /**
   * @dev Deposit payee&#39;s tokens to enable him participate to the exclusive.
   * @param payee The address whom to deposit the tokens from.
   * @param amount Amount of tokens to deposit in the exclusive contract.
   */
  function deposit(address payee, uint256 amount) external onlyOwner {
    require(_state == State.Active);
    _deposit(payee, amount);
  }

  /**
   * @dev Refund payee once the exclusive is over.
   * @param payee The address whom to return the tokens to.
   */
  function withdraw(address payee) external onlyOwner {
    require(_state == State.Refunding || _state == State.Closed);
    _withdraw(payee);
  }

  /**
   * @dev Internal function to deposit payee&#39;s tokens.
   * @param payee The address whom to deposit the tokens from.
   * @param amount Amount of tokens to deposit in the exclusive contract.
   */
  function _deposit(address payee, uint256 amount) internal {
    if(_deposits[payee] == 0) {
      _stakers.push(payee);
    }
    ERC20Escrow._deposit(payee, amount);
  }

  /**
   * @dev Internal function to refund payee.
   * @param payee The address whom to return the tokens to.
   */
  function _withdraw(address payee) internal {
    if(_deposits[payee] != 0) {
      for (uint i = 0; i<_stakers.length -1; i++) {
        if(_stakers[i] == payee) {
          _stakers[i] = _stakers[_stakers.length - 1];
          break;
        }
      }
      delete _stakers[_stakers.length - 1];
      _stakers.length--;

      ERC20Escrow._withdraw(payee);
    }
  }

}