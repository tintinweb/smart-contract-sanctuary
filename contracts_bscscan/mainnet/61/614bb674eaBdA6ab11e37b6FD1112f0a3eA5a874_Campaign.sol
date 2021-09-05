/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-02
*/

// SPDX-License-Identifier: agpl-3.0

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

    

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

    

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

    

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

    

pragma solidity >=0.6.0 <0.8.0;




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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/utils/Address.sol

    

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

    

pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Interfaces.sol

    

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License


interface IFactoryGetters {
    function getLpRouter() external view returns(address);
    function getFeeAddress() external view returns(address);
    function getLauncherToken() external view returns(address);
}

// Uniswap v2
interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// File: contracts/Campaign.sol

    

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License

pragma experimental ABIEncoderV2;





 
contract Campaign {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public factory;
    address public campaignOwner;
    address public token;
    uint256 public softCap;            
    uint256 public hardCap;  
    uint256 public tokenSalesQty;
    uint256 public feePcnt;
    uint256 public qualifyingTokenQty;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public midDate;         // Start of public sales for WhitelistedFirstThenEveryone type
    uint256 public minBuyLimit;            
    uint256 public maxBuyLimit;    
    
    // Liquidity
    uint256 public lpBnbQty;    
    uint256 public lpTokenQty;
    uint256 public lpLockDuration; 
    uint256[2] private lpInPool; // This is the actual LP provided in pool.
    bool private recoveredUnspentLP;
    
    // Config
    bool public burnUnSold;    
   
    // Misc variables //
    uint256 public unlockDate;
    uint256 public collectedBNB;
    uint256 public lpTokenAmount;

    // States
    bool public tokenFunded;        
    bool public finishUpSuccess; 
    bool public liquidityCreated;
    bool public cancelled;          

   // Token claiming by users
    mapping(address => bool) public claimedRecords; 
    bool public tokenReadyToClaim;    

    // Map user address to amount invested in BNB //
    mapping(address => uint256) public participants; 
    uint256 public numOfParticipants;

    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    // Whitelisting support
    enum Accessibility {
        Everyone, 
        WhitelistedOnly, 
        WhitelistedFirstThenEveryone
    }
    Accessibility public accessibility;
    uint256 public numOfWhitelisted;
    mapping(address => bool) public whitelistedMap;
    

    // Vesting Feature Support
    uint256 internal constant PERCENT100 = 1e6;

    struct VestingInfo {
        uint256[]  times;
        uint256[]  percents;
        uint256 totalVestedBnb;
        bool enabled;
    }
    VestingInfo public vestInfo;
    mapping(address=>mapping(uint256=>bool)) investorsClaimMap;
    mapping(uint256=>bool) campaignOwnerClaimMap;


    // Events
    event Purchased(
        address indexed user,
        uint256 timeStamp,
        uint256 amountBnb,
        uint256 amountToken
    );

    event LiquidityAdded(
        uint256 amountBnb,
        uint256 amountToken,
        uint256 amountLPToken
    );

    event LiquidityLocked(
        uint256 timeStampStart,
        uint256 timeStampExpiry
    );

    event LiquidityWithdrawn(
        uint256 amount
    );

    event TokenClaimed(
        address indexed user,
        uint256 timeStamp,
        uint256 amountToken
    );

    event Refund(
        address indexed user,
        uint256 timeStamp,
        uint256 amountBnb
    );

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    modifier onlyCampaignOwner() {
        require(msg.sender == campaignOwner, "Only campaign owner can call");
        _;
    }

    modifier onlyFactoryOrCampaignOwner() {
        require(msg.sender == factory || msg.sender == campaignOwner, "Only factory or campaign owner can call");
        _;
    }

    constructor() public{
        factory = msg.sender;
    }
    
    /**
     * @dev Initialize  a new campaign.
     * @notice - Access control: External. Can only be called by the factory contract.
     */
    function initialize
    (
        address _token,
        address _campaignOwner,
        uint256[5] calldata _stats,  
        uint256[3] calldata _dates, 
        uint256[2] calldata _buyLimits,    
        Campaign.Accessibility _access,  
        uint256[3] calldata _liquidity, 
        bool _burnUnSold
    ) external
    {
        require(msg.sender == factory,'Only factory allowed to initialize');
        token = _token;
        campaignOwner = _campaignOwner; 
        softCap = _stats[0];
        hardCap = _stats[1];
        tokenSalesQty = _stats[2];
        feePcnt = _stats[3];
        qualifyingTokenQty = _stats[4];
        startDate = _dates[0];
        endDate = _dates[1];
        midDate = _dates[2];
        minBuyLimit = _buyLimits[0];
        maxBuyLimit = _buyLimits[1];
        accessibility = _access;
        lpBnbQty = _liquidity[0];
        lpTokenQty = _liquidity[1];
        lpLockDuration = _liquidity[2];
        burnUnSold = _burnUnSold;
    }
    
    /**
     * @dev Allows campaign owner to fund in his token.
     * @notice - Access control: External, OnlyCampaignOwner
     */
    function fundIn() external onlyCampaignOwner {
        require(!tokenFunded, "Campaign is already funded");
        uint256 amt = getCampaignFundInTokensRequired();
        require(amt > 0, "Invalid fund in amount");

        tokenFunded = true;
        ERC20(token).safeTransferFrom(msg.sender, address(this), amt);  
    }

    // In case of a "cancelled" campaign, or softCap not reached, 
    // the campaign owner can retrieve back his funded tokens.
    function fundOut() external onlyCampaignOwner {
        require(failedOrCancelled(), "Only failed or cancelled campaign can un-fund");

        ERC20 ercToken = ERC20(token);
        uint256 totalTokens = ercToken.balanceOf(address(this));
        sendTokensTo(campaignOwner, totalTokens);
        tokenFunded = false;
    }

    /**
     * @dev Allows user to buy token.
     * @notice - Access control: Public
     */
    function buyTokens() public payable {
        
        require(isLive(), "Campaign is not live");
        require(checkQualifyingTokens(msg.sender), "Insufficient LAUNCH tokens to qualify"); 
        require(checkWhiteList(msg.sender), "You are not whitelisted");

        // Check for min purchase amount
        require(msg.value >= minBuyLimit, "Less than minimum purchase amount");

        // Check for over purchase
        uint256 invested =  participants[msg.sender];
        require(invested.add(msg.value) <= maxBuyLimit, "Exceeded max amount"); 
        require(msg.value <= getRemaining(),"Insufficent token left");

        uint256 buyAmt = calculateTokenAmount(msg.value);
        
        if (invested == 0) {
            numOfParticipants = numOfParticipants.add(1);
        }

        participants[msg.sender] = participants[msg.sender].add(msg.value);
        collectedBNB = collectedBNB.add(msg.value);

        emit Purchased(msg.sender, block.timestamp, msg.value, buyAmt);
    }

    /**
     * @dev Add liquidity and lock it up. Called after a campaign has ended successfully.
     * @notice - Access control: Public. onlyFactoryOrCampaignOwner. This allows the admin or campaignOwner to
     * coordinate the adding of LP when all campaigns are completed. This ensure a fairer arrangement, esp
     * when multiple campaigns are running in parallel.
     */
    function addAndLockLP() external onlyFactoryOrCampaignOwner {

        require(!isLive(), "Presale is still live");
        require(!failedOrCancelled(), "Presale failed or cancelled , can't provide LP");
        require(softCap <= collectedBNB, "Did not reach soft cap");

        if ((lpBnbQty > 0 && lpTokenQty > 0) && !liquidityCreated) {
        
            liquidityCreated = true;

            IFactoryGetters fact = IFactoryGetters(factory);
            address lpRouterAddress = fact.getLpRouter();
            require(ERC20(address(token)).approve(lpRouterAddress, lpTokenQty)); // Uniswap doc says this is required //
 
            (uint256 retTokenAmt, uint256 retBNBAmt, uint256 retLpTokenAmt) = IUniswapV2Router02(lpRouterAddress).addLiquidityETH
                {value : lpBnbQty}
                (address(token),
                lpTokenQty,
                0,
                0,
                address(this),
                block.timestamp + 100000000);
            
            lpTokenAmount = retLpTokenAmt;
            lpInPool[0] = retBNBAmt;
            lpInPool[1] = retTokenAmt;

            emit LiquidityAdded(retBNBAmt, retTokenAmt, retLpTokenAmt);
            
            unlockDate = (block.timestamp).add(lpLockDuration);
            emit LiquidityLocked(block.timestamp, unlockDate);
        }
    }

    /**
     * @dev Get the actual liquidity added to LP Pool
     * @return - uint256[2] consist of BNB amount, Token amount.
     * @notice - Access control: Public, View
     */
    function getPoolLP() external view returns (uint256, uint256) {
        return (lpInPool[0], lpInPool[1]);
    }

    /**
     * @dev There are situations that the campaign owner might call this.
     * @dev 1: Pancakeswap pool SC failure when we call addAndLockLP().
     * @dev 2: Pancakeswap pool already exist. After we provide LP, thee's some excess bnb/tokens
     * @dev 3: Campaign owner decided to change LP arrangement after campaign is successful.
     * @dev In that case, campaign owner might recover it and provide LP manually.
     * @dev Note: This function can only be called once by factory, as this is not a normal workflow.
     * @notice - Access control: External, onlyFactory
     */
    function recoverUnspentLp() external onlyFactory {
        
        require(!recoveredUnspentLP, "You have already recovered unspent LP");
        recoveredUnspentLP = true;

        uint256 bnbAmt;
        uint256 tokenAmt;

        if (liquidityCreated) {
            // Find out any excess bnb/tokens after LP provision is completed.
            bnbAmt = lpBnbQty.sub(lpInPool[0]);
            tokenAmt = lpTokenQty.sub(lpInPool[1]);
        } else {
            // liquidity not created yet. Just returns the full portion of the planned LP
            // Only finished success campaign can recover Unspent LP
            require(finishUpSuccess, "Campaign not finished successfully yet");
            bnbAmt = lpBnbQty;
            tokenAmt = lpTokenQty;
        }

        // Return bnb, token if any
        if (bnbAmt > 0) {
            (bool ok, ) = campaignOwner.call{value: bnbAmt}("");
            require(ok, "Failed to return BNB Lp");
        }

        if (tokenAmt > 0) {
            ERC20(token).safeTransfer(campaignOwner, tokenAmt);
        }
    }

    /**
     * @dev When a campaign reached the endDate, this function is called.
     * @dev Add liquidity to uniswap and burn the remaining tokens.
     * @dev Can be only executed when the campaign completes.
     * @dev Anyone can call. Only called once.
     * @notice - Access control: Public
     */
    function finishUp() external {
       
        require(!finishUpSuccess, "finishUp is already called");
        require(!isLive(), "Presale is still live");
        require(!failedOrCancelled(), "Presale failed or cancelled , can't call finishUp");
        require(softCap <= collectedBNB, "Did not reach soft cap");
        finishUpSuccess = true;

        uint256 feeAmt = getFeeAmt(collectedBNB);
        uint256 unSoldAmtBnb = getRemaining();
        uint256 remainBNB = collectedBNB.sub(feeAmt);
        
        // If lpBnbQty, lpTokenQty is 0, we won't provide LP.
        if ((lpBnbQty > 0 && lpTokenQty > 0)) {
            remainBNB = remainBNB.sub(lpBnbQty);
        }
        
        // Send fee to fee address
        if (feeAmt > 0) {
            (bool sentFee, ) = getFeeAddress().call{value: feeAmt}("");
            require(sentFee, "Failed to send Fee to platform");
        }

        // Send remain bnb to campaign owner if not in vested Mode
        if (!vestInfo.enabled) {
            (bool sentBnb, ) = campaignOwner.call{value: remainBNB}("");
            require(sentBnb, "Failed to send remain BNB to campaign owner");
        } else {
            vestInfo.totalVestedBnb = remainBNB;
        }

        // Calculate the unsold amount //
        if (unSoldAmtBnb > 0) {
            uint256 unsoldAmtToken = calculateTokenAmount(unSoldAmtBnb);
            // Burn or return UnSold token to owner 
            sendTokensTo(burnUnSold ? BURN_ADDRESS : campaignOwner, unsoldAmtToken);  
        }     
    }


    /**
     * @dev Allow Factory owner to call this to set the flag to
     * @dev enable token claiming.
     * @dev This is useful when 1 project has multiple campaigns that need
     * @dev to sync up the timing of token claiming After LP provision.
     * @notice - Access control: External,  onlyFactory
     */
    function setTokenClaimable() external onlyFactory {
        
        require(finishUpSuccess, "Campaign not finished successfully yet");

        // Token is only claimable in non-vested mode
        require(!vestInfo.enabled, "Not applicable to vested mode");

        tokenReadyToClaim = true;
    }

    /**
     * @dev Allow users to claim their tokens. 
     * @notice - Access control: External
     */
    function claimTokens() external {

        require(tokenReadyToClaim, "Tokens not ready to claim yet");
        require( claimedRecords[msg.sender] == false, "You have already claimed");
        
        uint256 amtBought = getTotalTokenPurchased(msg.sender);
        if (amtBought > 0) {
            claimedRecords[msg.sender] = true;
            ERC20(token).safeTransfer(msg.sender, amtBought);
            emit TokenClaimed(msg.sender, block.timestamp, amtBought);
        }
    }

     /**
     * @dev Allows campaign owner to withdraw LP after the lock duration.
     * @dev Only able to withdraw LP if lockActivated and lock duration has expired.
     * @dev Can call multiple times to withdraw a portion of the total lp.
     * @param _lpToken - The LP token address
     * @notice - Access control: Internal, OnlyCampaignOwner
     */
    function withdrawLP(address _lpToken,uint256 _amount) external onlyCampaignOwner 
    {
        require(liquidityCreated, "liquidity is not yet created");
        require(block.timestamp >= unlockDate ,"Unlock date not reached");
        
        ERC20(_lpToken).safeTransfer(msg.sender, _amount);
        emit LiquidityWithdrawn( _amount);
    }

    /**
     * @dev Allows Participants to withdraw/refunds when campaign fails
     * @notice - Access control: Public
     */
    function refund() external {
        require(failedOrCancelled(),"Can refund for failed or cancelled campaign only");

        uint256 investAmt = participants[msg.sender];
        require(investAmt > 0 ,"You didn't participate in the campaign");

        participants[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: investAmt}("");
        require(ok, "Failed to refund BNB to user");

        if (numOfParticipants > 0) {
            numOfParticipants -= 1;
        }

        emit Refund(msg.sender, block.timestamp, investAmt);
    }

    /**
     * @dev To calculate the total token amount based on user's total invested BNB
     * @param _user - The user's wallet address
     * @return - The total amount of token
     * @notice - Access control: Public
     */
     function getTotalTokenPurchased(address _user) public view returns (uint256) {
        uint256 investAmt = participants[_user];
        return calculateTokenAmount(investAmt);
    }

    // Whitelisting Support 
    /**
     * @dev Allows campaign owner to append to the whitelisted addresses.
     * @param _addresses - Array of addresses
     * @notice - Access control: Public, OnlyCampaignOwner
     */
    function appendWhitelisted(address[] memory _addresses) external onlyFactory {
        uint256 len = _addresses.length;
        for (uint256 n=0; n<len; n++) {
            address a = _addresses[n];
            if (whitelistedMap[a] == false) {
                whitelistedMap[a] = true;
                numOfWhitelisted = numOfWhitelisted.add(1);
            }
        }
    }

    /**
     * @dev Allows campaign owner to remove from the whitelisted addresses.
     * @param _addresses - Array of addresses
     * @notice - Access control: Public, OnlyCampaignOwner
     */
    function removeWhitelisted(address[] memory _addresses) external onlyFactory {
        uint256 len = _addresses.length;
        for (uint256 n=0; n<len; n++) {
            address a = _addresses[n];
            if (whitelistedMap[a] == true) {
                whitelistedMap[a] = false;
                numOfWhitelisted = numOfWhitelisted.sub(1);
            }
        }
    }

    /**
     * @dev To check whether this address has accessibility to buy token
     * @param _address - The user's wallet address
     * @return - A bool value
     * @notice - Access control: Internal
     */
    function checkWhiteList(address _address) public view returns(bool){
        if (accessibility == Accessibility.Everyone) {
            return true;
        }
        
        // Either WhitelistedOnly or WhitelistedFirstThenEveryone
        bool ok = whitelistedMap[_address];
        if (accessibility == Accessibility.WhitelistedOnly) {
            return ok;
        } else {
            return (ok || block.timestamp >= midDate);
        }
    }
  
    // Helpers //
    /**
     * @dev To send all XYZ token to either campaign owner or burn address when campaign finishes or cancelled.
     * @param _to - The destination address
     * @param _amount - The amount to send
     * @notice - Access control: Internal
     */
    function sendTokensTo(address _to, uint256 _amount) internal {

        // Security: Can only be sent back to campaign owner or burned //
        require((_to == campaignOwner)||(_to == BURN_ADDRESS), "Can only be sent to campaign owner or burn address");

         // Burn or return UnSold token to owner 
        ERC20 ercToken = ERC20(token);
        ercToken.safeTransfer(_to, _amount);
    } 
     
    /**
     * @dev To calculate the amount of fee in BNB
     * @param _amt - The amount in BNB
     * @return - The amount of fee in BNB
     * @notice - Access control: Internal
     */
    function getFeeAmt(uint256 _amt) internal view returns (uint256) {
        return _amt.mul(feePcnt).div(1e6);
    }

    /**
     * @dev To get the fee address
     * @return - The fee address
     * @notice - Access control: Internal
     */
    function getFeeAddress() internal view returns (address) {
        IFactoryGetters fact = IFactoryGetters(factory);
        return fact.getFeeAddress();
    }

    /**
     * @dev To check whether the campaign failed (softcap not met) or cancelled
     * @return - Bool value
     * @notice - Access control: Public
     */
    function failedOrCancelled() public view returns(bool) {
        if (cancelled) return true;
        
        return (block.timestamp >= endDate) && (softCap > collectedBNB) ;
    }

    /**
     * @dev To check whether the campaign is isLive? isLive means a user can still invest in the project.
     * @return - Bool value
     * @notice - Access control: Public
     */
    function isLive() public view returns(bool) {
        if (!tokenFunded || cancelled) return false;
        if((block.timestamp < startDate)) return false;
        if((block.timestamp >= endDate)) return false;
        if((collectedBNB >= hardCap)) return false;
        return true;
    }

    /**
     * @dev Calculate amount of token receivable.
     * @param _bnbInvestment - Amount of BNB invested
     * @return - The amount of token
     * @notice - Access control: Public
     */
    function calculateTokenAmount(uint256 _bnbInvestment) public view returns(uint256) {
        return _bnbInvestment.mul(tokenSalesQty).div(hardCap);
    }
    

    /**
     * @dev Gets remaining BNB to reach hardCap.
     * @return - The amount of BNB.
     * @notice - Access control: Public
     */
    function getRemaining() public view returns (uint256){
        return (hardCap).sub(collectedBNB);
    }

    /**
     * @dev Set a campaign as cancelled.
     * @dev This can only be set before tokenReadyToClaim, finishUpSuccess, liquidityCreated .
     * @dev ie, the users can either claim tokens or get refund, but Not both.
     * @notice - Access control: Public, OnlyFactory
     */
    function setCancelled() onlyFactory external {

        // If we are in VestingMode, then we should be able to cancel even if finishUp() is called 
        if (vestInfo.enabled && block.timestamp < vestInfo.times[0])
        {
            cancelled = true;
            return;
        }

        require(!tokenReadyToClaim, "Too late, tokens are claimable");
        require(!finishUpSuccess, "Too late, finishUp called");
        require(!liquidityCreated, "Too late, Lp created");

        cancelled = true;
    }

    /**
     * @dev Calculate and return the Token amount need to be deposit by the project owner.
     * @return - The amount of token required
     * @notice - Access control: Public
     */
    function getCampaignFundInTokensRequired() public view returns(uint256) {
        return tokenSalesQty.add(lpTokenQty);
    }


    /**
     * @dev Check whether the user address has enough Launcher Tokens to participate in project.
     * @param _user - The address of user
     * @return - Bool result
     * @notice - Access control: External
     */  
    function checkQualifyingTokens(address _user) public  view returns(bool) {

        if (qualifyingTokenQty == 0) {
            return true;
        }

        IFactoryGetters fact = IFactoryGetters(factory);
        address launchToken = fact.getLauncherToken();
        
        IERC20 ercToken = IERC20(launchToken);
        uint256 balance = ercToken.balanceOf(_user);
        return (balance >= qualifyingTokenQty);
    }


    // Vesting feature support
    /**
     * @dev Setup and turn on the vesting feature
     * @param _times - Array of period of the vesting.
     * @param _percents - Array of percents release of the vesting.
     * @notice - Access control: External. onlyFactory.
     */  
    function setupVestingMode(uint256[] calldata _times, uint256[] calldata _percents) external onlyFactory {
        uint256 len = _times.length;
        require(len>0, "Invalid length");
        require(len == _percents.length, "Wrong ranges");

        // check that all percentages should add up to 100% //
        // 100% is 1e6
        uint256 totalPcnt;
        for (uint256 n=0; n<len; n++) {
            totalPcnt = totalPcnt.add(_percents[n]);
        }
        require(totalPcnt == PERCENT100, "Percentages add up should be 100%");

        vestInfo = VestingInfo({ times:_times, percents:_percents, totalVestedBnb:0, enabled:true});
    }
        

    /**
     * @dev Check whether vesting feature is enabled
     * @return - Bool result
     * @notice - Access control: External. onlyFactory.
     */  
    function isVestingEnabled() external view returns(bool) {
        return vestInfo.enabled;
    }

    /**
     * @dev Check whether a particular vesting index has elapsed and claimable
     * @return - Bool: Claimable, uint256: If started and not claimable, returns the time needed to be claimable.
     * @notice - Access control: Public.
     */  
    function isVestingClaimable(uint256 _index) public view returns(bool, uint256) {

        if ( _index >= vestInfo.times.length) {
            return (false,0);
        }

        bool claimable = (block.timestamp >= vestInfo.times[_index]);
        uint256 remainTime;
        if (!claimable) {
            remainTime = vestInfo.times[_index].sub(block.timestamp); 
        }
        return (claimable, remainTime);
    }

    /**
     * @dev Allow users to claim their vested token, according to the index of the vested period.
     * @param _index - The index of the vesting period.
     * @notice - Access control: External.
     */  
    function claimVestedTokens(uint256 _index) external {

        (bool claimable, ) = isVestingClaimable(_index);
        require(claimable, "Not claimable at this time");

        uint256 amtTotalToken = getTotalTokenPurchased(msg.sender);

        require(amtTotalToken > 0, "You have not purchased the tokens");

        bool claimed = investorsClaimMap[msg.sender][_index];
        require(!claimed, "This vest amount is already claimed");

        investorsClaimMap[msg.sender][_index] = true;
        uint256 amtTokens = vestInfo.percents[_index].mul(amtTotalToken).div(PERCENT100);
            
        ERC20(token).safeTransfer(msg.sender, amtTokens);
        emit TokenClaimed(msg.sender, block.timestamp, amtTokens);
    }

    /**
     * @dev Allow campaign owner to claim their bnb, according to the index of the vested period.
     * @param _index - The index of the vesting period.
     * @notice - Access control: External. onlyCampaignOwner.
     */  
    function claimVestedBnb(uint256 _index) external onlyCampaignOwner {

        require(finishUpSuccess, "finishUp has to be called");

        (bool claimable, ) = isVestingClaimable(_index);
        require(claimable, "Not claimable at this time");

        require(!campaignOwnerClaimMap[_index], "This vest amount is already claimed");
        campaignOwnerClaimMap[_index] = true;

        uint256 amtBnb = vestInfo.percents[_index].mul(vestInfo.totalVestedBnb).div(PERCENT100);

        (bool sentBnb, ) = campaignOwner.call{value: amtBnb}("");
        require(sentBnb, "Failed to send remain BNB to campaign owner");
    }

     /**
     * @dev To get the next vesting claim for a user.
     * @param _user - The user's address.
     * @return - int256 : the next period. -1 to indicate none found.
     * @return - uint256 : the amount of token claimable
     * @return - uint256 : time left to claim. If 0 (and next claim period is valid), it is currently claimable.
     * @notice - Access control: External. View.
     */  
    function getNextVestingClaim(address _user) external view returns(int256, uint256, uint256) {

        if (!vestInfo.enabled) {
            return (-1,0,0);
        }

        uint256 amtTotalToken = getTotalTokenPurchased(_user);
        if (amtTotalToken==0) {
            return (-1,0,0);
        }

        uint256 len = vestInfo.times.length;
        for (uint256 n=0; n<len; n++) {
            (bool claimable, uint256 time) = isVestingClaimable(n);
            uint256 amtTokens = vestInfo.percents[n].mul(amtTotalToken).div(PERCENT100);
            bool claimed = investorsClaimMap[_user][n];
           
            if (!claimable) {
                return (int256(n), amtTokens, time);
            } else {
                if (!claimed) {
                    return ( int256(n), amtTokens, 0);
                }
            }
        }
        // All claimed 
        return (-1,0,0);
    }
}

// File: contracts/Factory.sol

    

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License




contract Factory is IFactoryGetters, Ownable {
    using SafeMath for uint256;

    address private immutable launcherTokenAddress;
    
    struct CampaignInfo {
        address contractAddress;
        address owner;
    }
    // List of campaign and their project owner address. 
    // For security, only project owner can provide fund.
    mapping(uint256 => CampaignInfo) public allCampaigns;
    uint256 count;
    
    address private feeAddress;
    address private lpRouter; // Uniswap or PancakeSwap

    constructor(
        address _launcherTokenAddress,
        address _feeAddress,
        address _lpRouter
    ) public Ownable() 
    {
        launcherTokenAddress = _launcherTokenAddress;
        feeAddress = _feeAddress;
        lpRouter = _lpRouter;
    }

    /**
     * @dev Create a new campaign
     * @param _token - The token address
     * @param _subIndex - The fund raising round Id
     * @param _campaignOwner - Campaign owner address
     * @param _stats - Array of 5 uint256 values.
     * @notice - [0] Softcap. 1e18 = 1 BNB.
     * @notice - [1] Hardcap. 1e18 = 1 BNB.
     * @notice - [2] TokenSalesQty. The amount of tokens for sale. Example: 1e8 for 1 token with 8 decimals.
     * @notice - [3] feePcnt. 100% is 1e6.
     * @notice - [4] QualifyingTokenQty. Number of LAUNCH required to participate. In 1e18 per LAUNCH.
     * @param _dates - Array of 3 uint256 dates.
     * @notice - [0] Start date.
     * @notice - [1] End date.
     * @notice - [2] Mid date. For Accessibility.WhitelistedFirstThenEveryone only.
     * @param _buyLimits - Array of 2 uint256 values.
     * @notice - [0] Min amount in BNB, per purchase.
     * @notice - [1] Max accumulated amount in BNB.
     * @param _access - Everyone, Whitelisted-only, or hybrid.
     * @param _liquidity - Array of 3 uint256 values.
     * @notice - [0] BNB amount to use (from token sales) to be used to provide LP.
     * @notice - [1] Token amount to be used to provide LP.
     * @notice - [2] LockDuration of the LP tokens.
     * @param _burnUnSold - Indicate to burn un-sold tokens or not. For successful campaign only.
     * @return campaignAddress - The address of the new campaign smart contract created
     * @notice - Access control: Public, OnlyOwner
     */

    function createCampaign(
        address _token,
        uint256 _subIndex,             
        address _campaignOwner,     
        uint256[5] calldata _stats,  
        uint256[3] calldata _dates, 
        uint256[2] calldata _buyLimits,    
        Campaign.Accessibility _access,  
        uint256[3] calldata _liquidity, 
        bool _burnUnSold  
    ) external onlyOwner returns (address campaignAddress)
    {
        require(_stats[0] < _stats[1],"Soft cap can't be higher than hard cap" );
        require(_stats[2] > 0,"Token for sales can't be 0");
        require(_stats[3] <= 10e6, "Invalid fees value");
        require(_dates[0] < _dates[1] ,"Start date can't be higher than end date" );
        require(block.timestamp < _dates[1] ,"End date must be higher than current date ");
        require(_buyLimits[1] > 0, "Max allowed can't be 0" );
        require(_buyLimits[0] <= _buyLimits[1],"Min limit can't be greater than max." );

        if (_liquidity[0] > 0) { // Liquidity provision check //
            require(_liquidity[0] <= _stats[0], "BNB for liquidity cannot be greater than softcap");
            require(_liquidity[1] > 0, "Token for liquidity cannot be 0");
        } else {
            require(_liquidity[1] == 0, "Both liquidity BNB and token must be 0");
        }

        // Boundary check: After deducting for fee, the Softcap amt left is enough to create the LP
        uint256 feeAmt = _stats[0].mul(_stats[3]).div(1e6);
        require(_stats[0].sub(feeAmt) >= _liquidity[0], "Liquidity BNB amount is too high");

        if (_access == Campaign.Accessibility.WhitelistedFirstThenEveryone) {
            require((_dates[2] > _dates[0]) && (_dates[2] < _dates[1]) , "Invalid dates setup");
        }
        
        bytes memory bytecode = type(Campaign).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, _subIndex, msg.sender));
        assembly {
            campaignAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        Campaign(campaignAddress).initialize 
        (
            _token,
            _campaignOwner,
            _stats,
            _dates,
            _buyLimits,
            _access,
            _liquidity,
            _burnUnSold
        );
        
        allCampaigns[count] = CampaignInfo(campaignAddress, _campaignOwner);
        count = count.add(1);
        
        return campaignAddress;
    }

    /**
     * @dev Cancel a campaign
     * @param _campaignID - The campaign ID
     * @notice - Access control: External, OnlyOwner
     */    
    function cancelCampaign(uint256 _campaignID) external onlyOwner {

        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");
        
        Campaign camp = Campaign(info.contractAddress);
        camp.setCancelled();
    }


    /**
     * @dev Append whitelisted addresses to a campaign
     * @param _campaignID - The campaign ID
     * @param _addresses - Array of addresses
     * @notice - Access control: External, OnlyOwner
     */   
    function appendWhitelisted(uint256 _campaignID, address[] memory _addresses) external onlyOwner {
        
        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");
        
        Campaign camp = Campaign(info.contractAddress);
        camp.appendWhitelisted(_addresses);
    }

    /**
     * @dev Remove whitelisted addresses from a campaign
     * @param _campaignID - The campaign ID
     * @param _addresses - Array of addresses
     * @notice - Access control: External, OnlyOwner
     */  
    function removeWhitelisted(uint256 _campaignID, address[] memory _addresses) external onlyOwner {

        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");
        
        Campaign camp = Campaign(info.contractAddress);
        camp.removeWhitelisted(_addresses);
    }

    /**
     * @dev Allow Factory owner to call this to set the flag to
     * @dev enable token claiming.
     * @dev This is useful when 1 project has multiple campaigns that need
     * @dev to sync up the timing of token claiming After LP provision.
     * @notice - Access control: External,  onlyFactory
     */
    function setTokenClaimable(uint256 _campaignID) external onlyOwner {

        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");
        
        Campaign camp = Campaign(info.contractAddress);
        camp.setTokenClaimable();
    }


    /**
     * @dev Add liquidity and lock it up. Called after a campaign has ended successfully.
     * @notice - Access control: External. OnlyOwner.
     */
    function addAndLockLP(uint256 _campaignID) external onlyOwner {
        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");
        
        Campaign camp = Campaign(info.contractAddress);
        camp.addAndLockLP();
    }

    /**
     * @dev Recover Unspent LP for a campaign
     * @param _campaignID - The campaign ID
     * @notice - Access control: External, OnlyOwner
     */    
    function recoverUnspentLp(uint256 _campaignID, address _campaignOwnerForCheck) external onlyOwner {

        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");
        require(info.owner == _campaignOwnerForCheck, "Invalid campaign owner"); // additional check
        
        Campaign camp = Campaign(info.contractAddress);
        camp.recoverUnspentLp();
    }

    /**
     * @dev Setup and turn on the vesting feature
     * @param _campaignID - The campaign ID
     * @param _times - Array of period of the vesting.
     * @param _percents - Array of percents release of the vesting.
     * @notice - Access control: External. onlyFactory.
     */  
    function setupVestingMode(uint256 _campaignID, uint256[] calldata _times, uint256[] calldata _percents) external onlyOwner {

        require(_campaignID < count, "Invalid ID");

        CampaignInfo memory info = allCampaigns[_campaignID];
        require(info.contractAddress != address(0), "Invalid Campaign contract");

        Campaign camp = Campaign(info.contractAddress);
        camp.setupVestingMode(_times, _percents);
    }


    // IFactoryGetters
    /**
     * @dev Get the LP router address
     * @return - Return the LP router address
     * @notice - Access control: External
     */  
    function getLpRouter() external override view returns(address) {
        return lpRouter;
    }

    /**
     * @dev Get the fee address
     * @return - Return the fee address
     * @notice - Access control: External
     */  
    function getFeeAddress() external override view returns(address) {
        return feeAddress;
    }

    /**
     * @dev Get the launcher token address
     * @return - Return the address
     * @notice - Access control: External
     */ 
    function getLauncherToken() external override view returns(address) {
        return launcherTokenAddress;
    }
}