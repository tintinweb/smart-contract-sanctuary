/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED


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

//A Jar is a contract that users deposit funds into.
//Jar contracts are paired with a strategy contract that interacts with the pool being farmed.
interface IJar {
    function token() external view returns (address);

    function getRatio() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function depositAll() external;

    function deposit(uint256) external;

    //function depositFor(address user, uint256 amount) external;

    function withdrawAll() external;

    //function withdraw(uint256) external;

    function earn() external;

    function strategy() external view returns (address);

    //function decimals() external view returns (uint8);

    //function getLastTimeRestaked(address _address) external view returns (uint256);

    //function notifyReward(address _reward, uint256 _amount) external;

    //function getPendingReward(address _user) external view returns (uint256);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
interface IUniswapRouterV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}


abstract contract BaseStrategy is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public lastHarvestTime = 0;

    // Tokens
    address public want; //The LP token, Harvest calls this "rewardToken"
    address public constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; //weth for Matic
    address public harvestedToken; //The token we harvest, will add support for multiple tokens in v2

    // User accounts
    address public strategist; //The address the performance fee is sent to
    address public jar;

    // Dex
    address public currentRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Quickswap router

    constructor(
        address _want,
        address _strategist,
        address _harvestedToken,
        address _currentRouter
    ) public {
        require(_want != address(0));
        require(_strategist != address(0));

        want = _want;
        strategist = _strategist;
        harvestedToken = _harvestedToken;
        currentRouter = _currentRouter;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function getHarvestable() external virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // **** Setters **** //

    function setJar(address _jar) external onlyOwner {
        require(jar == address(0), "jar already set");
        jar = _jar;
        emit SetJar(_jar);
    }

    function setStrategist(address _strategist) external onlyOwner {
        strategist = _strategist;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == jar, "!jar");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(jar, _amount);
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance)
    {
        require(msg.sender == jar, "!jar");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(jar, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        // Swap with uniswap
        IERC20(_from).safeApprove(currentRouter, 0);
        IERC20(_from).safeApprove(currentRouter, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(currentRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswapWithPath(
        address[] memory path,
        uint256 _amount
    ) internal {
        require(path[1] != address(0));

        // Swap with uniswap
        IERC20(path[0]).safeApprove(currentRouter, 0);
        IERC20(path[0]).safeApprove(currentRouter, _amount);

        IUniswapRouterV2(currentRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswapWithPathForFeeOnTransferTokens(
        address[] memory path,
        uint256 _amount
    ) internal {
        require(path[1] != address(0));

        // Swap with uniswap
        IERC20(path[0]).safeApprove(currentRouter, 0);
        IERC20(path[0]).safeApprove(currentRouter, _amount);

        IUniswapRouterV2(currentRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _want = IERC20(want).balanceOf(address(this));

        if (_want > 0) {
            deposit();
        }
        lastHarvestTime = now;
    }

    // **** Events **** //
    event SetJar(address indexed jar);
}
interface IStakingRewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function exit() external;

    function getReward() external;

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function notifyRewardAmount(uint256 reward) external;

    function periodFinish() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewards(address) external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsDuration() external view returns (uint256);

    function rewardsToken() external view returns (address);

    function stake(uint256 amount) external;

    function stakeLocked(uint256 amount, uint256 secs) external;

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function withdrawLocked(bytes32 kek_id) external;
}

// Base contract for SNX Staking rewards contract interfaces

abstract contract BaseStrategyStakingRewards is BaseStrategy {
    address public rewards;

    // **** Getters ****
    constructor(
        address _rewards,
        address _want,
        address _strategist,
        address _harvestedToken,
        address _currentRouter
    )
        public
        BaseStrategy(_want, _strategist, _harvestedToken, _currentRouter)
    {
        rewards = _rewards;
    }

    function balanceOfPool() public override view returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external override view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }

    function _notifyJar(uint256 _amount) internal virtual;

    /* **** Mutative functions **** */

    function _getReward() internal {
        IStakingRewards(rewards).getReward();
    }

    // **** Admin functions ****

    function salvage(address recipient, address token, uint256 amount) public onlyOwner {
        require(token != want, "cannot salvage");
        IERC20(token).safeTransfer(recipient, amount);
    }
}

interface IERCFund {
    function feeShareEnabled() external view returns (bool);

    function depositToFeeDistributor(address token, uint256 amount) external;

    function notifyFeeDistribution(address token) external;

    function getFee() external view returns (uint256);

    function recover(address token) external;
}

//Vaults are jars that emit ADDY rewards.
interface IVault is IJar {

    function getPendingReward(address _user) external view returns (uint256);

    function getLastDepositTime(address _user) external view returns (uint256);

    function getTokensStaked(address _user) external view returns (uint256);

    function totalShares() external view returns (uint256);
}

//A normal vault is a vault where the strategy contract notifies the vault contract about the profit it generated when harvesting. 
interface IGenericVault is IVault {
    
    //Strategy calls notifyReward to let the vault know that it earned a certain amount of profit (the performance fee) for gov token stakers
    function notifyReward(address _reward, uint256 _amount) external;
}

//For A/B token pairs, where I have to convert the harvested token to A (ETH/MATIC/USDC/etc) and then sell 1/2 of A for B
abstract contract BaseStrategyOtherPair is BaseStrategyStakingRewards {

    // Addresses for MATIC
    //address public quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public tokenA;
    address public tokenB;
    //address public quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Quickswap router
    
    uint256 public constant keepMax = 10000;

    // Uniswap swap paths
    address[] public reward_a_path;
    address[] public a_b_path;

    constructor(
        address _rewards,
        address _want,
        address _tokenA,
        address _tokenB,
        address _harvestedToken,
        address _strategist,
        address _router
    )
        public
        BaseStrategyStakingRewards(
            _rewards,
            _want,
            _strategist,
            _harvestedToken,
            _router
        )
    {
        tokenA = _tokenA;
        tokenB = _tokenB;

        reward_a_path = new address[](2);
        reward_a_path[0] = _harvestedToken;
        reward_a_path[1] = _tokenA;

        a_b_path = new address[](2);
        a_b_path[0] = _tokenA;
        a_b_path[1] = _tokenB;
    }

    // **** State Mutations ****

    function harvest() public override {
        //prevent unauthorized smart contracts from calling harvest()
        require(msg.sender == tx.origin || msg.sender == owner() || msg.sender == strategist, "not authorized");
        
        _getReward();

        uint256 _harvested_balance = IERC20(harvestedToken).balanceOf(address(this));

        //Distribute fee and swap Quick for tokenA
        if (_harvested_balance > 0) {
            uint256 feeAmount = _harvested_balance.mul(IERCFund(strategist).getFee()).div(keepMax);
            uint256 afterFeeAmount = _harvested_balance.sub(feeAmount);
            _notifyJar(feeAmount);

            IERC20(harvestedToken).safeTransfer(strategist, feeAmount);
            _swapUniswapWithPath(reward_a_path, afterFeeAmount);
        }

        //Swap 1/2 of tokenA for tokenB
        uint256 _balanceA = IERC20(tokenA).balanceOf(address(this));
        if (_balanceA > 0) {
            _swapUniswapWithPath(a_b_path, _balanceA.div(2));
        }

        //Add liquidity
        uint256 aBalance = IERC20(tokenA).balanceOf(address(this));
        uint256 bBalance = IERC20(tokenB).balanceOf(address(this));
        if (aBalance > 0 && bBalance > 0) {
            IERC20(tokenA).safeApprove(currentRouter, 0);
            IERC20(tokenA).safeApprove(currentRouter, aBalance);
            IERC20(tokenB).safeApprove(currentRouter, 0);
            IERC20(tokenB).safeApprove(currentRouter, bBalance);

            IUniswapRouterV2(currentRouter).addLiquidity(
                tokenA, tokenB,
                aBalance, bBalance,
                0, 0,
                address(this),
                now + 60
            );
        }

        // Stake the LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    function _notifyJar(uint256 _amount) internal override {
        IGenericVault(jar).notifyReward(harvestedToken, _amount);
    }
}


contract StrategyOtherPair is BaseStrategyOtherPair {

    address public QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Quickswap router
    string private pair_name;

    constructor(address rewards, address lp, address tokenA, address tokenB, address strategist, string memory _pair_name)
        public
        BaseStrategyOtherPair(
            rewards,
            lp,
            tokenA,
            tokenB,
            QUICK,
            strategist,
            QUICKSWAP_ROUTER
        )
    {
        pair_name = _pair_name;
    }

    // **** Views ****

    function pairName() external view returns (string memory) {
        return pair_name;
    }
}

interface IStrategy {
    function harvestedToken() external view returns (address);

    function lastHarvestTime() external returns (uint256);

    function rewards() external view returns (address);

    function gauge() external view returns (address);

    function want() external view returns (address);

    function treasury() external view returns (address);

    function deposit() external;

    function depositLocked(uint256 _secs) external;

    function withdrawForSwap(uint256) external returns (uint256);

    function withdraw(address) external;

    function withdraw(uint256) external;

    function withdrawLocked(bytes32 kek_id) external returns (uint256 balance);

    function skim() external;

    function migrate() external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function getHarvestable() external view returns (uint256);

    function pairName() external view returns (string memory);

    function harvest() external;

    function setJar(address _jar) external;

    function migrate(address newStakingContract) external;

    function getLastTimeMigrated() external view returns (uint256);

    function execute(address _target, bytes calldata _data)
        external
        payable
        returns (bytes memory response);

    function execute(bytes calldata _data)
        external
        payable
        returns (bytes memory response);
}
interface IMinter {
    function isMinter(address) view external returns(bool);
    function amountAddyToMint(uint256 ethProfit) view external returns(uint256);
    function mintFor(address user, address asset, uint256 amount) external;

    function addyPerProfitEth() view external returns(uint256);

    function setMinter(address minter, bool canMint) external;
}// Based on https://github.com/iearn-finance/vaults/blob/master/contracts/vaults/yVault.sol


abstract contract VaultBase is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Info of each user
    struct UserInfo {
        uint256 shares; // User shares
        uint256 rewardDebt; // Reward debt (in terms of QUICK)
        uint256 lastDepositTime;
        uint256 tokensStaked; // Number of tokens staked, only used to calculate profit on the frontend (different than shares)
    }

    uint256 public constant keepMax = 10000;

    /* ========== STATE VARIABLES ========== */

    // Info of each user
    mapping (address => UserInfo) public userInfo;

    // The total amount of pending rewards available for stakers to claim
    uint256 public totalPendingReward;
    // Accumulated rewards per share, times 1e12.
    uint256 public accRewardPerShare;
    // The total # of shares issued
    uint256 public totalShares;
    // Withdrawing before this much time has passed will have a withdrawal penalty
    uint256 public withdrawPenaltyTime = 3 days;
    // Withdrawal penalty, 100 = 1%
    uint256 public withdrawPenalty = 50;

    // Certain vaults will give up to 10x ADDY rewards
    // Additional usecase for ADDY: lock it to boost the yield of a certain vault
    uint256 private rewardMultiplier = 1000;
    uint256 private constant MULTIPLIER_BASE = 1000;
    uint256 private constant MULTIPLIER_MAX = 10000;

    IERC20 public token;
    address public strategy;
    IMinter internal minter;
    address public ercFund;

    constructor(IStrategy _strategy, address _minter, address _ercFund)
        public
    {
        require(address(_strategy) != address(0));
        token = IERC20(_strategy.want());
        strategy = address(_strategy);
        minter = IMinter(_minter);
        ercFund = _ercFund;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // 1000 = 1x multiplier
    function getRewardMultiplier() public view returns (uint256) {
        return rewardMultiplier;
    }

    function applyRewardMultiplier(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(rewardMultiplier).div(MULTIPLIER_BASE);
    }

    function getRatio() public view returns (uint256) {
        return balance().mul(1e18).div(totalShares);
    }

    function balance() public view returns (uint256) {
        return
            token.balanceOf(address(this)).add(
                IStrategy(strategy).balanceOf()
            );
    }

    function balanceOf(address _user) public view returns (uint256) {
        return userInfo[_user].shares;
    }

    function getPendingReward(address _user) public view returns (uint256) {
        return userInfo[_user].shares.mul(accRewardPerShare).div(1e12).sub(userInfo[_user].rewardDebt);
    }

    function getLastDepositTime(address _user) public view returns (uint256) {
        return userInfo[_user].lastDepositTime;
    }

    function getTokensStaked(address _user) public view returns (uint256) {
        return userInfo[_user].tokensStaked;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        require(msg.sender == tx.origin, "no contracts");
        _claimReward(msg.sender);

        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);

        UserInfo storage user = userInfo[msg.sender];
        user.shares = user.shares.add(shares);
        user.rewardDebt = user.shares.mul(accRewardPerShare).div(1e12);
        user.lastDepositTime = now;
        user.tokensStaked = user.tokensStaked.add(_amount);

        earn(); 
        emit Deposited(msg.sender, _amount);
    }
 
    function earn() internal {
        uint256 _bal = token.balanceOf(address(this));
        token.safeTransfer(strategy, _bal);
        IStrategy(strategy).deposit();
    }

    // Withdraw all tokens and claim rewards.
    function withdrawAll() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _shares = user.shares;
        uint256 r = (balance().mul(_shares)).div(totalShares);

        _claimReward(msg.sender);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        totalShares = totalShares.sub(_shares);

        user.shares = user.shares.sub(_shares);
        user.rewardDebt = user.shares.mul(accRewardPerShare).div(1e12);
        user.tokensStaked = 0;
        // Deduct early withdrawal fee if applicable
        if(user.lastDepositTime.add(withdrawPenaltyTime) >= now) {
            uint256 earlyWithdrawalFee = r.mul(withdrawPenalty).div(keepMax);
            r = r.sub(earlyWithdrawalFee);
            token.safeTransfer(ercFund, earlyWithdrawalFee);
        }

        token.safeTransfer(msg.sender, r);
        emit Withdrawn(msg.sender, r);
    }

    // Withdraw all tokens without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _shares = user.shares;
        uint256 r = (balance().mul(_shares)).div(totalShares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        if(_shares <= totalShares) {
            totalShares = totalShares.sub(_shares);
        }
        else {
            totalShares = 0;
        }
        user.shares = 0;
        user.rewardDebt = 0;
        user.tokensStaked = 0;
        // Deduct early withdrawal fee if applicable
        if(user.lastDepositTime.add(withdrawPenaltyTime) >= now) {
            uint256 earlyWithdrawalFee = r.mul(withdrawPenalty).div(keepMax);
            r = r.sub(earlyWithdrawalFee);
            token.safeTransfer(ercFund, earlyWithdrawalFee);
        }

        token.safeTransfer(msg.sender, r);
        emit Withdrawn(msg.sender, r);
    }
    
    function claim() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares > 0, "no stake");

        _claimReward(msg.sender);

        user.rewardDebt = user.shares.mul(accRewardPerShare).div(1e12);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // Handles claiming the user's pending rewards
    function _claimReward(address _user) internal virtual;

    /* ========== RESTRICTED FUNCTIONS ========== */

    //Vault deployer also needs to register the vault with the new minter
    function setMinter(IMinter newMinter) public onlyOwner {
        minter = newMinter;
    }

    function setWithdrawPenaltyTime(uint256 _withdrawPenaltyTime) public onlyOwner {
        require(_withdrawPenaltyTime <= 30 days, "delay too high");
        withdrawPenaltyTime = _withdrawPenaltyTime;
    }

    function setWithdrawPenalty(uint256 _withdrawPenalty) public onlyOwner {
        require(_withdrawPenalty <= 500, "penalty too high");
        withdrawPenalty = _withdrawPenalty;
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) public onlyOwner {
        require(_rewardMultiplier <= MULTIPLIER_MAX, "multiplier too high");
        rewardMultiplier = _rewardMultiplier;
    }

    /* ========== EVENTS ========== */

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardAdded(address reward, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
}


contract GenericVault is VaultBase {

    constructor(IStrategy _strategy, address _minter, address _ercFund) 
        public
        VaultBase(_strategy, _minter, _ercFund)
    {
        
    }

    // Handles claiming the user's pending rewards
    function _claimReward(address _user) internal override {
        UserInfo storage user = userInfo[_user];
        if (user.shares > 0) {
            uint256 pendingReward = user.shares.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingReward > 0) {
                totalPendingReward = totalPendingReward.sub(pendingReward);
                
                //Apply reward multiplier to the pendingReward that the minter will mint for
                pendingReward = applyRewardMultiplier(pendingReward);
                //Minter will mint to MultiFeeDistribution and then stake the minted tokens for the user
                minter.mintFor(_user, IStrategy(strategy).harvestedToken(), pendingReward);
                emit Claimed(_user, pendingReward);
            }
        }
    }

    //Strategy calls notifyReward to let the vault know that it earned a certain amount of profit (the performance fee) for gov token stakers
    function notifyReward(address _reward, uint256 _amount) public {
        require(msg.sender == strategy);
        if(_amount == 0) {
            return;
        }

        totalPendingReward = totalPendingReward.add(_amount);
        accRewardPerShare = accRewardPerShare.add(_amount.mul(1e12).div(totalShares)); //shouldn't be adding reward if totalShares == 0 anyway

        emit RewardAdded(_reward, _amount);
    }
    
    //No user tokens should be in this contract
    function salvage(address _recipient, address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(_recipient, _amount);
    }
}


contract ProxyMinter is Ownable {

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;
    address public deployer;
    address public minter;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _minter)
        public
    {
        minter = _minter;
    }
    
    /* ========== MODIFIERS ========== */

    modifier onlyMinter {
        require(isMinter(msg.sender) == true, "AddyMinter: caller is not the minter");
        _;
    }

    function mintFor(address user, address asset, uint256 amount) external onlyMinter {
        IMinter(minter).mintFor(user, asset, amount);
    }
    
    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    function amountAddyToMint(uint256 ethProfit) public view returns (uint256) {
        return IMinter(minter).amountAddyToMint(ethProfit);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDeployer(address _deployer) public onlyOwner {
        require(deployer == address(0), "already set");
        deployer = _deployer;
    }
    
    function setMinter(address _minter, bool canMint) external {
        require(deployer == msg.sender, "not deployer");

        if (canMint) {
            _minters[_minter] = canMint;
        } else {
            delete _minters[_minter];
        }
    }
    
    function disableMinter(address _minter) external onlyOwner {
        _minters[_minter] = false;
    }
}


//Deploys strategies for TokenA/TokenB pairs
//Make sure that a pair for rewardToken/TokenA exists
contract StrategyDeployer is Ownable {

    address public FUND = 0xC9E908D24f13c18A0ab803A4ACF469B37c1761e8;
    address MULTI_HARVEST = 0x3355743Db830Ed30FF4089DB8b18DEeb683F8546;
    address public proxy_minter;

    constructor() public {
        proxy_minter = address(new ProxyMinter(0xAAE758A2dB4204E1334236Acd6E6E73035704921));
        ProxyMinter(proxy_minter).setDeployer(address(this));
        Ownable(proxy_minter).transferOwnership(msg.sender);
    }

    function deploy(address rewards, address lp, address tokenA, address tokenB, string memory _pair_name) public onlyOwner {
        address strategy = address(new StrategyOtherPair(rewards, lp, tokenA, tokenB, FUND, _pair_name));
        address jar = address(new GenericVault(IStrategy(strategy), proxy_minter, FUND));
        StrategyOtherPair(strategy).setJar(jar);
        IMinter(proxy_minter).setMinter(jar, true);
        Ownable(strategy).transferOwnership(MULTI_HARVEST);
        Ownable(jar).transferOwnership(msg.sender);

        emit Deployed(strategy, jar);
    }

    event Deployed(address indexed strategy, address indexed jar);
}