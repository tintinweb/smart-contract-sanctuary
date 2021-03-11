/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity ^0.6.0;





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
    function _setupDecimals(uint8 decimals_) internal {
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

// File: contracts/SHARDToken.sol

pragma solidity 0.6.12;






// SHARDToken with Governance.
contract SHARDToken is ERC20("Shard Token", "SHARD"), Ownable {
    // cross chain
    mapping(address => bool) public minters;

    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }
    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;
    event VotesBalanceChanged(
        address indexed user,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender] == true, "SHARD : You are not the miner");
        _mint(_to, _amount);
    }

    function addMiner(address _miner) external onlyOwner {
        minters[_miner] = true;
    }

    function removeMiner(address _miner) external onlyOwner {
        minters[_miner] = false;
    }

    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "getPriorVotes: not yet determined"
        );

        uint256 nCheckpoints = numCheckpoints[account];
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

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function _voteTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 fromNum = numCheckpoints[from];
                uint256 fromOld =
                    fromNum > 0 ? checkpoints[from][fromNum - 1].votes : 0;
                uint256 fromNew = fromOld.sub(amount);
                _writeCheckpoint(from, fromNum, fromOld, fromNew);
            }

            if (to != address(0)) {
                uint256 toNum = numCheckpoints[to];
                uint256 toOld =
                    toNum > 0 ? checkpoints[to][toNum - 1].votes : 0;
                uint256 toNew = toOld.add(amount);
                _writeCheckpoint(to, toNum, toOld, toNew);
            }
        }
    }

    function _writeCheckpoint(
        address user,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint256 blockNumber = block.number;
        if (
            nCheckpoints > 0 &&
            checkpoints[user][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[user][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[user][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[user] = nCheckpoints + 1;
        }

        emit VotesBalanceChanged(user, oldVotes, newVotes);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _voteTransfer(from, to, amount);
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: interfaces/IInvitation.sol

pragma solidity 0.6.12;

interface IInvitation{

    function acceptInvitation(address _invitor) external;

    function getInvitation(address _sender) external view returns(address _invitor, address[] memory _invitees, bool _isWithdrawn);
    
}

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// File: @uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol

pragma solidity >=0.5.0;



// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: contracts/ActivityBase.sol

pragma solidity 0.6.12;





contract ActivityBase{
    using SafeMath for uint256;
    using FixedPoint for *;

    struct TokenPairInfo{
        IUniswapV2Pair tokenToEthSwap; 
        FixedPoint.uq112x112 price; 
        bool isFirstTokenEth;
        uint256 priceCumulativeLast;
        uint32  blockTimestampLast;
        uint256 lastPriceUpdateHeight;
    }

    // invitee's supply 5% deposit weight to its invitor
    uint256 public constant INVITEE_WEIGHT = 20; 
    // invitee's supply 10% deposit weight to its invitor
    uint256 public constant INVITOR_WEIGHT = 10;

    // The block number when SHARD mining starts.
    uint256 public startBlock;

    // token as the unit of measurement
    address public WETHToken;

    // dev fund
    uint256 public userDividendWeight = 8;
    uint256 public devDividendWeight = 2;
    address public devAddress;

    uint256 public updateTokenPriceTerm = 120;

    function getTargetTokenInSwap(IUniswapV2Pair _lpTokenSwap, address _targetToken) internal view returns (address, address, uint256){
        address token0 = _lpTokenSwap.token0();
        address token1 = _lpTokenSwap.token1();
        if(token0 == _targetToken){
            return(token0, token1, 0);
        }
        if(token1 == _targetToken){
            return(token0, token1, 1);
        }
        require(false, "invalid uniswap");
    }

    function generateOrcaleInfo(IUniswapV2Pair _pairSwap, bool _isFirstTokenEth) internal view returns(TokenPairInfo memory){
        uint256 priceTokenCumulativeLast = _isFirstTokenEth? _pairSwap.price1CumulativeLast(): _pairSwap.price0CumulativeLast();
        uint112 reserve0;
        uint112 reserve1;
        uint32 tokenBlockTimestampLast;
        (reserve0, reserve1, tokenBlockTimestampLast) = _pairSwap.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'ExampleOracleSimple: NO_RESERVES'); // ensure that there's liquidity in the pair
        TokenPairInfo memory tokenBInfo = TokenPairInfo({
            tokenToEthSwap: _pairSwap,
            isFirstTokenEth: _isFirstTokenEth,
            priceCumulativeLast: priceTokenCumulativeLast,
            blockTimestampLast: tokenBlockTimestampLast,
            price: FixedPoint.uq112x112(0),
            lastPriceUpdateHeight: block.number
        });
        return tokenBInfo;
    }

    function updateTokenOracle(TokenPairInfo storage _pairInfo) internal returns (FixedPoint.uq112x112 memory _price) {
        FixedPoint.uq112x112 memory cachedPrice = _pairInfo.price;
        if(cachedPrice._x > 0 && block.number.sub(_pairInfo.lastPriceUpdateHeight) <= updateTokenPriceTerm){
            return cachedPrice;
        }
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pairInfo.tokenToEthSwap));
        uint32 timeElapsed = blockTimestamp - _pairInfo.blockTimestampLast; // overflow is desired
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        if(_pairInfo.isFirstTokenEth){
            _price = FixedPoint.uq112x112(uint224(price1Cumulative.sub(_pairInfo.priceCumulativeLast).div(timeElapsed)));
            _pairInfo.priceCumulativeLast = price1Cumulative;
        }     
        else{
            _price = FixedPoint.uq112x112(uint224(price0Cumulative.sub(_pairInfo.priceCumulativeLast).div(timeElapsed)));
            _pairInfo.priceCumulativeLast = price0Cumulative;
        }
        _pairInfo.price = _price;
        _pairInfo.lastPriceUpdateHeight = block.number;
        _pairInfo.blockTimestampLast = blockTimestamp;
    }
}

// File: contracts/MasterchefActivityTwo.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;









contract MasterChefActivityTwo is Ownable, IInvitation, ActivityBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20; 

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How much LP token the user has provided.
        uint256 originWeight; //initial weight
        uint256 inviteeWeight; // invitees' weight
        uint256 endBlock;
        bool isCalculateInvitation;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 nftPoolId;
        address lpTokenSwap; // uniswapPair contract address
        uint256 accumulativeDividend;
        uint256 usersTotalWeight; // user's sum weight
        uint256 lpTokenAmount; // lock amount
        uint256 oracleWeight; // eth value
        uint256 lastDividendHeight; // last dividend block height
        TokenPairInfo tokenToEthPairInfo;
        bool isFirstTokenShard;
    }

    struct InvitationInfo {
        address invitor;
        address[] invitees;
        bool isUsed;
        bool isWithdrawn;
        mapping(address => uint256) inviteeIndexMap;
    }

    // The SHARD TOKEN!
    SHARDToken public SHARD;

    // Info of each pool.
    uint256[] private rankPoolIndex;
    // indicates whether the pool is in the rank
    mapping(uint256 => uint256) public rankPoolIndexMap;

    // relationship info about invitation
    mapping(address => InvitationInfo) private usersRelationshipInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;
    // Info of each pool.
    PoolInfo[] private poolInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public maxRankNumber = 10;

    // Last block number that SHARDs distribution occurs.
    uint256 public lastRewardBlock;

    // produced blocks per day
    uint256 public constant produceBlocksPerDay = 6496;
     // produced blocks per month
    uint256 public constant produceBlocksPerMonth = 1;
    // Bonus muliplier for early SHARD makers.
    uint256 public constant INITIAL_BONUS_PER_BLOCK = 11052 * (1e14);
    // after each term, mine half SHARD token
    uint256 public constant MINT_DECREASE_TERM = 9500000;
    // used to caculate user deposit weight
    uint256[] private depositTimeWeight;

    // max lock time in stage two
    uint256 private constant MAX_MONTH = 36;

    // add pool automatically in nft shard
    address public nftShard;

    // to mint token cross chain
    uint256 public nftMintWeight = 1;
    uint256 public reserveMintWeight = 0;
    uint256 public reserveToMint;

    // black list
    struct EvilPoolInfo {
        uint256 pid;
        string description;
    }
    EvilPoolInfo[] public blackList;
    mapping(uint256 => uint256) public blackListMap;

    // undividend shard
    uint256 public unDividendShard;

    // 20% shard => SHARD - ETH pool
    uint256 public shardPoolDividendWeight = 2;
    // 80% shard => SHARD - ETH pool
    uint256 public otherPoolDividendWeight = 8;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 weight
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Replace(
        address indexed user,
        uint256 indexed rankIndex,
        uint256 newPid
    );

    event AddToBlacklist(
        uint256 indexed pid
    );

    event RemoveFromBlacklist(
        uint256 indexed pid
    );

    function initialize(
        SHARDToken _SHARD,
        address _wethToken,
        address _devAddress,
        uint256 _maxRankNumber,
        uint256 _startBlock
    ) public virtual onlyOwner{
        require(WETHToken == address(0), "already initialized");
        SHARD = _SHARD;
        maxRankNumber = _maxRankNumber;
        if (_startBlock < block.number) {
            startBlock = block.number;
        } else {
            startBlock = _startBlock;
        }
        lastRewardBlock = startBlock.sub(1);
        WETHToken = _wethToken;
        initializeTimeWeight();
        devAddress = _devAddress;
        InvitationInfo storage initialInvitor =
            usersRelationshipInfo[address(this)];
        initialInvitor.isUsed = true;
    }

    function initializeTimeWeight() private {
        depositTimeWeight = [
            1238,
            1383,
            1495,
            1587,
            1665,
            1732,
            1790,
            1842,
            1888,
            1929,
            1966,
            2000,
            2031,
            2059,
            2085,
            2108,
            2131,
            2152,
            2171,
            2189,
            2206,
            2221,
            2236,
            2250,
            2263,
            2276,
            2287,
            2298,
            2309,
            2319,
            2328,
            2337,
            2346,
            2355,
            2363,
            2370
        ];
    }

    function setNftShard(address _nftShard) public virtual onlyOwner {
        require(
            nftShard == address(0),
            "nft shard contract's address has been set"
        );
        nftShard = _nftShard;
    }

    // Add a new lp to the pool. Can only be called by the nft shard contract.
    // if _lpTokenSwap contains tokenA instead of eth, then _tokenToEthSwap should consist of token A and eth
    function add(
        uint256 _nftPoolId,
        IUniswapV2Pair _lpTokenSwap,
        IUniswapV2Pair _tokenToEthSwap
    ) public virtual {
        require(msg.sender == nftShard || msg.sender == owner(), "invalid sender");
        TokenPairInfo memory tokenToEthInfo;
        uint256 lastDividendHeight = 0;
        if(poolInfo.length == 0){
            _nftPoolId = 0;
            lastDividendHeight = lastRewardBlock;  //adjust
        }
        bool isFirstTokenShard;
        if (address(_tokenToEthSwap) != address(0)) {
            (address token0, address token1, uint256 targetTokenPosition) =
                getTargetTokenInSwap(_tokenToEthSwap, WETHToken);
            address wantToken;
            bool isFirstTokenEthToken;
            if (targetTokenPosition == 0) {
                isFirstTokenEthToken = true;
                wantToken = token1;
            } else {
                isFirstTokenEthToken = false;
                wantToken = token0;
            }
            (, , targetTokenPosition) = getTargetTokenInSwap(
                _lpTokenSwap,
                wantToken
            );
            if (targetTokenPosition == 0) {
                isFirstTokenShard = false;
            } else {
                isFirstTokenShard = true;
            }
            tokenToEthInfo = generateOrcaleInfo(
                _tokenToEthSwap,
                isFirstTokenEthToken
            );
        } else {
            (, , uint256 targetTokenPosition) =
                getTargetTokenInSwap(_lpTokenSwap, WETHToken);
            if (targetTokenPosition == 0) {
                isFirstTokenShard = false;
            } else {
                isFirstTokenShard = true;
            }
            tokenToEthInfo = generateOrcaleInfo(
                _lpTokenSwap,
                !isFirstTokenShard
            );
        }
        poolInfo.push(
            PoolInfo({
                nftPoolId: _nftPoolId,
                lpTokenSwap: address(_lpTokenSwap),
                lpTokenAmount: 0,
                usersTotalWeight: 0,
                accumulativeDividend: 0,
                oracleWeight: 0,
                lastDividendHeight: lastDividendHeight,
                tokenToEthPairInfo: tokenToEthInfo,
                isFirstTokenShard: isFirstTokenShard
            })
        );
    }

    function setPriceUpdateTerm(uint256 _term) public virtual onlyOwner{
        updateTokenPriceTerm = _term;
    }

    function kickEvilPoolByPid(uint256 _pid, string calldata description)
        public
        virtual
        onlyOwner
    {
        bool isDescriptionLeagal = verifyDescription(description);
        require(isDescriptionLeagal, "invalid description, just ASCII code is allowed");
        require(_pid > 0, "invalid pid");
        uint256 poolRankIndex = rankPoolIndexMap[_pid];
        if (poolRankIndex > 0) {
            massUpdatePools();
            uint256 _rankIndex = poolRankIndex.sub(1);
            uint256 currentRankLastIndex = rankPoolIndex.length.sub(1);
            uint256 lastPidInRank = rankPoolIndex[currentRankLastIndex];
            rankPoolIndex[_rankIndex] = lastPidInRank;
            rankPoolIndexMap[lastPidInRank] = poolRankIndex;
            delete rankPoolIndexMap[_pid];
            rankPoolIndex.pop();
        }
        addInBlackList(_pid, description);
        dealEvilPoolDiviend(_pid);
        emit AddToBlacklist(_pid);
    }

    function addInBlackList(uint256 _pid, string calldata description) private {
        if (blackListMap[_pid] > 0) {
            return;
        }
        blackList.push(EvilPoolInfo({pid: _pid, description: description}));
        blackListMap[_pid] = blackList.length;
    }

    function resetEvilPool(uint256 _pid) public virtual onlyOwner {
        uint256 poolPosition = blackListMap[_pid];
        if (poolPosition == 0) {
            return;
        }
        uint256 poolIndex = poolPosition.sub(1);
        uint256 lastIndex = blackList.length.sub(1);
        EvilPoolInfo storage lastEvilInBlackList = blackList[lastIndex];
        uint256 lastPidInBlackList = lastEvilInBlackList.pid;
        blackListMap[lastPidInBlackList] = poolPosition;
        blackList[poolIndex] = blackList[lastIndex];
        delete blackListMap[_pid];
        blackList.pop();
        emit RemoveFromBlacklist(_pid);
    }

    function dealEvilPoolDiviend(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 undistributeDividend = pool.accumulativeDividend;
        if (undistributeDividend == 0) {
            return;
        }
        uint256 currentRankCount = rankPoolIndex.length;
        if (currentRankCount > 0) {
            uint256 averageDividend =
                undistributeDividend.div(currentRankCount);
            for (uint256 i = 0; i < currentRankCount; i++) {
                PoolInfo storage poolInRank = poolInfo[rankPoolIndex[i]];
                if (i < currentRankCount - 1) {
                    poolInRank.accumulativeDividend = poolInRank
                        .accumulativeDividend
                        .add(averageDividend);
                    undistributeDividend = undistributeDividend.sub(
                        averageDividend
                    );
                } else {
                    poolInRank.accumulativeDividend = poolInRank
                        .accumulativeDividend
                        .add(undistributeDividend);
                }
            }
        } else {
            unDividendShard = unDividendShard.add(undistributeDividend);
        }
        pool.accumulativeDividend = 0;
    }

    function setMintCoefficient(
        uint256 _nftMintWeight,
        uint256 _reserveMintWeight
    ) public virtual onlyOwner {
        require(
            _nftMintWeight != 0 && _reserveMintWeight != 0,
            "invalid input"
        );
        massUpdatePools();
        nftMintWeight = _nftMintWeight;
        reserveMintWeight = _reserveMintWeight;
    }

    function setShardPoolDividendWeight(
        uint256 _shardPoolWeight,
        uint256 _otherPoolWeight
    ) public virtual onlyOwner {
        require(
            _shardPoolWeight != 0 && _otherPoolWeight != 0,
            "invalid input"
        );
        massUpdatePools();
        shardPoolDividendWeight = _shardPoolWeight;
        otherPoolDividendWeight = _otherPoolWeight;
    }

    function massUpdatePools() public virtual {
        uint256 poolCountInRank = rankPoolIndex.length;
        uint256 farmMintShard = mintSHARD(address(this), block.number);
        updateSHARDPoolAccumulativeDividend(block.number);
        if(poolCountInRank == 0){
            farmMintShard = farmMintShard.mul(otherPoolDividendWeight)
                                     .div(shardPoolDividendWeight.add(otherPoolDividendWeight));
            if(farmMintShard > 0){
                unDividendShard = unDividendShard.add(farmMintShard);
            }
        }
        for (uint256 i = 0; i < poolCountInRank; i++) {
            updatePoolAccumulativeDividend(
                rankPoolIndex[i],
                poolCountInRank,
                block.number
            );
        }
    }

    // update reward vairables for a pool
    function updatePoolDividend(uint256 _pid) public virtual {
        if(_pid == 0){
            updateSHARDPoolAccumulativeDividend(block.number);
            return;
        }
        if (rankPoolIndexMap[_pid] == 0) {
            return;
        }
        updatePoolAccumulativeDividend(
            _pid,
            rankPoolIndex.length,
            block.number
        );
    }

    function mintSHARD(address _address, uint256 _toBlock) private returns (uint256){
        uint256 recentlyRewardBlock = lastRewardBlock;
        if (recentlyRewardBlock >= _toBlock) {
            return 0;
        }
        uint256 totalReward =
            getRewardToken(recentlyRewardBlock.add(1), _toBlock);
        uint256 farmMint =
            totalReward.mul(nftMintWeight).div(
                reserveMintWeight.add(nftMintWeight)
            );
        uint256 reserve = totalReward.sub(farmMint);
        if (totalReward > 0) {
            SHARD.mint(_address, farmMint);
            if (reserve > 0) {
                reserveToMint = reserveToMint.add(reserve);
            }
            lastRewardBlock = _toBlock;
        }
        return farmMint;
    }

    function updatePoolAccumulativeDividend(
        uint256 _pid,
        uint256 _validRankPoolCount,
        uint256 _toBlock
    ) private {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.lastDividendHeight >= _toBlock) return;
        uint256 poolReward =
            getModifiedRewardToken(pool.lastDividendHeight.add(1), _toBlock)
                                    .mul(otherPoolDividendWeight)
                                    .div(shardPoolDividendWeight.add(otherPoolDividendWeight));

        uint256 otherPoolReward = poolReward.div(_validRankPoolCount);                            
        pool.lastDividendHeight = _toBlock;
        uint256 existedDividend = pool.accumulativeDividend;
        pool.accumulativeDividend = existedDividend.add(otherPoolReward);
    }

    function updateSHARDPoolAccumulativeDividend (uint256 _toBlock) private{
        PoolInfo storage pool = poolInfo[0];
        if (pool.lastDividendHeight >= _toBlock) return;
        uint256 poolReward =
            getModifiedRewardToken(pool.lastDividendHeight.add(1), _toBlock);

        uint256 shardPoolDividend = poolReward.mul(shardPoolDividendWeight)
                                               .div(shardPoolDividendWeight.add(otherPoolDividendWeight));                              
        pool.lastDividendHeight = _toBlock;
        uint256 existedDividend = pool.accumulativeDividend;
        pool.accumulativeDividend = existedDividend.add(shardPoolDividend);
    }

    // deposit LP tokens to MasterChef for SHARD allocation.
    // ignore lockTime in stage one
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256 _lockTime
    ) public virtual {
        require(_amount > 0, "invalid deposit amount");
        InvitationInfo storage senderInfo = usersRelationshipInfo[msg.sender];
        require(senderInfo.isUsed, "must accept an invitation firstly");
        require(_lockTime > 0 && _lockTime <= 36, "invalid lock time"); // less than 36 months
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpTokenAmount = pool.lpTokenAmount.add(_amount);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 newOriginWeight = user.originWeight;
        uint256 existedAmount = user.amount;
        uint256 endBlock = user.endBlock;
        uint256 newEndBlock =
            block.number.add(produceBlocksPerMonth.mul(_lockTime));
        if (existedAmount > 0) {
            if (block.number >= endBlock) {
                newOriginWeight = getDepositWeight(
                    _amount.add(existedAmount),
                    _lockTime
                );
            } else {
                newOriginWeight = newOriginWeight.add(getDepositWeight(_amount, _lockTime));
                newOriginWeight = newOriginWeight.add(
                    getDepositWeight(
                        existedAmount,
                        newEndBlock.sub(endBlock).div(produceBlocksPerMonth)
                    )
                );
            }
        } else {
            newOriginWeight = getDepositWeight(_amount, _lockTime);
        }
        modifyWeightByInvitation(
            _pid,
            msg.sender,
            user.originWeight,
            newOriginWeight,
            user.inviteeWeight,
            existedAmount
        );   
        updateUserInfo(
            user,
            existedAmount.add(_amount),
            newOriginWeight,
            newEndBlock
        );
        IERC20(pool.lpTokenSwap).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.oracleWeight =  getOracleWeight(pool, lpTokenAmount);
        pool.lpTokenAmount = lpTokenAmount;
        if (
            rankPoolIndexMap[_pid] == 0 &&
            rankPoolIndex.length < maxRankNumber &&
            blackListMap[_pid] == 0
        ) {
            addToRank(pool, _pid);
        }
        emit Deposit(msg.sender, _pid, _amount, newOriginWeight);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid) public virtual {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "user is not existed");
        require(user.endBlock < block.number, "token is still locked");
        mintSHARD(address(this), block.number);
        updatePoolDividend(_pid);
        uint256 originWeight = user.originWeight;
        PoolInfo storage pool = poolInfo[_pid];
        uint256 totalDividend = pool.accumulativeDividend;
        uint256 usersTotalWeight = pool.usersTotalWeight;
        uint256 userWeight = user.inviteeWeight.add(originWeight);
        if(user.isCalculateInvitation){
            userWeight = userWeight.add(originWeight.div(INVITOR_WEIGHT));
        }
        if (totalDividend > 0) {
            uint256 pending =
                totalDividend.mul(userWeight).div(usersTotalWeight);
            pool.accumulativeDividend = totalDividend.sub(pending);
            uint256 devDividend =
                pending.mul(devDividendWeight).div(
                    devDividendWeight.add(userDividendWeight)
                );
            if(devDividend > 0){
                pending = pending.sub(devDividend);
                safeSHARDTransfer(devAddress, devDividend);
            }
            safeSHARDTransfer(msg.sender, pending);
        }
        pool.usersTotalWeight = usersTotalWeight.sub(userWeight);
        uint256 amount = user.amount;
        userInfo[_pid][msg.sender].amount = 0;
        userInfo[_pid][msg.sender].originWeight = 0;
        userInfo[_pid][msg.sender].endBlock = 0;
        IERC20(pool.lpTokenSwap).safeTransfer(address(msg.sender), amount);
        uint256 lpTokenAmount = pool.lpTokenAmount.sub(amount);
        pool.lpTokenAmount = lpTokenAmount;
        uint256 oracleWeight = 0;
        if (lpTokenAmount == 0) oracleWeight = 0;
        else {
            oracleWeight = getOracleWeight(pool, lpTokenAmount);
        }
        pool.oracleWeight = oracleWeight;
        resetInvitationRelationship(_pid, msg.sender, originWeight);
        emit Withdraw(msg.sender, _pid, amount);
    }

    function addToRank(
        PoolInfo storage _pool,
        uint256 _pid
    ) private {
        if(_pid == 0){
            return;
        }
        massUpdatePools();
        _pool.lastDividendHeight = block.number;
        rankPoolIndex.push(_pid);
        rankPoolIndexMap[_pid] = rankPoolIndex.length;
        if(unDividendShard > 0){
            _pool.accumulativeDividend = _pool.accumulativeDividend.add(unDividendShard);
            unDividendShard = 0;
        }
        emit Replace(msg.sender, rankPoolIndex.length.sub(1), _pid);
        return;
    }

    //_poolIndexInRank is the index in rank
    //_pid is the index in poolInfo
    function tryToReplacePoolInRank(uint256 _poolIndexInRank, uint256 _pid)
        public
        virtual
    {
        if(_pid == 0){
            return;
        }
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.lpTokenAmount > 0, "there is not any lp token depsoited");
        require(blackListMap[_pid] == 0, "pool is in the black list");
        if (rankPoolIndexMap[_pid] > 0) {
            return;
        }
        uint256 currentPoolCountInRank = rankPoolIndex.length;
        require(currentPoolCountInRank == maxRankNumber, "invalid operation");
        uint256 targetPid = rankPoolIndex[_poolIndexInRank];
        PoolInfo storage targetPool = poolInfo[targetPid];
        uint256 targetPoolOracleWeight = getOracleWeight(targetPool, targetPool.lpTokenAmount);
        uint256 challengerOracleWeight = getOracleWeight(pool, pool.lpTokenAmount);
        if (challengerOracleWeight <= targetPoolOracleWeight) {
            return;
        }
        updatePoolDividend(targetPid);
        rankPoolIndex[_poolIndexInRank] = _pid;
        delete rankPoolIndexMap[targetPid];
        rankPoolIndexMap[_pid] = _poolIndexInRank.add(1);
        pool.lastDividendHeight = block.number;
        emit Replace(msg.sender, _poolIndexInRank, _pid);
    }

    function acceptInvitation(address _invitor) public virtual override {
        require(_invitor != msg.sender, "invitee should not be invitor");
        buildInvitation(_invitor, msg.sender);
    }

    function buildInvitation(address _invitor, address _invitee) private {
        InvitationInfo storage invitee = usersRelationshipInfo[_invitee];
        require(!invitee.isUsed, "has accepted invitation");
        invitee.isUsed = true;
        InvitationInfo storage invitor = usersRelationshipInfo[_invitor];
        require(invitor.isUsed, "invitor has not acceptted invitation");
        invitee.invitor = _invitor;
        invitor.invitees.push(_invitee);
        invitor.inviteeIndexMap[_invitee] = invitor.invitees.length.sub(1);
    }

    function setMaxRankNumber(uint256 _count) public virtual onlyOwner {
        require(_count > 0, "invalid count");
        if (maxRankNumber == _count) return;
        massUpdatePools();
        maxRankNumber = _count;
        uint256 currentPoolCountInRank = rankPoolIndex.length;
        if (_count >= currentPoolCountInRank) {
            return;
        }
        uint256 sparePoolCount = currentPoolCountInRank.sub(_count);
        uint256 lastPoolIndex = currentPoolCountInRank.sub(1);
        while (sparePoolCount > 0) {
            delete rankPoolIndexMap[rankPoolIndex[lastPoolIndex]];
            rankPoolIndex.pop();
            lastPoolIndex--;
            sparePoolCount--;
        }
    }

    function setDeveloperFund(
        address _devAddress,
        uint256 _userDividendWeight,
        uint256 _devDividendWeight
    ) public virtual onlyOwner {
        require(
            _userDividendWeight != 0 && _devDividendWeight != 0,
            "invalid input"
        );
        userDividendWeight = _userDividendWeight;
        devDividendWeight = _devDividendWeight;
        devAddress = _devAddress;
    }

    function setInvitation(
        address _invitor, 
        address[] memory _invitees
    ) public virtual onlyOwner {
        for(uint256 i = 0; i < _invitees.length; i++) {
            address invitee = _invitees[i];
            require(_invitor != invitee, "invitee should not be invitor");
            buildInvitation(_invitor, invitee);
        }    
    }

    function getModifiedRewardToken(uint256 _fromBlock, uint256 _toBlock)
        private
        view
        returns (uint256)
    {
        return
            getRewardToken(_fromBlock, _toBlock).mul(nftMintWeight).div(
                reserveMintWeight.add(nftMintWeight)
            );
    }

    // View function to see pending SHARDs on frontend.
    function pendingSHARD(uint256 _pid, address _user)
        external
        view
        virtual
        returns (uint256 _pending, uint256 _potential)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (user.amount == 0) {
            return (0, 0);
        }
        uint256 recentlyRewardBlock = pool.lastDividendHeight;
        uint256 userWithdrawWeight = userDividendWeight;
        uint256 totalWithdrawWeight = userWithdrawWeight.add(devDividendWeight);
        uint256 userModifiedWeight = getUserModifiedWeight(_pid, _user);
        _pending = pool
            .accumulativeDividend
            .mul(userModifiedWeight)
            .div(pool.usersTotalWeight);
        _pending = _pending   
            .mul(userWithdrawWeight)
            .div(totalWithdrawWeight);
        if (recentlyRewardBlock >= block.number) {
            return (_pending, 0);
        }
        uint256 validRankPoolCount = rankPoolIndex.length;
        if (_pid != 0 && (validRankPoolCount == 0 || rankPoolIndexMap[_pid] == 0)) {
            return (_pending, 0);
        }
        recentlyRewardBlock = recentlyRewardBlock.add(1);
        uint256 poolReward = getModifiedRewardToken(recentlyRewardBlock, block.number);
        if(_pid != 0){
            poolReward = poolReward.div(validRankPoolCount);
        }                          
        _potential = poolReward
            .mul(userModifiedWeight)
            .div(pool.usersTotalWeight);
        _potential = _potential    
            .mul(userWithdrawWeight)
            .div(totalWithdrawWeight);
        uint256 numerator;
        uint256 denominator = otherPoolDividendWeight.add(shardPoolDividendWeight);
        if(_pid == 0){
            numerator = shardPoolDividendWeight;
        }
        else{
            numerator = otherPoolDividendWeight;
        }
        _potential = _potential       
            .mul(numerator)
            .div(denominator);
    }

    //calculate the weight and end block when users deposit
    function getDepositWeight(uint256 _lockAmount, uint256 _lockTime)
        private
        view
        returns (uint256)
    {
        if (_lockTime == 0) return 0;
        if (_lockTime.div(MAX_MONTH) > 1) _lockTime = MAX_MONTH;
        return depositTimeWeight[_lockTime.sub(1)].sub(500).mul(_lockAmount);
    }

    function getPoolLength() public view virtual returns (uint256) {
        return poolInfo.length;
    }

    function getPagePoolInfo(uint256 _fromIndex, uint256 _toIndex)
        public
        view
        virtual
        returns (
            uint256[] memory _nftPoolId,
            uint256[] memory _accumulativeDividend,
            uint256[] memory _usersTotalWeight,
            uint256[] memory _lpTokenAmount,
            uint256[] memory _oracleWeight,
            address[] memory _swapAddress
        )
    {
        uint256 poolCount = _toIndex.sub(_fromIndex).add(1);
        _nftPoolId = new uint256[](poolCount);
        _accumulativeDividend = new uint256[](poolCount);
        _usersTotalWeight = new uint256[](poolCount);
        _lpTokenAmount = new uint256[](poolCount);
        _oracleWeight = new uint256[](poolCount);
        _swapAddress = new address[](poolCount);
        uint256 startIndex = 0;
        for (uint256 i = _fromIndex; i <= _toIndex; i++) {
            PoolInfo storage pool = poolInfo[i];
            _nftPoolId[startIndex] = pool.nftPoolId;
            _accumulativeDividend[startIndex] = pool.accumulativeDividend;
            _usersTotalWeight[startIndex] = pool.usersTotalWeight;
            _lpTokenAmount[startIndex] = pool.lpTokenAmount;
            _oracleWeight[startIndex] = pool.oracleWeight;
            _swapAddress[startIndex] = pool.lpTokenSwap;
            startIndex++;
        }
    }

    function getInstantPagePoolInfo(uint256 _fromIndex, uint256 _toIndex)
    public
    virtual
    returns (
        uint256[] memory _nftPoolId,
        uint256[] memory _accumulativeDividend,
        uint256[] memory _usersTotalWeight,
        uint256[] memory _lpTokenAmount,
        uint256[] memory _oracleWeight,
        address[] memory _swapAddress
    )
    {
        uint256 poolCount = _toIndex.sub(_fromIndex).add(1);
        _nftPoolId = new uint256[](poolCount);
        _accumulativeDividend = new uint256[](poolCount);
        _usersTotalWeight = new uint256[](poolCount);
        _lpTokenAmount = new uint256[](poolCount);
        _oracleWeight = new uint256[](poolCount);
        _swapAddress = new address[](poolCount);
        uint256 startIndex = 0;
        for (uint256 i = _fromIndex; i <= _toIndex; i++) {
            PoolInfo storage pool = poolInfo[i];
            _nftPoolId[startIndex] = pool.nftPoolId;
            _accumulativeDividend[startIndex] = pool.accumulativeDividend;
            _usersTotalWeight[startIndex] = pool.usersTotalWeight;
            _lpTokenAmount[startIndex] = pool.lpTokenAmount;
            _oracleWeight[startIndex] = getOracleWeight(pool, _lpTokenAmount[startIndex]);
            _swapAddress[startIndex] = pool.lpTokenSwap;
            startIndex++;
        }
    }

    function getRankList() public view virtual returns (uint256[] memory) {
        uint256[] memory rankIdList = rankPoolIndex;
        return rankIdList;
    }

    function getBlackList()
        public
        view
        virtual
        returns (EvilPoolInfo[] memory _blackList)
    {
        _blackList = blackList;
    }

    function getInvitation(address _sender)
        public
        view
        virtual
        override
        returns (
            address _invitor,
            address[] memory _invitees,
            bool _isWithdrawn
        )
    {
        InvitationInfo storage invitation = usersRelationshipInfo[_sender];
        _invitees = invitation.invitees;
        _invitor = invitation.invitor;
        _isWithdrawn = invitation.isWithdrawn;
    }

    function getUserInfo(uint256 _pid, address _user)
        public
        view
        virtual
        returns (
            uint256 _amount,
            uint256 _originWeight,
            uint256 _modifiedWeight,
            uint256 _endBlock
        )
    {
        UserInfo storage user = userInfo[_pid][_user];
        _amount = user.amount;
        _originWeight = user.originWeight;
        _modifiedWeight = getUserModifiedWeight(_pid, _user);
        _endBlock = user.endBlock;
    }

    function getOracleInfo(uint256 _pid)
        public
        view
        virtual
        returns (
            address _swapToEthAddress,
            uint256 _priceCumulativeLast,
            uint256 _blockTimestampLast,
            uint256 _price,
            uint256 _lastPriceUpdateHeight
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        _swapToEthAddress = address(pool.tokenToEthPairInfo.tokenToEthSwap);
        _priceCumulativeLast = pool.tokenToEthPairInfo.priceCumulativeLast;
        _blockTimestampLast = pool.tokenToEthPairInfo.blockTimestampLast;
        _price = pool.tokenToEthPairInfo.price._x;
        _lastPriceUpdateHeight = pool.tokenToEthPairInfo.lastPriceUpdateHeight;
    }

    // Safe SHARD transfer function, just in case if rounding error causes pool to not have enough SHARDs.
    function safeSHARDTransfer(address _to, uint256 _amount) internal {
        uint256 SHARDBal = SHARD.balanceOf(address(this));
        if (_amount > SHARDBal) {
            SHARD.transfer(_to, SHARDBal);
        } else {
            SHARD.transfer(_to, _amount);
        }
    }

    function updateUserInfo(
        UserInfo storage _user,
        uint256 _amount,
        uint256 _originWeight,
        uint256 _endBlock
    ) private {
        _user.amount = _amount;
        _user.originWeight = _originWeight;
        _user.endBlock = _endBlock;
    }

    function getOracleWeight(
        PoolInfo storage _pool,
        uint256 _amount
    ) private returns (uint256 _oracleWeight) {
        _oracleWeight = calculateOracleWeight(_pool, _amount);
        _pool.oracleWeight = _oracleWeight;
    }

    function calculateOracleWeight(PoolInfo storage _pool, uint256 _amount)
        private
        returns (uint256 _oracleWeight)
    {
        uint256 lpTokenTotalSupply =
            IUniswapV2Pair(_pool.lpTokenSwap).totalSupply();
        (uint112 shardReserve, uint112 wantTokenReserve, ) =
            IUniswapV2Pair(_pool.lpTokenSwap).getReserves();
        if (_amount == 0) {
            _amount = _pool.lpTokenAmount;
            if (_amount == 0) {
                return 0;
            }
        }
        if (!_pool.isFirstTokenShard) {
            uint112 wantToken = wantTokenReserve;
            wantTokenReserve = shardReserve;
            shardReserve = wantToken;
        }
        FixedPoint.uq112x112 memory price =
            updateTokenOracle(_pool.tokenToEthPairInfo);
        if (
            address(_pool.tokenToEthPairInfo.tokenToEthSwap) ==
            _pool.lpTokenSwap
        ) {
            _oracleWeight = uint256(price.mul(shardReserve).decode144())
                .mul(2)
                .mul(_amount)
                .div(lpTokenTotalSupply);
        } else {
            _oracleWeight = uint256(price.mul(wantTokenReserve).decode144())
                .mul(2)
                .mul(_amount)
                .div(lpTokenTotalSupply);
        }
    }

    function resetInvitationRelationship(
        uint256 _pid,
        address _user,
        uint256 _originWeight
    ) private {
        InvitationInfo storage senderRelationshipInfo =
            usersRelationshipInfo[_user];
        if (!senderRelationshipInfo.isWithdrawn){
            senderRelationshipInfo.isWithdrawn = true;
            InvitationInfo storage invitorRelationshipInfo =
            usersRelationshipInfo[senderRelationshipInfo.invitor];
            uint256 targetIndex = invitorRelationshipInfo.inviteeIndexMap[_user];
            uint256 inviteesCount = invitorRelationshipInfo.invitees.length;
            address lastInvitee =
            invitorRelationshipInfo.invitees[inviteesCount.sub(1)];
            invitorRelationshipInfo.inviteeIndexMap[lastInvitee] = targetIndex;
            invitorRelationshipInfo.invitees[targetIndex] = lastInvitee;
            delete invitorRelationshipInfo.inviteeIndexMap[_user];
            invitorRelationshipInfo.invitees.pop();
        }
        
        UserInfo storage invitorInfo =
            userInfo[_pid][senderRelationshipInfo.invitor];
        UserInfo storage user =
            userInfo[_pid][_user];
        if(!user.isCalculateInvitation){
            return;
        }
        user.isCalculateInvitation = false;
        uint256 inviteeToSubWeight = _originWeight.div(INVITEE_WEIGHT);
        invitorInfo.inviteeWeight = invitorInfo.inviteeWeight.sub(inviteeToSubWeight);
        if (invitorInfo.amount == 0){
            return;
        }
        PoolInfo storage pool = poolInfo[_pid];
        pool.usersTotalWeight = pool.usersTotalWeight.sub(inviteeToSubWeight);
    }

    function modifyWeightByInvitation(
        uint256 _pid,
        address _user,
        uint256 _oldOriginWeight,
        uint256 _newOriginWeight,
        uint256 _inviteeWeight,
        uint256 _existedAmount
    ) private{
        PoolInfo storage pool = poolInfo[_pid];
        InvitationInfo storage senderInfo = usersRelationshipInfo[_user];
        uint256 poolTotalWeight = pool.usersTotalWeight;
        poolTotalWeight = poolTotalWeight.sub(_oldOriginWeight).add(_newOriginWeight);
        if(_existedAmount == 0){
            poolTotalWeight = poolTotalWeight.add(_inviteeWeight);
        }     
        UserInfo storage user = userInfo[_pid][_user];
        if (!senderInfo.isWithdrawn || (_existedAmount > 0 && user.isCalculateInvitation)) {
            UserInfo storage invitorInfo = userInfo[_pid][senderInfo.invitor];
            user.isCalculateInvitation = true;
            uint256 addInviteeWeight =
                    _newOriginWeight.div(INVITEE_WEIGHT).sub(
                        _oldOriginWeight.div(INVITEE_WEIGHT)
                    );
            invitorInfo.inviteeWeight = invitorInfo.inviteeWeight.add(
                addInviteeWeight
            );
            uint256 addInvitorWeight = 
                    _newOriginWeight.div(INVITOR_WEIGHT).sub(
                        _oldOriginWeight.div(INVITOR_WEIGHT)
                    );
            
            poolTotalWeight = poolTotalWeight.add(addInvitorWeight);
            if (invitorInfo.amount > 0) {
                poolTotalWeight = poolTotalWeight.add(addInviteeWeight);
            } 
        }
        pool.usersTotalWeight = poolTotalWeight;
    }

    function verifyDescription(string memory description)
        internal
        pure
        returns (bool success)
    {
        bytes memory nameBytes = bytes(description);
        uint256 nameLength = nameBytes.length;
        require(nameLength > 0, "INVALID INPUT");
        success = true;
        bool n7;
        for (uint256 i = 0; i <= nameLength - 1; i++) {
            n7 = (nameBytes[i] & 0x80) == 0x80 ? true : false;
            if (n7) {
                success = false;
                break;
            }
        }
    }

    function getUserModifiedWeight(uint256 _pid, address _user) private view returns (uint256){
        UserInfo storage user =  userInfo[_pid][_user];
        uint256 originWeight = user.originWeight;
        uint256 modifiedWeight = originWeight.add(user.inviteeWeight);
        if(user.isCalculateInvitation){
            modifiedWeight = modifiedWeight.add(originWeight.div(INVITOR_WEIGHT));
        }
        return modifiedWeight;
    }

        // get how much token will be mined from _toBlock to _toBlock.
    function getRewardToken(uint256 _fromBlock, uint256 _toBlock) public view virtual returns (uint256){
        return calculateRewardToken(MINT_DECREASE_TERM, INITIAL_BONUS_PER_BLOCK, startBlock, _fromBlock, _toBlock);
    }

    function calculateRewardToken(uint _term, uint256 _initialBlock, uint256 _startBlock, uint256 _fromBlock, uint256 _toBlock) private pure returns (uint256){
        if(_fromBlock > _toBlock || _startBlock > _toBlock)
            return 0;
        if(_startBlock > _fromBlock)
            _fromBlock = _startBlock;
        uint256 totalReward = 0;
        uint256 blockPeriod = _fromBlock.sub(_startBlock).add(1);
        uint256 yearPeriod = blockPeriod.div(_term);  // produce 5760 blocks per day, 2102400 blocks per year.
        for (uint256 i = 0; i < yearPeriod; i++){
            _initialBlock = _initialBlock.div(2);
        }
        uint256 termStartIndex = yearPeriod.add(1).mul(_term).add(_startBlock);
        uint256 beforeCalculateIndex = _fromBlock.sub(1);
        while(_toBlock >= termStartIndex && _initialBlock > 0){
            totalReward = totalReward.add(termStartIndex.sub(beforeCalculateIndex).mul(_initialBlock));
            beforeCalculateIndex = termStartIndex.add(1);
            _initialBlock = _initialBlock.div(2);
            termStartIndex = termStartIndex.add(_term);
        }
        if(_toBlock > beforeCalculateIndex){
            totalReward = totalReward.add(_toBlock.sub(beforeCalculateIndex).mul(_initialBlock));
        }
        return totalReward;
    }
}