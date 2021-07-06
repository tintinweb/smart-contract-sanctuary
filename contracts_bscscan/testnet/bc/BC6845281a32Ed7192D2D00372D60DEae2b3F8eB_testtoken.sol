/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-12
*/

//----------------------------------------------------------------------------
pragma solidity ^0.5.0;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
  function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
  function balanceOf(address who) external view returns (uint256);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
  function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transfer(address to, uint256 value) external returns (bool);
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
  function approve(address spender, uint256 value) external returns (bool);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transferFrom(address from, address to, uint256 value) external returns (bool);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
library SafeMath {
    
 /**@dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
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
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }
      /**
     * @dev Returns the name of the token.
     */
  function name() public view returns(string memory) {
    return _name;
  }
      /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
  function symbol() public view returns(string memory) {
    return _symbol;
  }
      /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}
contract testtoken is ERC20Detailed {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "testmoon";
  string constant tokenSymbol = "TestM";
  uint8  constant tokenDecimals = 9;
  uint256 _totalSupply = 45000000000000000;
  uint256 public basePercent = 19;
  
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
  
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }
      /**
     * @dev See {IERC20-totalSupply}.
     */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
      /**
     * @dev See {IERC20-balanceOf}.
     */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
      /**
     * @dev See {IERC20-allowance}.
     */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
  
      /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);
    return true;
  }
  
      /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
      /*
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
   /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
  
    /*
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  /*
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}