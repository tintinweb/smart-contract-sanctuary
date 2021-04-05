/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity 0.5.12;

library SafeMaths {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole  {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;
    
    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract AssetPoolToken is MinterRole {
    string public constant name = "AssetPool Token";
    string public constant symbol = "APT";
    uint8 public constant decimals = 18;
    constructor() public 
    {

    }
    using SafeMaths for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view   returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public   returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public   returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

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
    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");


        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public  {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public  {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    
        /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
    
    
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

 /**
  * @title INonStandardERC20
  * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
  *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
  */
interface INonStandardERC20 {
     /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
     function totalSupply() external view returns (uint256);

     /**
      * @notice Gets the balance of the specified address
      * @param owner The address from which the balance will be retrieved
      * @return The balance
      */
     function balanceOf(address owner) external view returns (uint256 balance);

     ///
     /// !!!!!!!!!!!!!!
     /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
     /// !!!!!!!!!!!!!!
     ///

     /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
     function transfer(address dst, uint256 amount) external;

     ///
     /// !!!!!!!!!!!!!!
     /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
     /// !!!!!!!!!!!!!!
     ///

     /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
     function transferFrom(
         address src,
         address dst,
         uint256 amount
     ) external;

     /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
     function approve(address spender, uint256 amount)
         external
         returns (bool success);

     /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
     function allowance(address owner, address spender)
         external
         view
         returns (uint256 remaining);

     event Transfer(address indexed from, address indexed to, uint256 amount);
     event Approval(
         address indexed owner,
         address indexed spender,
         uint256 amount
     );
 }

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view   returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public   returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public   returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

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
    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");


        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
}

contract ERC20Detailed is ERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract StockLiquiditator is ERC20Detailed
{

    using SafeMath for uint256;
    
    uint256 public cashDecimals;
    uint256 public assetTokenMultiplier;
    
    ERC20Detailed internal cash;
    AssetPoolToken internal assetPoolToken;
    ERC20Detailed internal assetToken;
    
    uint256 public assetToCashRate;
    uint256 public cashValauationCap;
    
    string public url;
    
    event UrlUpdated(string _url);
    event ValuationCapUpdated(uint256 cashCap);
    event OwnerChanged(address indexed newOwner);
    event CashboxPoolRateUpdated(uint256 cashboxPoolRate);
    event AssetPoolRateUpdated(uint256 assetPoolrate);
    event CashTokensRedeemed(address indexed user,uint256 redeeemedCashAmount,uint256 outputAssetAmount,uint256 mintedCashboxPoolAmount);
    event CashboxPoolTokensBurnt(address indexed user,uint256 burntCashboxPoolAmount,uint256 outputAssetAmount,uint256 outputCashAmount);
    event AssetTokensRedeemed(address indexed user,uint256 redeemedAssetToken,uint256 outputCashAmount,uint256 mintedAssetPoolAmount);
    event AssetPoolTokensBurnt(address indexed user,uint256 burntAssetPoolToken,uint256 outputAssetAmount,uint256 outputCashAmount);
    
    function () external {  //fallback function
        
    }
    
    address payable public owner;
    
    modifier onlyOwner() {
        require (msg.sender == owner,"Account not Owner");
        _;
    }
        
    constructor (address cashAddress,address assetTokenAddress,uint256 _assetToCashRate,uint256 cashCap,string memory name,string memory symbol,string memory _url) 
    public ERC20Detailed( name, symbol, 18)  
    {
        require(msg.sender != address(0), "Zero address cannot be owner/contract deployer");
        owner = msg.sender;
        require(assetTokenAddress != address(0), "assetToken is the zero address");
        require(cashAddress != address(0), "cash is the zero address");
        require(_assetToCashRate != 0, "Asset to cash rate can't be zero");
        cash = ERC20Detailed(cashAddress);
        assetToken = ERC20Detailed(assetTokenAddress);
        cashDecimals = cash.decimals();
        assetTokenMultiplier = (10**uint256(assetToken.decimals()));
        assetToCashRate = ((10**(cashDecimals)).mul(_assetToCashRate)).div(1e18);
        updateCashValuationCap(cashCap);
        updateURL(_url);
        assetPoolToken = new AssetPoolToken();
    }
    
    function updateURL(string memory _url) public onlyOwner returns(string memory){
        url=_url;
        emit UrlUpdated(_url);
        return url;
    }
    
    function updateCashValuationCap(uint256 cashCap) public onlyOwner returns(uint256){
        cashValauationCap=cashCap;
        emit ValuationCapUpdated(cashCap);
        return cashValauationCap;
    }
    
    function changeOwner(address payable newOwner) external onlyOwner {
        owner=newOwner;
        emit OwnerChanged(newOwner);
    }
    
    function assetPoolTokenAddress() public view returns (address) {
        return address(assetPoolToken);
    }
    
    function _preValidateData(address beneficiary, uint256 amount) internal pure {
        require(beneficiary != address(0), "Beneficiary can't be zero address");
        require(amount != 0, "amount can't be 0");
    }
    
    function contractCashBalance() public view returns(uint256 cashBalance){
        return cash.balanceOf(address(this));
    } 
    
    function contractAssetTokenBalance() public view returns(uint256 assetTokenBalance){
        return assetToken.balanceOf(address(this));
    }
    
    function assetTokenCashValuation() internal view returns(uint256){
        uint256 cashEquivalent=(contractAssetTokenBalance().mul(assetToCashRate)).div(assetTokenMultiplier);
        return cashEquivalent;
    }
    
    function contractCashValuation() public view returns(uint256 cashValauation){
        uint256 cashEquivalent=(contractAssetTokenBalance().mul(assetToCashRate)).div(assetTokenMultiplier);
        return contractCashBalance().add(cashEquivalent);
    }

    function depositCash(uint256 inputCashAmount) external {    
        if(cashValauationCap!=0)
        {
            require(inputCashAmount.add(contractCashValuation())<=cashValauationCap,"inputCashAmount exceeds cashValauationCap");
        }
        address sender= msg.sender;
        _preValidateData(sender,inputCashAmount);

        uint256 actualCashReceived = doTransferIn(
            address(cash),
            sender,
            inputCashAmount
        );
        
        uint256 outputAssetAmount = 0;
        uint256 cashboxPoolTokens = 0;
        
        uint256 assetToRedeem=(actualCashReceived.mul(assetTokenMultiplier)).div(assetToCashRate);
        
        if(assetToRedeem <= contractAssetTokenBalance()){
            outputAssetAmount = assetToRedeem;
            if(outputAssetAmount > 0){
                doTransferOut(address(assetToken), sender, outputAssetAmount);
            }
        }
        
        else{
            outputAssetAmount=contractAssetTokenBalance();
            if(outputAssetAmount > 0){
                doTransferOut(address(assetToken), sender, outputAssetAmount);
            }
            uint256 remainingAsCashTokens = ((assetToRedeem.sub(outputAssetAmount)).mul(assetToCashRate)).div(assetTokenMultiplier);
            
            // calculate CashboxPool token amount to be minted
            cashboxPoolTokens = remainingAsCashTokens;
            _mint(sender, cashboxPoolTokens); //Minting  CashboxPool Token
        }
        emit CashTokensRedeemed(sender,actualCashReceived,outputAssetAmount,cashboxPoolTokens);
    }
    
    function burnCashboxPoolToken(uint256 cashboxPoolTokenAmount) external {  
        address sender= msg.sender;
        _preValidateData(sender,cashboxPoolTokenAmount);
        
        uint256 assetToRedeem = cashboxPoolTokenAmount.mul(assetTokenMultiplier).div(assetToCashRate);
        _burn(sender, cashboxPoolTokenAmount);
        
        uint256 outputAssetToken = 0;
        uint256 outputCashAmount = 0;
        if( assetToRedeem<= contractAssetTokenBalance() )
        {
            outputAssetToken=assetToRedeem;//calculate Asset token amount to be return
            if(outputAssetToken > 0){
                doTransferOut(address(assetToken), sender, outputAssetToken);
            }
        }
        
        else
        {
            outputAssetToken=contractAssetTokenBalance();
            if(outputAssetToken > 0){
                doTransferOut(address(assetToken), sender, outputAssetToken);
            }
            outputCashAmount=cashboxPoolTokenAmount.sub(outputAssetToken);// calculate cash amount to be return
            doTransferOut(address(cash), sender, outputCashAmount);
        }
         
        emit CashboxPoolTokensBurnt(sender,cashboxPoolTokenAmount,outputAssetToken,outputCashAmount);
    }
    
    function depositAsset(uint256 inputAssetTokenAmount) external {    
        address sender= msg.sender;
        _preValidateData(sender,inputAssetTokenAmount);

        uint256 actualAssetReceived = doTransferIn(
            address(assetToken),
            sender,
            inputAssetTokenAmount
        );
        uint256 outputCashAmount = 0;
        uint256 mintableAssetPoolTokens = 0;
        
        uint256 cashToRedeem=(actualAssetReceived.mul(assetToCashRate)).div(assetTokenMultiplier);
        
        if(cashToRedeem <= contractCashBalance()){
            outputCashAmount = cashToRedeem;
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
        }
        else{
            outputCashAmount=contractCashBalance();
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
            uint256 remainingAsAssetTokens=((cashToRedeem.sub(outputCashAmount)).mul(assetTokenMultiplier)).div(assetToCashRate);
            
            // calculate Asset Pool token amount to be minted
            mintableAssetPoolTokens = remainingAsAssetTokens;
            assetPoolToken.mint(sender, mintableAssetPoolTokens); //Minting  Asset Pool Token
        }
        emit AssetTokensRedeemed(sender,actualAssetReceived,outputCashAmount,mintableAssetPoolTokens);
    }
    
    function burnAssetPoolToken(uint256 assetPoolTokenAmount) external {  
        address sender= msg.sender;
        _preValidateData(sender,assetPoolTokenAmount);
        uint256 cashToRedeem = (assetPoolTokenAmount.mul(assetToCashRate)).div(assetTokenMultiplier);
        assetPoolToken.burnFrom(sender,assetPoolTokenAmount);
        
        uint256 outputAssetToken = 0;
        uint256 outputCashAmount = 0;
        if( cashToRedeem<=contractCashBalance()  )
        { 
            outputCashAmount = cashToRedeem;
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
            
        }
        else
        {
            outputCashAmount=contractCashBalance();
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
            uint256 remainingCash = cashToRedeem.sub(outputCashAmount);
            outputAssetToken=(remainingCash.mul(assetTokenMultiplier)).div(assetToCashRate);
            doTransferOut(address(assetToken), sender, outputAssetToken);
        }
        emit AssetPoolTokensBurnt(sender,assetPoolTokenAmount,outputAssetToken,outputCashAmount);
    }
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        INonStandardERC20 token = INonStandardERC20(tokenAddress);
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        INonStandardERC20 token = INonStandardERC20(tokenAddress);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}
contract DeployFactory {
    event CashBoxAdded(
        address indexed cashBoxAddress,
        address indexed cashBoxOwner,
        address indexed assetTokenAddress,
        address cashTokenAddress,
        string url
    );

    address[] public cashBoxes;

    function createCashBox(
        address cashTokenAddress,
        address assetTokenAddress,
        uint256 assetToCashRate,
        uint256 cashCap,
        string memory name,
        string memory symbol,
        string memory url
    ) public returns (address newCashBox) {
        StockLiquiditator cashBox = new StockLiquiditator(
            cashTokenAddress,
            assetTokenAddress,
            assetToCashRate,
            cashCap,
            name,
            symbol,
            url
        );
        cashBox.changeOwner(msg.sender);

        cashBoxes.push(address(cashBox));
        emit CashBoxAdded(
            address(cashBox),
            msg.sender,
            assetTokenAddress,
            cashTokenAddress,
            url
        );
        return address(cashBox);
    }

    function getAllCashBoxes() public view returns (address[] memory) {
        return cashBoxes;
    }

    function getCashBoxesByUser(address account)
        external
        view
        returns (address[] memory)
    {
        uint256 len = cashBoxes.length;
        address[] memory cashBoxesByUser = new address[](len);
        uint256 index = 0;

        for (uint256 i = 0; i < len; i++) {
            address payable cashBoxAddress = address(uint160(cashBoxes[i]));
            StockLiquiditator cashbox = StockLiquiditator(cashBoxAddress);

            if (cashbox.owner() == account) {
                cashBoxesByUser[index] = cashBoxes[i];
                index++;
            }
        }

        // to remove zero addresses from the result
        address[] memory result = new address[](index);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = cashBoxesByUser[i];
        }

        return result;
    }
}