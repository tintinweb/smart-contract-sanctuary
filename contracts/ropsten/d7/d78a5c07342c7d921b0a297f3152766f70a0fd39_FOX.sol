pragma solidity ^0.4.24;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title FOX ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol
 */
contract FOX is IERC20, Ownable {
  /**
   * MATH
   */
  using SafeMath for uint256;

  /**
  * DATA
  */

  // ERC20 BASIC DATA 
  mapping (address => uint256) private _balances;
  string public constant name = "FOX token"; // solium-disable-line uppercase
  string public constant symbol = "FOX"; // solium-disable-line uppercase
  uint8 public constant decimals = 8; // solium-disable-line uppercase
  uint256 private _totalSupply;

  // ERC20 DATA
  mapping (address => mapping (address => uint256)) private _allowed;

  // INITIALIZATION DATA
  bool private initialized = false;

  /**
  * FUNCTIONALITY
  */

  // INITIALIZATION FUNCTIONALITY

  /**
  * @dev sets initials tokens, the owner.
  * this serves as the constructor for the proxy but compiles to the
  * memory model of the Implementation contract.
  */
  function initialize() public {
    require(!initialized, "already initialized");
    Ownable.initialize();  // Initialize Parent Contract

    _totalSupply = 2*10**9*10**8;
    _balances[owner()] = _totalSupply;
    initialized = true;
  }

  /**
  * The constructor is used here to ensure that the implementation
  * contract is initialized. An uncontrolled implementation
  * contract might lead to misleading state
  * for users who accidentally interact with it.
  */
  constructor() public {
    initialize();
  }

  // ERC20 BASIC FUNCTIONALITY

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _addr The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _addr) public view returns (uint256) {
    return _balances[_addr];
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

  // ERC20 FUNCTIONALITY

  /**
  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  * @param _owner address The address which owns the funds.
  * @param spender address The address which will spend the funds.
  * @return A uint256 specifying the amount of tokens still available for the spender.
  */
  function allowance(address _owner, address spender) public view returns (uint256) {
    return _allowed[_owner][spender];
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);
    return true;
  }

  function issue(uint256 amount) public onlyOwner {
        _totalSupply += amount;
        _balances[owner()] += amount;

        emit Transfer(address(0), owner(), amount);
  }
  
  function burn(uint256 amount) public {
        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[msg.sender] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}