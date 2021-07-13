/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;


/**
 * library SafeMath
 */

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath
{

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }


  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256)
  {
    return sub(a, b, "SafeMath: subtraction overflow");
  }


  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
  {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256)
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0)
    {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }


  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256)
  {
    return div(a, b, "SafeMath: division by zero");
  }


  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256)
  {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
  {
    require(b != 0, errorMessage);
    return a % b;
  }

}


library SafeAddresses
{
  /**
   * @return charity address that gets tokens transfer fee (3%).
   */
  function associationAddress() internal pure returns(address)
  {
    return 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
  }


  /**
   * @return contributors address that gets a tokens transfer fee (0,1%).
   */
  function contributorsAddress() internal pure returns(address)
  {
    return 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
  }
}


/**
 * interface IERC20
 */
interface IERC20
{

  /**
   * function totalSupply():
   *
   * Returns the total token supply.
   */
  function totalSupply() external view returns(uint256);


  /**
   * function balanceOf(address _owner):
   *
   * Returns the account balance of another account with address _owner.
   */
  function balanceOf(address _owner) external view returns(uint256 balance);


  /**
   * function transfer(address _to, uint256 _value):
   *
   * Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
   * The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
   *
   * NOTE: Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
   */
  function transfer(address _to, uint256 _value) external returns(bool success);


  /**
   * function transferFrom(address _from, address _to, uint256 _value):
   *
   * Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
   * The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
   * This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
   * The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
   *
   * NOTE: Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
   */
  function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);


  /**
   * function approve(address _spender, uint256 _value):
   *
   * Allows _spender to withdraw from your account multiple times, up to the _value amount. If this function is called again it overwrites the current allowance with _value.
   * NOTE: To prevent attack vectors like the one described here and discussed here, clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0
   * before setting it to another value for the same spender. THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before
   */
  function approve(address _spender, uint256 _value) external returns(bool success);


  /**
   * function allowance(address _owner, address _spender):
   *
   * Returns the amount which _spender is still allowed to withdraw from _owner.
   */
  function allowance(address _owner, address _spender) external view returns(uint256 remaining);


  /**
   * function increaseAllowance(address spender, uint256 addedValue)
   *
   * Adds the addedValue amount to the amount that _spender is still allowed to withdraw from _owner.
   */
  function increaseAllowance(address spender, uint256 addedValue) external returns(bool success);


  /**
   * function decreaseAllowance(address spender, uint256 subtractedValue):
   *
   * Subtracts the addedValue amount to the amount that _spender is still allowed to withdraw from _owner.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool success);


  /**
   * event Transfer(address indexed _from, address indexed _to, uint256 _value):
   *
   * A token contract which creates new tokens SHOULD trigger a Transfer event with the _from address set to 0x0 when tokens are created.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);


  /**
   * event Approval(address indexed _owner, address indexed _spender, uint256 _value):
   *
   * MUST trigger on any successful call to approve(address _spender, uint256 _value).
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


/**
 * contract ERC20
 */
contract ERC20 is IERC20
{

  using SafeMath for uint256;
  using SafeAddresses for address;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  /**
   * @dev Total number of tokens in existence
   */
  function totalSupply() public view override returns(uint256)
  {
    return _totalSupply;
  }


  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view override returns(uint256)
  {
    return _balances[owner];
  }


  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view override returns(uint256)
  {
    return _allowances[owner][spender];
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
  function approve(address spender, uint256 value) public override returns(bool)
  {
    require(spender != address(0));
    require(_allowances[msg.sender][spender] == 0, "Address had already approve");

    _allowances[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public override returns(bool)
  {
    require(msg.sender != address(0), "Address from is address 0 (burn address)");
    require(to != address(0), "Address to is address 0 (burn address");

    require(_balances[msg.sender] >= value, "Balance from haven't enough tokens" );

    _sendValues(msg.sender, to, value);

    return true;
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public override returns(bool)
  {
    require(_allowances[from][msg.sender] >= value, "address from haven't enough allowed tokens");
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

    _sendValues(msg.sender, to, value);

    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowances to a spender. approve should be called when allowances_[_spender] == 0. To increment
   * allowances value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public override returns(bool)
  {
    require(spender != address(0));

    _allowances[msg.sender][spender] = (_allowances[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender. approve should be called when allowed_[_spender] == 0.
   * To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined) From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public override returns(bool)
  {
    require(spender != address(0));

    _allowances[msg.sender][spender] = (_allowances[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
    return true;
  }


  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public
  {
    _burn(msg.sender, value);
  }


  /**
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal
  {
    require(account != address(0));
    require(_balances[account] >= amount);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }


  /**
   * @dev Internal function that mints an amount of the token and assigns it to an account.
   * This encapsulates the modification of balances such that the proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal
  {
    require(account != address(0));
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that sends amount to differents addresses (receiver address, charity address, burn function, contributors address).
   * @param from The account that sends the amount.
   * @param to The amount that receives 96% of amount.
   * @param value The amount that will be send.
   */
  function _sendValues(address from, address to, uint256 value) internal returns(bool)
  {
    address associationAddress = SafeAddresses.associationAddress();
    address contributorsAddress = SafeAddresses.contributorsAddress();

    uint256 valueFeeAssoc = value.mul(3).div(100);
    _balances[from] = _balances[from].sub(valueFeeAssoc);
    _balances[associationAddress] = _balances[associationAddress].add(valueFeeAssoc);
    emit Transfer(from, associationAddress, valueFeeAssoc);

    // Calculate fee of tokens transfers contributors
    uint256 valueFeeContributors = value.div(1000);
    _balances[from] = _balances[from].sub(valueFeeContributors);
    _balances[contributorsAddress] = _balances[contributorsAddress].add(valueFeeContributors);
    emit Transfer(from, contributorsAddress, valueFeeContributors);

    // Calculate fee of tokens transfers burn
    uint256 valueFeeBurn = value.mul(9).div(1000);
    _burn(from, valueFeeBurn);


    uint256 valueWithFees = value.sub(valueFeeAssoc).sub(valueFeeContributors).sub(valueFeeBurn);

    _balances[to] = _balances[to].add(valueWithFees);

    emit Transfer(from, to, valueWithFees);

    return true;
  }

}



/* contract ICO is CrowdSale
{

    function buy() payable public
    {

    }

    function capHard()
    {
        uint256 montantMaxCaphard = 100000000;
    }

} */


/**
 * contract Helpone
 */
contract Helpone is ERC20
{

  using SafeMath for uint256;
  using SafeAddresses for address;

  // the name of the token
  string private _name = "Helpone";

  // the symbol of the token
  string private _symbol = "HELP";

  // the number of decimals of the token
  uint8 private _decimals = 18;

  // the number of decimals of the token (10 000 000 000 000 tokens)
  uint256 private _totalSupply = 10000000000000 * 10 ** 18;

  // the number of fee (3% for associations + 0,9% burn + 0,1% for contributors) of the token's tranfers
  uint256 private _taxFee = 4;

  address private lol;

  /**
   * @dev Constructor
   * @param tokenOwnerAddress address that gets 100% of token supply
   * mint all tokens
   */
  constructor(address payable tokenOwnerAddress) payable
  {
    // send all tokens to tokenOwnerAddress as owner
    _mint(tokenOwnerAddress, _totalSupply);

    // fee receiver for contrat deployement (payable)
    tokenOwnerAddress.transfer(msg.value);
  }


  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory)
  {
    return _name;
  }


  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory)
  {
    return _symbol;
  }


  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8)
  {
    return _decimals;
  }


  /**
   * @return the number of fee of the token.
   */
  function taxFee() public view returns(uint256)
  {
    return _taxFee;
  }


  /**
   * @return charity address that gets tokens transfer fee (3%).
   */
  function associationAddress() public pure returns(address)
  {
    return SafeAddresses.associationAddress();
  }


  /**
   * @return contributors address that gets a tokens transfer fee (0,1%).
   */
  function contributorsAddress() public pure returns(address)
  {
    return SafeAddresses.contributorsAddress();
  }

}