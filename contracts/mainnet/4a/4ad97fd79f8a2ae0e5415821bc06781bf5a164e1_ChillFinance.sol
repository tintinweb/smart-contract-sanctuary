/**
 *Submitted for verification at Etherscan.io on 2020-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    using Address for address;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    // fallback() external payable {
    //     deposit();
    // }

    // function deposit() public payable {
    //     _balances[msg.sender] += msg.value;
    //     Deposit(msg.sender, msg.value);
    // }

    // function withdraw(uint wad) public {
    //     require(_balances[msg.sender] >= wad);
    //     _balances[msg.sender] -= wad;
    //     msg.sender.transfer(wad);
    //     Withdrawal(msg.sender, wad);
    // }

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// CHILL with Governance.
contract ChillToken is ERC20("CHILLSWAP", "CHILL"), Ownable {

    IUniswapV2Router02 public iUniswapV2Router02;
    IUniswapV2Factory public iUniswapV2Factory;
    IWETH public iWeth;
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    
      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // fallback() external payable {
    // }

    constructor(
        address _uniswapRouter, 
        address _uniswapFactory, 
        address _wethAddress
    ) public  {
        iUniswapV2Factory = IUniswapV2Factory(_uniswapFactory);
        iUniswapV2Router02 = IUniswapV2Router02(_uniswapRouter);
        iWeth = IWETH(_wethAddress);
        mint(msg.sender, 40000e18);
    }

    function createPair(address tokenA, address tokenB) public {
        iUniswapV2Factory.createPair(tokenA, tokenB);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @notice Burn `_amount` token to `_to`. 
    function burn(address _to, uint256 _amount) public onlyOwner {
        _burn(_to, _amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CHILL::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CHILL::delegateBySig: invalid nonce");
        require(now <= expiry, "CHILL::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CHILL::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CHILLs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CHILL::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
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

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IUniStakingRewards {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
    function balanceOf(address account) external view returns (uint256);
}

library PairValue {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    function countEthAmount(address _countPair, uint256 _liquiditybalance) internal view returns(uint256) {
        address countToken0 = IUniswapV2Pair(_countPair).token0();
        (uint112 countReserves0, uint112 countReserves1, ) = IUniswapV2Pair(_countPair).getReserves();
        uint256 countTotalSupply = IERC20(_countPair).totalSupply();
        uint256 ethAmount;
        uint256 tokenbalance;

        if(countTotalSupply > 0) {
            if(countToken0 != 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
                tokenbalance = _liquiditybalance.mul(countReserves0).div(countTotalSupply);
                ethAmount = UniswapV2Library.getAmountOut(tokenbalance, countReserves0, countReserves1);
            } else {
                tokenbalance = _liquiditybalance.mul(countReserves1).div(countTotalSupply);
                ethAmount = UniswapV2Library.getAmountOut(tokenbalance, countReserves1, countReserves0);
            }
        } else {
            return 0;
        }
        return countUsdtAmount(ethAmount);
    }

    function countUsdtAmount(uint256 ethAmount) internal view returns(uint256) {
        address _stablePair = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
        address usdttoken0 = IUniswapV2Pair(_stablePair).token0();
        (uint112 stableReserves0, uint112 stableReserves1, ) = IUniswapV2Pair(_stablePair).getReserves();

        uint256 stableOutAmount;
        if (usdttoken0 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) { // WETH Mainnet
            stableOutAmount = UniswapV2Library.getAmountOut(1e18, stableReserves0, stableReserves1);
        } else {
            stableOutAmount = UniswapV2Library.getAmountOut(1e18, stableReserves1, stableReserves0);
        }
        uint256 totalAmount = ((ethAmount.div(1e18)).mul(stableOutAmount.div(1e6))).mul(2);
        return totalAmount;
    }
}

interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}

contract ChillFinance is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 startedBlock;
    }
    
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accChillPerShare;
        uint256 totalPoolBalance;
        address nirvanaRewardAddress;
        uint256 nirvanaFee;
    }

    ChillToken public chill;
    address public devaddr;
    uint256 public DEV_FEE = 0;
    uint256 public DEV_TAX_FEE = 20;
    PoolInfo[] public poolInfo;
    uint256 public bonusEndBlock;
    uint256 public constant BONUS_MULTIPLIER = 10;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlockOfChill;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => address[]) public poolUsers;
    mapping (uint256 => mapping(address => bool)) public isUserExist;
    mapping (address => bool) public stakingUniPools;
    mapping (address => address) public uniRewardAddresses;
    mapping (uint256 => bool) public isCheckInitialPeriod;
    mapping (address => bool) private distributors;
    IMigratorChef public migrator;

    uint256 initialPeriod;
    uint256 public initialAmt = 20000;
    uint256[] public blockPerPhase;
    uint256[] public blockMilestone;

    uint256 public phase1time;
    uint256 public phase2time;
    uint256 public phase3time;
    uint256 public phase4time;
    uint256 public phase5time;

    uint256 burnFlag = 0;
    uint256 lastBurnedPhase1 = 0;
    uint256 lastBurnedPhase2 = 0;
    uint256 lastTimeOfBurn;
    uint256 totalBurnedAmount;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier isDistributor(address _isDistributor) {
        require(distributors[_isDistributor]);
        _;
    }

    constructor(
        ChillToken _chill,
        address _devaddr, 
        uint256 _startBlockOfChill
    ) public {
        chill = _chill;
        devaddr = _devaddr;
        
        startBlockOfChill = block.number.add(_startBlockOfChill);
        bonusEndBlock = block.number;
        initialPeriod = block.number.add(99999); 
        
        blockPerPhase.push(75e18);
        blockPerPhase.push(100e18);
        blockPerPhase.push(50e18);
        blockPerPhase.push(25e18);
        blockPerPhase.push(0);

        blockMilestone.push(2201); // 2201
        blockMilestone.push(4401); // 4401
        blockMilestone.push(6600); // 6600
        blockMilestone.push(8798); // 8798
        blockMilestone.push(10997); // 10997

        phase1time = block.number.add(92338); // 14 days (14*24*60*60)/15 92338
        phase2time = block.number.add(290201); // 44 - 14 = 30 days (44*24*60*60)/15 290201
        phase3time = block.number.add(488069); // 74 - 44 = 30 days (74*24*60*60)/15 488069
        phase4time = block.number.add(883804); // 134 - 74 = 60 days (134*24*60*60)/15 883804
        phase5time = block.number.add(0); // 134 - 74 = 60 days (134*24*60*60)/15
        lastTimeOfBurn = block.timestamp.add(1 days);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function userPoollength(uint256 _pid) external view returns (uint256) {
        return poolUsers[_pid].length;
    }

    // get a participant users in a specific pool
    function getPoolUsers(uint256 _pid) public view returns(address[] memory) {
        return poolUsers[_pid];
    }

    // Add Function to give support new uniswap lp pool by only owner
    // for allocpoint will be 100 and if you want to generate more chill for specific pool then you need to increase allocpoint
    // like for, 1x=>100, 2x=>200, 3x=>300 etc.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _lastRewardBlock = block.number > startBlockOfChill ? block.number : startBlockOfChill;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: _lastRewardBlock,
            accChillPerShare: 0,
            totalPoolBalance: 0,
            nirvanaRewardAddress: address(0),
            nirvanaFee: 0
        }));
    }
    
    // increase alloc point for specific pool
    function set(uint256 _pid, uint256 _allocPoint, uint256 _nirvanaFee, address _nirvanaRewardAddress, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].nirvanaRewardAddress = _nirvanaRewardAddress;
        poolInfo[_pid].nirvanaFee = _nirvanaFee;
    }
    
    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(address _migrator) public onlyOwner {
        migrator = IMigratorChef(_migrator);
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }
    
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    // user can deposit lp for specific pool
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (isCheckInitialPeriod[_pid]) {
            if (block.number <= initialPeriod) {
                // calculate id lp token amount less than $20000 and only applicable to eth pair
                require(PairValue.countEthAmount(address(pool.lpToken), _amount) <= initialAmt, "Amount must be less than or equal to 20000 dollars.");
            } else {
                isCheckInitialPeriod[_pid] = false;
            }
        }
        
        if (user.startedBlock <= 0) {
            user.startedBlock = block.number;
        }
        
        updatePool(_pid);
        if (user.amount > 0) {
            userRewardAndTaxes(pool, user);
        }

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        pool.totalPoolBalance = pool.totalPoolBalance.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accChillPerShare).div(1e12);
        user.startedBlock = block.number;

        if (stakingUniPools[address(pool.lpToken)] && _amount > 0) {
            stakeInUni(_amount, address(pool.lpToken), uniRewardAddresses[address(pool.lpToken)]);
        }

        if (!isUserExist[_pid][msg.sender]) {
            isUserExist[_pid][msg.sender] = true;
            poolUsers[_pid].push(msg.sender);
        }
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    // it will be call if spicific pool uniswap uni pool supported in chill finance
    // and if you want to support uniswap pool then you need to add in addStakeUniPool
    function stakeInUni(uint256 amount, address v2address, address _stakeAddress) private {
        IERC20(v2address).approve(address(_stakeAddress), amount);
        IUniStakingRewards(_stakeAddress).stake(amount);
    }

    // user can withdraw their lp token from specific pool 
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw is not valid");
        
        if (user.startedBlock <= 0) {
            user.startedBlock = block.number;
        }
        
        if (stakingUniPools[address(pool.lpToken)]  && _amount > 0) {
            withdrawUni(uniRewardAddresses[address(pool.lpToken)], _amount);
        }

        updatePool(_pid);
        userRewardAndTaxes(pool, user);

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accChillPerShare).div(1e12);
        user.startedBlock = block.number;
        pool.totalPoolBalance = pool.totalPoolBalance.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // withdraw lp token from uniswap uni farm pool  
    function withdrawUni(address _stakeAddress, uint256 _amount) private {
        IUniStakingRewards(_stakeAddress).withdraw(_amount);
    }
    
    // Reward will genrate in update pool function and call will be happen internally by deposit and withdraw function
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalPoolBalance == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 chillReward;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (block.number <= phase1time) {
            chillReward = multiplier.mul(blockPerPhase[0]).mul(pool.allocPoint).div(totalAllocPoint);
        } else if (block.number <= phase2time) {
            chillReward = multiplier.mul(blockPerPhase[1]).mul(pool.allocPoint).div(totalAllocPoint);
        } else if (block.number <= phase3time) {
            chillReward = multiplier.mul(blockPerPhase[2]).mul(pool.allocPoint).div(totalAllocPoint);
        } else if (block.number <= phase4time) {
            chillReward = multiplier.mul(blockPerPhase[3]).mul(pool.allocPoint).div(totalAllocPoint);
        } else {
            chillReward = multiplier.mul(blockPerPhase[4]).mul(pool.allocPoint).div(totalAllocPoint);
        }
        
        if (chillReward > 0) {
            if (DEV_FEE > 0) {
                chill.mint(devaddr, chillReward.mul(DEV_FEE).div(100));
            }
            chill.mint(address(this), chillReward);
        }
        pool.accChillPerShare = pool.accChillPerShare.add(chillReward.mul(1e12).div(pool.totalPoolBalance));
        pool.lastRewardBlock = block.number;
    }
    
    // User's extra reward and taxes will be handle in this internal funation
    function userRewardAndTaxes(PoolInfo storage pool, UserInfo storage user) internal {
        uint256 pending =  user.amount.mul(pool.accChillPerShare).div(1e12).sub(user.rewardDebt);
        uint256 tax = deductTaxByBlock(getCrossMultiplier(user.startedBlock, block.number));
        if (tax > 0) {
            uint256 pendingTax = pending.mul(tax).div(100);
            uint256 devReward = pendingTax.mul(DEV_TAX_FEE).div(100);
            safeChillTransfer(devaddr, devReward);
            if (pool.nirvanaFee > 0) {
                uint256 nirvanaReward = pendingTax.mul(pool.nirvanaFee).div(100);
                safeChillTransfer(pool.nirvanaRewardAddress, nirvanaReward);
                safeChillTransfer(msg.sender, pending.sub(devReward).sub(nirvanaReward));
                chill.burn(msg.sender, pendingTax.sub(devReward).sub(nirvanaReward));
                lastDayBurned(pendingTax.sub(devReward).sub(nirvanaReward));
            } else {
                safeChillTransfer(msg.sender, pending.sub(devReward));
                chill.burn(msg.sender, pendingTax.sub(devReward));
                lastDayBurned(pendingTax.sub(devReward));
            }
        } else {
            safeChillTransfer(msg.sender, pending);
            lastDayBurned(0);
        }
    }
    
    function lastDayBurned(uint256 burnedAmount) internal {
        if (block.timestamp >= lastTimeOfBurn) {
            if (burnFlag == 0) {
                burnFlag = 1;
                lastBurnedPhase1 = 0;
            } else {
                burnFlag = 0;
                lastBurnedPhase2 = 0;
            }
            lastTimeOfBurn = block.timestamp.add(1 days);
        }
        totalBurnedAmount = totalBurnedAmount.add(burnedAmount);
        if (burnFlag == 0) {
            lastBurnedPhase2 = lastBurnedPhase2.add(burnedAmount);
            // return lastBurnedPhase1;
        } else {
            lastBurnedPhase1 = lastBurnedPhase1.add(burnedAmount);
            // return lastBurnedPhase2;
        }
    }
    
    function getBurnedDetails() public view returns (uint256, uint256, uint256, uint256) {
        return (burnFlag, lastBurnedPhase1, lastBurnedPhase2, totalBurnedAmount);
    }

    // For user interface to claimable token
    function pendingChill(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending;
        uint256 accChillPerShare = pool.accChillPerShare;
        uint256 lpSupply = pool.totalPoolBalance;
        if (lpSupply != 0) {
            uint256 chillReward;
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            if (block.number <= phase1time) {
                chillReward = multiplier.mul(blockPerPhase[0]).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (block.number <= phase2time) {
                chillReward = multiplier.mul(blockPerPhase[1]).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (block.number <= phase3time) {
                chillReward = multiplier.mul(blockPerPhase[2]).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (block.number <= phase4time) {
                chillReward = multiplier.mul(blockPerPhase[3]).mul(pool.allocPoint).div(totalAllocPoint);
            } else {
                chillReward = multiplier.mul(blockPerPhase[4]).mul(pool.allocPoint).div(totalAllocPoint);
            }
            accChillPerShare = accChillPerShare.add(chillReward.mul(1e12).div(pool.totalPoolBalance));
            pending =  user.amount.mul(accChillPerShare).div(1e12).sub(user.rewardDebt);
            uint256 tax = deductTaxByBlock(getCrossMultiplier(user.startedBlock, block.number));
            if (tax > 0) {
                uint256 pendingTax = pending.mul(tax).div(100);
                pending = pending.sub(pendingTax);
            }
        }
        return pending;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getCrossMultiplier(uint256 _from, uint256 currentblock) public view returns (uint256) {
        uint256 multiplier;
        if (currentblock > _from) {
            multiplier = currentblock.sub(_from);
        } else {
            multiplier = _from.sub(currentblock);
        }
        return multiplier;
    }
    
    // get if nirvana
    function getNirvanaStatus(uint256 _from) public view returns (uint256) {
        uint256 multiplier = getCrossMultiplier(_from, block.number);
        uint256 isNirvana = getTotalBlocksCovered(multiplier);
        return isNirvana;
    }
    
    // Set extra reward after each 8 hours(1920 block)
    function getTotalBlocksCovered(uint256 _block) internal view returns(uint256) {
        if (_block >= blockMilestone[4]) { // 9600
            return 50;
        } else if (_block >= blockMilestone[3]) { // 7680
            return 40;
        } else if (_block >= blockMilestone[2]) { // 5760
            return 30;
        } else if (_block >= blockMilestone[1]) { // 3840
            return 20;
        } else if (_block >= blockMilestone[0]) { // 1920
            return 10;
        } else {
            return 0;
        }
    }
    
    // Deduct tax if user withdraw before nirvana at different stage
    function deductTaxByBlock(uint256 _block) internal view returns(uint256) {
        if (_block <= blockMilestone[0]) { // 1920
            return 50;
        } else if (_block <= blockMilestone[1]) { // 3840
            return 40;
        } else if (_block <= blockMilestone[2]) { // 5760
            return 30;
        } else if (_block <= blockMilestone[3]) { // 7680
            return 20;
        } else if (_block <= blockMilestone[4]) { // 9600
            return 10;
        }  else {
            return 0;
        }
    }

    // Safe chill transfer function, just in case if rounding error causes pool to not have enough CHILLs.
    function safeChillTransfer(address _to, uint256 _amount) internal {
        uint256 chillBal = chill.balanceOf(address(this));
        if (_amount > chillBal) {
            chill.transfer(_to, chillBal);
        } else {
            chill.transfer(_to, _amount);
        }
    }
    
    // if specific lp pool is supported in uniswap uni pool the deposited lp token in chill finance will again deposit in uni pool and earn double reward in uni token
    // and owner can withdraw extra reward from uni pool
    function getUniReward(address _stakeAddress) public onlyOwner {
        IUniStakingRewards(_stakeAddress).getReward();
    }
    
    // extra uni reward only access by distributor
    // distributor can be single user or any other contracts as well 
    function accessReward(address _uniAddress, address _to, uint256 _amount) public isDistributor(msg.sender) {
        require(_amount <= IERC20(_uniAddress).balanceOf(address(this)), "Not Enough Uni Token Balance");
        require(_to != address(0), "Not Vaild Address");
        IERC20(_uniAddress).safeTransfer(_to, _amount);
    }
    
    // withdraw extra uni reward and lp token as well from uni pool
    // function getUniRewardAndExit(address _stakeAddress) public onlyOwner {
    //     IUniStakingRewards(_stakeAddress).exit();
    // }
    
    // to give support to specific pool to deposit again in uni pool to generate extra reward in uni token 
    function addStakeUniPool(address _uniV2Pool, address _stakingRewardAddress) public onlyOwner {
        require(!stakingUniPools[_uniV2Pool], "This pool is already exist.");
        uint256 _amount = IERC20(_uniV2Pool).balanceOf(address(this));
        if(_amount > 0) {
            stakeInUni(_amount, address(_uniV2Pool), address(_stakingRewardAddress));
        }
        stakingUniPools[_uniV2Pool] = true;
        uniRewardAddresses[_uniV2Pool] = _stakingRewardAddress;
    }

    // to remove support of uni pool for specific pool
    function removeStakeUniPool(address _uniV2Pool) public onlyOwner {
        require(stakingUniPools[_uniV2Pool], "This pool is not exist.");
        uint256 _amount = IUniStakingRewards(uniRewardAddresses[address(_uniV2Pool)]).balanceOf(address(this));
        if (_amount > 0) {
            IUniStakingRewards(uniRewardAddresses[address(_uniV2Pool)]).withdraw(_amount);
        }
        stakingUniPools[_uniV2Pool] = false;
        uniRewardAddresses[_uniV2Pool] = address(0);
    }
    
    // dev adderess can only change by dev
    function dev(address _devaddr, uint256 _devFee, uint256 _devTaxFee) public {
        require(msg.sender == devaddr, "dev adddress is not valid");
        devaddr = _devaddr;
        DEV_FEE = _devFee;
        DEV_TAX_FEE = _devTaxFee;
    }

    // to set flag for count $20000 worth asset for specific pool
    function setCheckInitialPeriodAndAmount(uint256 _pid, bool _isCheck, uint256 _amount) public onlyOwner {
        isCheckInitialPeriod[_pid] = _isCheck;
        initialAmt = _amount;
    }

    // set block milestone
    function setBlockMilestoneByIndex(uint256 _index, uint256 _blockMilestone) public onlyOwner {
        blockMilestone[_index] = _blockMilestone;
    }

    // increase any phase time and chill per block by its index
    function setAndEditPhaseTime(uint256 _index, uint256 _time, uint256 _chillPerBlock) public onlyOwner {
        blockPerPhase[_index] = _chillPerBlock;
        if(_index == 0) {
            phase1time = phase1time.add(_time);
        } else if(_index == 1) {
            phase2time = phase2time.add(_time);
        } else if(_index == 2) {
            phase3time = phase3time.add(_time);
        } else if(_index == 3) {
            phase4time = phase4time.add(_time);
        } else if(_index == 4) {
            phase5time = phase5time.add(_time);
        }
    }

    // get current phase with its chill per block
    function getPhaseTimeAndBlocks() public view returns(uint256, uint256) {
        if (block.number <= phase1time) {
            return ( phase1time, blockPerPhase[0] );
        } else if (block.number <= phase2time) {
            return ( phase2time, blockPerPhase[1] );
        } else if (block.number <= phase3time) {
            return ( phase3time, blockPerPhase[2] );
        } else if (block.number <= phase4time) {
            return ( phase4time, blockPerPhase[3] );
        } else {
            return ( phase5time, blockPerPhase[4] );
        }
    }

    // to set reward distibutor for extra uni token
    function setRewardDistributor(address _distributor, bool _isdistributor) public onlyOwner {
        distributors[_distributor] = _isdistributor;
    }
}