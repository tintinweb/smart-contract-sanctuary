// SPDX-License-Identifier: GPL-3.0-only
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/network/$.sol

pragma solidity ^0.6.0;

/**
 * @dev This library is provided for conveniece. It is the single source for
 *      the current network and all related hardcoded contract addresses. It
 *      also provide useful definitions for debuging faultless code via events.
 */
library $
{
	address constant GRO = 0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0;

	address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	address constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

	address constant cETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

	address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

	address constant Aave_AAVE_LENDING_POOL = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;

	address constant Aave_AAVE_LENDING_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

	address constant Balancer_FACTORY = 0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd;

	address constant Compound_COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

	address constant Dydx_SOLO_MARGIN = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

	address constant Sushiswap_ROUTER02 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
}

// File: contracts/interop/WrappedEther.sol

pragma solidity ^0.6.0;

interface WETH is IERC20
{
	function deposit() external payable;
	function withdraw(uint256 _amount) external;
}

// File: contracts/interop/UniswapV2.sol

pragma solidity ^0.6.0;

interface Router01
{
	function WETH() external pure returns (address _token);
	function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapETHForExactTokens(uint256 _amountOut, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint[] memory _amounts);
	function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint[] memory _amounts);
}

interface Router02 is Router01
{
}

// File: contracts/interop/Aave.sol

pragma solidity ^0.6.0;

interface LendingPoolAddressesProvider
{
	function getLendingPool() external view returns (address _pool);
	function getLendingPoolCore() external view returns (address payable _lendingPoolCore);
}

interface LendingPool
{
	function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;
}

interface FlashLoanReceiver
{
	function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

// File: contracts/interop/Dydx.sol

pragma solidity ^0.6.0;

interface SoloMargin
{
	function getMarketTokenAddress(uint256 _marketId) external view returns (address _token);
	function getNumMarkets() external view returns (uint256 _numMarkets);
	function operate(Account.Info[] memory _accounts, Actions.ActionArgs[] memory _actions) external;
}

interface ICallee
{
	function callFunction(address _sender, Account.Info memory _accountInfo, bytes memory _data) external;
}

library Account
{
	struct Info {
		address owner;
		uint256 number;
	}
}

library Actions
{
	enum ActionType { Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call }

	struct ActionArgs {
		ActionType actionType;
		uint256 accountId;
		Types.AssetAmount amount;
		uint256 primaryMarketId;
		uint256 secondaryMarketId;
		address otherAddress;
		uint256 otherAccountId;
		bytes data;
	}
}

library Types
{
	enum AssetDenomination { Wei, Par }
	enum AssetReference { Delta, Target }

	struct AssetAmount {
		bool sign;
		AssetDenomination denomination;
		AssetReference ref;
		uint256 value;
	}
}

// File: contracts/interop/Balancer.sol

pragma solidity ^0.6.0;

interface BFactory
{
	function newBPool() external returns (address _pool);
}

interface BPool is IERC20
{
	function getFinalTokens() external view returns (address[] memory _tokens);
	function getBalance(address _token) external view returns (uint256 _balance);
	function setSwapFee(uint256 _swapFee) external;
	function finalize() external;
	function bind(address _token, uint256 _balance, uint256 _denorm) external;
	function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;
	function joinswapExternAmountIn(address _tokenIn, uint256 _tokenAmountIn, uint256 _minPoolAmountOut) external returns (uint256 _poolAmountOut);
}

// File: contracts/interop/Compound.sol

pragma solidity ^0.6.0;

interface Comptroller
{
	function oracle() external view returns (address _oracle);
	function enterMarkets(address[] calldata _ctokens) external returns (uint256[] memory _errorCodes);
	function markets(address _ctoken) external view returns (bool _isListed, uint256 _collateralFactorMantissa);
	function getAccountLiquidity(address _account) external view returns (uint256 _error, uint256 _liquidity, uint256 _shortfall);
}

interface PriceOracle
{
	function getUnderlyingPrice(address _ctoken) external view returns (uint256 _price);
}

interface CToken is IERC20
{
	function underlying() external view returns (address _token);
	function exchangeRateStored() external view returns (uint256 _exchangeRate);
	function borrowBalanceStored(address _account) external view returns (uint256 _borrowBalance);
	function exchangeRateCurrent() external returns (uint256 _exchangeRate);
	function getCash() external view returns (uint256 _cash);
	function borrowBalanceCurrent(address _account) external returns (uint256 _borrowBalance);
	function balanceOfUnderlying(address _owner) external returns (uint256 _underlyingBalance);
	function mint() external payable;
	function mint(uint256 _mintAmount) external returns (uint256 _errorCode);
	function repayBorrow() external payable;
	function repayBorrow(uint256 _repayAmount) external returns (uint256 _errorCode);
	function redeemUnderlying(uint256 _redeemAmount) external returns (uint256 _errorCode);
	function borrow(uint256 _borrowAmount) external returns (uint256 _errorCode);
}

// File: contracts/modules/Math.sol

pragma solidity ^0.6.0;

library Math
{
	function _min(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _minAmount)
	{
		return _amount1 < _amount2 ? _amount1 : _amount2;
	}

	function _max(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _maxAmount)
	{
		return _amount1 > _amount2 ? _amount1 : _amount2;
	}
}

// File: contracts/modules/Wrapping.sol

pragma solidity ^0.6.0;

library Wrapping
{
	function _wrap(uint256 _amount) internal returns (bool _success)
	{
		try WETH($.WETH).deposit{value: _amount}() {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _unwrap(uint256 _amount) internal returns (bool _success)
	{
		try WETH($.WETH).withdraw(_amount) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _safeWrap(uint256 _amount) internal
	{
		require(_wrap(_amount), "wrap failed");
	}

	function _safeUnwrap(uint256 _amount) internal
	{
		require(_unwrap(_amount), "unwrap failed");
	}
}

// File: contracts/modules/Transfers.sol

pragma solidity ^0.6.0;

library Transfers
{
	using SafeERC20 for IERC20;

	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	function _approveFunds(address _token, address _to, uint256 _amount) internal
	{
		uint256 _allowance = IERC20(_token).allowance(address(this), _to);
		if (_allowance > _amount) {
			IERC20(_token).safeDecreaseAllowance(_to, _allowance - _amount);
		}
		else
		if (_allowance < _amount) {
			IERC20(_token).safeIncreaseAllowance(_to, _amount - _allowance);
		}
	}

	function _pullFunds(address _token, address _from, uint256 _amount) internal
	{
		IERC20(_token).safeTransferFrom(_from, address(this), _amount);
	}

	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		IERC20(_token).safeTransfer(_to, _amount);
	}
}

// File: contracts/GExchange.sol

pragma solidity ^0.6.0;

/**
 * @dev Custom and uniform interface to a decentralized exchange. It is used
 *      to estimate and convert funds whenever necessary. This furnishes
 *      client contracts with the flexibility to replace conversion strategy
 *      and routing, dynamically, by delegating these operations to different
 *      external contracts that share this common interface. See
 *      GUniswapV2Exchange.sol for further documentation.
 */
interface GExchange
{
	// view functions
	function calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) external view returns (uint256 _outputAmount);
	function calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) external view returns (uint256 _inputAmount);

	// open functions
	function convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external returns (uint256 _outputAmount);
}

// File: contracts/modules/Conversions.sol

pragma solidity ^0.6.0;

library Conversions
{
	function _dynamicConvertFunds(address _exchange, address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Transfers._approveFunds(_from, _exchange, _inputAmount);
		try GExchange(_exchange).convertFunds(_from, _to, _inputAmount, _minOutputAmount) returns (uint256 _outAmount) {
			return _outAmount;
		} catch (bytes memory /* _data */) {
			Transfers._approveFunds(_from, _exchange, 0);
			return 0;
		}
	}
}

// File: contracts/modules/AaveFlashLoanAbstraction.sol

pragma solidity ^0.6.0;

library AaveFlashLoanAbstraction
{
	using SafeMath for uint256;

	uint256 constant FLASH_LOAN_FEE_RATIO = 9e14; // 0.09%

	function _estimateFlashLoanFee(address _token, uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		_token;
		return _netAmount.mul(FLASH_LOAN_FEE_RATIO).div(1e18);
	}

	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		address _pool = $.Aave_AAVE_LENDING_POOL;
		try LendingPool(_pool).flashLoan(address(this), _token, _netAmount, _context) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _paybackFlashLoan(address _token, uint256 _grossAmount) internal
	{
		address _poolCore = $.Aave_AAVE_LENDING_POOL_CORE;
		Transfers._pushFunds(_token, _poolCore, _grossAmount);
	}
}

// File: contracts/modules/DydxFlashLoanAbstraction.sol

pragma solidity ^0.6.0;

library DydxFlashLoanAbstraction
{
	using SafeMath for uint256;

	function _estimateFlashLoanFee(address /* _token */, uint256 /* _netAmount */) internal pure returns (uint256 _feeAmount)
	{
		return 2;
	}

	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		address _solo = $.Dydx_SOLO_MARGIN;
		uint256 _feeAmount = 2;
		uint256 _grossAmount = _netAmount.add(_feeAmount);
		uint256 _marketId = uint256(-1);
		uint256 _numMarkets = SoloMargin(_solo).getNumMarkets();
		for (uint256 _i = 0; _i < _numMarkets; _i++) {
			address _address = SoloMargin(_solo).getMarketTokenAddress(_i);
			if (_address == _token) {
				_marketId = _i;
				break;
			}
		}
		if (_marketId == uint256(-1)) return false;
		Account.Info[] memory _accounts = new Account.Info[](1);
		_accounts[0] = Account.Info({ owner: address(this), number: 1 });
		Actions.ActionArgs[] memory _actions = new Actions.ActionArgs[](3);
		_actions[0] = Actions.ActionArgs({
			actionType: Actions.ActionType.Withdraw,
			accountId: 0,
			amount: Types.AssetAmount({
				sign: false,
				denomination: Types.AssetDenomination.Wei,
				ref: Types.AssetReference.Delta,
				value: _netAmount
			}),
			primaryMarketId: _marketId,
			secondaryMarketId: 0,
			otherAddress: address(this),
			otherAccountId: 0,
			data: ""
		});
		_actions[1] = Actions.ActionArgs({
			actionType: Actions.ActionType.Call,
			accountId: 0,
			amount: Types.AssetAmount({
				sign: false,
				denomination: Types.AssetDenomination.Wei,
				ref: Types.AssetReference.Delta,
				value: 0
			}),
			primaryMarketId: 0,
			secondaryMarketId: 0,
			otherAddress: address(this),
			otherAccountId: 0,
			data: abi.encode(_token, _netAmount, _feeAmount, _context)
		});
		_actions[2] = Actions.ActionArgs({
			actionType: Actions.ActionType.Deposit,
			accountId: 0,
			amount: Types.AssetAmount({
				sign: true,
				denomination: Types.AssetDenomination.Wei,
				ref: Types.AssetReference.Delta,
				value: _grossAmount
			}),
			primaryMarketId: _marketId,
			secondaryMarketId: 0,
			otherAddress: address(this),
			otherAccountId: 0,
			data: ""
		});
		try SoloMargin(_solo).operate(_accounts, _actions) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _paybackFlashLoan(address _token, uint256 _grossAmount) internal
	{
		address _solo = $.Dydx_SOLO_MARGIN;
		Transfers._approveFunds(_token, _solo, _grossAmount);
	}
}

// File: contracts/modules/FlashLoans.sol

pragma solidity ^0.6.0;

library FlashLoans
{
	enum Provider { Aave, Dydx }

	function _estimateFlashLoanFee(Provider _provider, address _token, uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		if (_provider == Provider.Aave) return AaveFlashLoanAbstraction._estimateFlashLoanFee(_token, _netAmount);
		if (_provider == Provider.Dydx) return DydxFlashLoanAbstraction._estimateFlashLoanFee(_token, _netAmount);
	}

	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		_success = DydxFlashLoanAbstraction._requestFlashLoan(_token, _netAmount, _context);
		if (_success) return true;
		_success = AaveFlashLoanAbstraction._requestFlashLoan(_token, _netAmount, _context);
		if (_success) return true;
		return false;
	}

	function _paybackFlashLoan(Provider _provider, address _token, uint256 _grossAmount) internal
	{
		if (_provider == Provider.Aave) return AaveFlashLoanAbstraction._paybackFlashLoan(_token, _grossAmount);
		if (_provider == Provider.Dydx) return DydxFlashLoanAbstraction._paybackFlashLoan(_token, _grossAmount);
	}
}

// File: contracts/modules/BalancerLiquidityPoolAbstraction.sol

pragma solidity ^0.6.0;

library BalancerLiquidityPoolAbstraction
{
	using SafeMath for uint256;

	uint256 constant MIN_AMOUNT = 1e6;
	uint256 constant TOKEN0_WEIGHT = 25e18; // 25/50 = 50%
	uint256 constant TOKEN1_WEIGHT = 25e18; // 25/50 = 50%
	uint256 constant SWAP_FEE = 10e16; // 10%

	function _createPool(address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal returns (address _pool)
	{
		require(_amount0 >= MIN_AMOUNT && _amount1 >= MIN_AMOUNT, "amount below the minimum");
		_pool = BFactory($.Balancer_FACTORY).newBPool();
		Transfers._approveFunds(_token0, _pool, _amount0);
		Transfers._approveFunds(_token1, _pool, _amount1);
		BPool(_pool).bind(_token0, _amount0, TOKEN0_WEIGHT);
		BPool(_pool).bind(_token1, _amount1, TOKEN1_WEIGHT);
		BPool(_pool).setSwapFee(SWAP_FEE);
		BPool(_pool).finalize();
		return _pool;
	}

	function _joinPool(address _pool, address _token, uint256 _maxAmount) internal returns (uint256 _amount)
	{
		uint256 _balanceAmount = BPool(_pool).getBalance(_token);
		if (_balanceAmount == 0) return 0;
		uint256 _limitAmount = _balanceAmount.div(2);
		_amount = Math._min(_maxAmount, _limitAmount);
		Transfers._approveFunds(_token, _pool, _amount);
		BPool(_pool).joinswapExternAmountIn(_token, _amount, 0);
		return _amount;
	}

	function _exitPool(address _pool, uint256 _percent) internal returns (uint256 _amount0, uint256 _amount1)
	{
		if (_percent == 0) return (0, 0);
		address[] memory _tokens = BPool(_pool).getFinalTokens();
		_amount0 = Transfers._getBalance(_tokens[0]);
		_amount1 = Transfers._getBalance(_tokens[1]);
		uint256 _poolAmount = Transfers._getBalance(_pool);
		uint256 _poolExitAmount = _poolAmount.mul(_percent).div(1e18);
		uint256[] memory _minAmountsOut = new uint256[](2);
		_minAmountsOut[0] = 0;
		_minAmountsOut[1] = 0;
		BPool(_pool).exitPool(_poolExitAmount, _minAmountsOut);
		_amount0 = Transfers._getBalance(_tokens[0]).sub(_amount0);
		_amount1 = Transfers._getBalance(_tokens[1]).sub(_amount1);
		return (_amount0, _amount1);
	}
}

// File: contracts/modules/CompoundLendingMarketAbstraction.sol

pragma solidity ^0.6.0;

library CompoundLendingMarketAbstraction
{
	using SafeMath for uint256;

	function _getUnderlyingToken(address _ctoken) internal view returns (address _token)
	{
		if (_ctoken == $.cETH) return $.WETH;
		return CToken(_ctoken).underlying();
	}

	function _getCollateralRatio(address _ctoken) internal view returns (uint256 _collateralFactor)
	{
		address _comptroller = $.Compound_COMPTROLLER;
		(, _collateralFactor) = Comptroller(_comptroller).markets(_ctoken);
		return _collateralFactor;
	}

	function _getMarketAmount(address _ctoken) internal view returns (uint256 _marketAmount)
	{
		return CToken(_ctoken).getCash();
	}

	function _getLiquidityAmount(address _ctoken) internal view returns (uint256 _liquidityAmount)
	{
		address _comptroller = $.Compound_COMPTROLLER;
		(uint256 _result, uint256 _liquidity, uint256 _shortfall) = Comptroller(_comptroller).getAccountLiquidity(address(this));
		if (_result != 0) return 0;
		if (_shortfall > 0) return 0;
		address _priceOracle = Comptroller(_comptroller).oracle();
		uint256 _price = PriceOracle(_priceOracle).getUnderlyingPrice(_ctoken);
		return _liquidity.mul(1e18).div(_price);
	}

	function _getAvailableAmount(address _ctoken, uint256 _marginAmount) internal view returns (uint256 _availableAmount)
	{
		uint256 _liquidityAmount = _getLiquidityAmount(_ctoken);
		if (_liquidityAmount <= _marginAmount) return 0;
		return Math._min(_liquidityAmount.sub(_marginAmount), _getMarketAmount(_ctoken));
	}

	function _getExchangeRate(address _ctoken) internal view returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateStored();
	}

	function _fetchExchangeRate(address _ctoken) internal returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateCurrent();
	}

	function _getLendAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		return CToken(_ctoken).balanceOf(address(this)).mul(_getExchangeRate(_ctoken)).div(1e18);
	}

	function _fetchLendAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).balanceOfUnderlying(address(this));
	}

	function _getBorrowAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceStored(address(this));
	}

	function _fetchBorrowAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceCurrent(address(this));
	}

	function _enter(address _ctoken) internal returns (bool _success)
	{
		address _comptroller = $.Compound_COMPTROLLER;
		address[] memory _ctokens = new address[](1);
		_ctokens[0] = _ctoken;
		try Comptroller(_comptroller).enterMarkets(_ctokens) returns (uint256[] memory _errorCodes) {
			return _errorCodes[0] == 0;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _lend(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			if (!Wrapping._unwrap(_amount)) return false;
			try CToken(_ctoken).mint{value: _amount}() {
				return true;
			} catch (bytes memory /* _data */) {
				assert(Wrapping._wrap(_amount));
				return false;
			}
		} else {
			address _token = _getUnderlyingToken(_ctoken);
			Transfers._approveFunds(_token, _ctoken, _amount);
			try CToken(_ctoken).mint(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
	}

	function _redeem(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			try CToken(_ctoken).redeemUnderlying(_amount) returns (uint256 _errorCode) {
				if (_errorCode == 0) {
					assert(Wrapping._wrap(_amount));
					return true;
				} else {
					return false;
				}
			} catch (bytes memory /* _data */) {
				return false;
			}
		} else {
			try CToken(_ctoken).redeemUnderlying(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
	}

	function _borrow(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			try CToken(_ctoken).borrow(_amount) returns (uint256 _errorCode) {
				if (_errorCode == 0) {
					assert(Wrapping._wrap(_amount));
					return true;
				} else {
					return false;
				}
			} catch (bytes memory /* _data */) {
				return false;
			}
		} else {
			try CToken(_ctoken).borrow(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
	}

	function _repay(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			if (!Wrapping._unwrap(_amount)) return false;
			try CToken(_ctoken).repayBorrow{value: _amount}() {
				return true;
			} catch (bytes memory /* _data */) {
				assert(Wrapping._wrap(_amount));
				return false;
			}
		} else {
			address _token = _getUnderlyingToken(_ctoken);
			Transfers._approveFunds(_token, _ctoken, _amount);
			try CToken(_ctoken).repayBorrow(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
	}

	function _safeEnter(address _ctoken) internal
	{
		require(_enter(_ctoken), "enter failed");
	}

	function _safeLend(address _ctoken, uint256 _amount) internal
	{
		require(_lend(_ctoken, _amount), "lend failure");
	}

	function _safeRedeem(address _ctoken, uint256 _amount) internal
	{
		require(_redeem(_ctoken, _amount), "redeem failure");
	}

	function _safeBorrow(address _ctoken, uint256 _amount) internal
	{
		require(_borrow(_ctoken, _amount), "borrow failure");
	}

	function _safeRepay(address _ctoken, uint256 _amount) internal
	{
		require(_repay(_ctoken, _amount), "repay failure");
	}
}

// File: contracts/G.sol

pragma solidity ^0.6.0;

/**
 * @dev This public library provides a single entrypoint to all the relevant
 *      internal libraries available in the modules folder. It exists to
 *      circunvent the contract size limitation imposed by the EVM. All function
 *      calls are directly delegated to the target library function preserving
 *      argument and return values exactly as they are. Thit library is shared
 *      by all contracts and even other public libraries from this repository,
 *      therefore it needs to be published alongside them.
 */
library G
{
	function min(uint256 _amount1, uint256 _amount2) public pure returns (uint256 _minAmount) { return Math._min(_amount1, _amount2); }

	function safeWrap(uint256 _amount) public { Wrapping._safeWrap(_amount); }
	function safeUnwrap(uint256 _amount) public { Wrapping._safeUnwrap(_amount); }

	function getBalance(address _token) public view returns (uint256 _balance) { return Transfers._getBalance(_token); }
	function pullFunds(address _token, address _from, uint256 _amount) public { Transfers._pullFunds(_token, _from, _amount); }
	function pushFunds(address _token, address _to, uint256 _amount) public { Transfers._pushFunds(_token, _to, _amount); }
	function approveFunds(address _token, address _to, uint256 _amount) public { Transfers._approveFunds(_token, _to, _amount); }

	function dynamicConvertFunds(address _exchange, address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) public returns (uint256 _outputAmount) { return Conversions._dynamicConvertFunds(_exchange, _from, _to, _inputAmount, _minOutputAmount); }

	function requestFlashLoan(address _token, uint256 _amount, bytes memory _context) public returns (bool _success) { return FlashLoans._requestFlashLoan(_token, _amount, _context); }
	function paybackFlashLoan(FlashLoans.Provider _provider, address _token, uint256 _grossAmount) public { FlashLoans._paybackFlashLoan(_provider, _token, _grossAmount); }

	function createPool(address _token0, uint256 _amount0, address _token1, uint256 _amount1) public returns (address _pool) { return BalancerLiquidityPoolAbstraction._createPool(_token0, _amount0, _token1, _amount1); }
	function joinPool(address _pool, address _token, uint256 _maxAmount) public returns (uint256 _amount) { return BalancerLiquidityPoolAbstraction._joinPool(_pool, _token, _maxAmount); }
	function exitPool(address _pool, uint256 _percent) public returns (uint256 _amount0, uint256 _amount1) { return BalancerLiquidityPoolAbstraction._exitPool(_pool, _percent); }

	function getUnderlyingToken(address _ctoken) public view returns (address _token) { return CompoundLendingMarketAbstraction._getUnderlyingToken(_ctoken); }
	function getCollateralRatio(address _ctoken) public view returns (uint256 _collateralFactor) { return CompoundLendingMarketAbstraction._getCollateralRatio(_ctoken); }
	function getLiquidityAmount(address _ctoken) public view returns (uint256 _liquidityAmount) { return CompoundLendingMarketAbstraction._getLiquidityAmount(_ctoken); }
	function getExchangeRate(address _ctoken) public view returns (uint256 _exchangeRate) { return CompoundLendingMarketAbstraction._getExchangeRate(_ctoken); }
	function fetchExchangeRate(address _ctoken) public returns (uint256 _exchangeRate) { return CompoundLendingMarketAbstraction._fetchExchangeRate(_ctoken); }
	function getLendAmount(address _ctoken) public view returns (uint256 _amount) { return CompoundLendingMarketAbstraction._getLendAmount(_ctoken); }
	function fetchLendAmount(address _ctoken) public returns (uint256 _amount) { return CompoundLendingMarketAbstraction._fetchLendAmount(_ctoken); }
	function getBorrowAmount(address _ctoken) public view returns (uint256 _amount) { return CompoundLendingMarketAbstraction._getBorrowAmount(_ctoken); }
	function fetchBorrowAmount(address _ctoken) public returns (uint256 _amount) { return CompoundLendingMarketAbstraction._fetchBorrowAmount(_ctoken); }
	function lend(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._lend(_ctoken, _amount); }
	function redeem(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._redeem(_ctoken, _amount); }
	function borrow(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._borrow(_ctoken, _amount); }
	function repay(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._repay(_ctoken, _amount); }
	function safeEnter(address _ctoken) public { CompoundLendingMarketAbstraction._safeEnter(_ctoken); }
	function safeLend(address _ctoken, uint256 _amount) public { CompoundLendingMarketAbstraction._safeLend(_ctoken, _amount); }
	function safeRedeem(address _ctoken, uint256 _amount) public { CompoundLendingMarketAbstraction._safeRedeem(_ctoken, _amount); }
}

// File: contracts/GToken.sol

pragma solidity ^0.6.0;

/**
 * @dev Complete top-level interface for gTokens, implemented by the
 *      GTokenBase contract. See GTokenBase.sol for further documentation.
 */
interface GToken is IERC20
{
	// pure functions
	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) external pure returns (uint256 _cost, uint256 _feeShares);
	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) external pure returns (uint256 _cost, uint256 _feeShares);

	// view functions
	function stakesToken() external view returns (address _stakesToken);
	function reserveToken() external view returns (address _reserveToken);
	function totalReserve() external view returns (uint256 _totalReserve);
	function depositFee() external view returns (uint256 _depositFee);
	function withdrawalFee() external view returns (uint256 _withdrawalFee);
	function liquidityPool() external view returns (address _liquidityPool);
	function liquidityPoolBurningRate() external view returns (uint256 _burningRate);
	function liquidityPoolLastBurningTime() external view returns (uint256 _lastBurningTime);
	function liquidityPoolMigrationRecipient() external view returns (address _migrationRecipient);
	function liquidityPoolMigrationUnlockTime() external view returns (uint256 _migrationUnlockTime);

	// open functions
	function deposit(uint256 _cost) external;
	function withdraw(uint256 _grossShares) external;

	// priviledged functions
	function allocateLiquidityPool(uint256 _stakesAmount, uint256 _sharesAmount) external;
	function setLiquidityPoolBurningRate(uint256 _burningRate) external;
	function burnLiquidityPoolPortion() external;
	function initiateLiquidityPoolMigration(address _migrationRecipient) external;
	function cancelLiquidityPoolMigration() external;
	function completeLiquidityPoolMigration() external;

	// emitted events
	event BurnLiquidityPoolPortion(uint256 _stakesAmount, uint256 _sharesAmount);
	event InitiateLiquidityPoolMigration(address indexed _migrationRecipient);
	event CancelLiquidityPoolMigration(address indexed _migrationRecipient);
	event CompleteLiquidityPoolMigration(address indexed _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount);
}

// File: contracts/GCToken.sol

pragma solidity ^0.6.0;

/**
 * @dev Complete top-level interface for gcTokens, implemented by the
 *      GCTokenBase contract. See GCTokenBase.sol for further documentation.
 */
interface GCToken is GToken
{
	// pure functions
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);
	function calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost, uint256 _feeShares);
	function calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost, uint256 _feeShares);

	// view functions
	function miningToken() external view returns (address _miningToken);
	function growthToken() external view returns (address _growthToken);
	function underlyingToken() external view returns (address _underlyingToken);
	function exchangeRate() external view returns (uint256 _exchangeRate);
	function totalReserveUnderlying() external view returns (uint256 _totalReserveUnderlying);
	function lendingReserveUnderlying() external view returns (uint256 _lendingReserveUnderlying);
	function borrowingReserveUnderlying() external view returns (uint256 _borrowingReserveUnderlying);
	function exchange() external view returns (address _exchange);
	function miningGulpRange() external view returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount);
	function growthGulpRange() external view returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount);
	function collateralizationRatio() external view returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin);

	// open functions
	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;

	// priviledged functions
	function setExchange(address _exchange) external;
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) external;
	function setGrowthGulpRange(uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) external;
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) external;
}

// File: contracts/GFormulae.sol

pragma solidity ^0.6.0;

/**
 * @dev Pure implementation of deposit/minting and withdrawal/burning formulas
 *      for gTokens.
 *      All operations assume that, if total supply is 0, then the total
 *      reserve is also 0, and vice-versa.
 *      Fees are calculated percentually based on the gross amount.
 *      See GTokenBase.sol for further documentation.
 */
library GFormulae
{
	using SafeMath for uint256;

	/* deposit(cost):
	 *   price = reserve / supply
	 *   gross = cost / price
	 *   net = gross * 0.99	# fee is assumed to be 1% for simplicity
	 *   fee = gross - net
	 *   return net, fee
	 */
	function _calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _grossShares = _totalSupply == _totalReserve ? _cost : _cost.mul(_totalSupply).div(_totalReserve);
		_netShares = _grossShares.mul(uint256(1e18).sub(_depositFee)).div(1e18);
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	/* deposit_reverse(net):
	 *   price = reserve / supply
	 *   gross = net / 0.99	# fee is assumed to be 1% for simplicity
	 *   cost = gross * price
	 *   fee = gross - net
	 *   return cost, fee
	 */
	function _calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _grossShares = _netShares.mul(1e18).div(uint256(1e18).sub(_depositFee));
		_cost = _totalReserve == _totalSupply ? _grossShares : _grossShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	/* withdrawal_reverse(cost):
	 *   price = reserve / supply
	 *   net = cost / price
	 *   gross = net / 0.99	# fee is assumed to be 1% for simplicity
	 *   fee = gross - net
	 *   return gross, fee
	 */
	function _calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _netShares = _cost == _totalReserve ? _totalSupply : _cost.mul(_totalSupply).div(_totalReserve);
		_grossShares = _netShares.mul(1e18).div(uint256(1e18).sub(_withdrawalFee));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	/* withdrawal(gross):
	 *   price = reserve / supply
	 *   net = gross * 0.99	# fee is assumed to be 1% for simplicity
	 *   cost = net * price
	 *   fee = gross - net
	 *   return cost, fee
	 */
	function _calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _netShares = _grossShares.mul(uint256(1e18).sub(_withdrawalFee)).div(1e18);
		_cost = _netShares == _totalSupply ? _totalReserve : _netShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}
}

// File: contracts/GCFormulae.sol

pragma solidity ^0.6.0;

/**
 * @dev Pure implementation of deposit/minting and withdrawal/burning formulas
 *      for gTokens calculated based on the cToken underlying asset
 *      (e.g. DAI for cDAI). See GFormulae.sol and GCTokenBase.sol for further
 *      documentation.
 */
library GCFormulae
{
	using SafeMath for uint256;

	/**
	 * @dev Simple token to cToken formula from Compound
	 */
	function _calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) internal pure returns (uint256 _cost)
	{
		return _underlyingCost.mul(1e18).div(_exchangeRate);
	}

	/**
	 * @dev Simple cToken to token formula from Compound
	 */
	function _calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost)
	{
		return _cost.mul(_exchangeRate).div(1e18);
	}

	/**
	 * @dev Composition of the gToken deposit formula with the Compound
	 *      conversion formula to obtain the gcToken deposit formula in
	 *      terms of the cToken underlying asset.
	 */
	function _calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @dev Composition of the gToken reserve deposit formula with the
	 *      Compound conversion formula to obtain the gcToken reverse
	 *      deposit formula in terms of the cToken underlying asset.
	 */
	function _calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		uint256 _cost;
		(_cost, _feeShares) = GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
		return (_calcUnderlyingCostFromCost(_cost, _exchangeRate), _feeShares);
	}

	/**
	 * @dev Composition of the gToken reserve withdrawal formula with the
	 *      Compound conversion formula to obtain the gcToken reverse
	 *      withdrawal formula in terms of the cToken underlying asset.
	 */
	function _calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @dev Composition of the gToken withdrawal formula with the Compound
	 *      conversion formula to obtain the gcToken withdrawal formula in
	 *      terms of the cToken underlying asset.
	 */
	function _calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		uint256 _cost;
		(_cost, _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
		return (_calcUnderlyingCostFromCost(_cost, _exchangeRate), _feeShares);
	}
}

// File: contracts/GLiquidityPoolManager.sol

pragma solidity ^0.6.0;

/**
 * @dev This library implements data structure abstraction for the liquidity
 *      pool management code in order to circuvent the EVM contract size limit.
 *      It is therefore a public library shared by all gToken contracts and
 *      needs to be published alongside them. See GTokenBase.sol for further
 *      documentation.
 */
library GLiquidityPoolManager
{
	using GLiquidityPoolManager for GLiquidityPoolManager.Self;

	uint256 constant MAXIMUM_BURNING_RATE = 2e16; // 2%
	uint256 constant DEFAULT_BURNING_RATE = 5e15; // 0.5%
	uint256 constant BURNING_INTERVAL = 7 days;
	uint256 constant MIGRATION_INTERVAL = 7 days;

	enum State { Created, Allocated, Migrating, Migrated }

	struct Self {
		address stakesToken;
		address sharesToken;

		State state;
		address liquidityPool;

		uint256 burningRate;
		uint256 lastBurningTime;

		address migrationRecipient;
		uint256 migrationUnlockTime;
	}

	/**
	 * @dev Initializes the data structure. This method is exposed publicly.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _sharesToken The ERC-20 token address to be used as shares
	 *                     token (gToken).
	 */
	function init(Self storage _self, address _stakesToken, address _sharesToken) public
	{
		_self.stakesToken = _stakesToken;
		_self.sharesToken = _sharesToken;

		_self.state = State.Created;
		_self.liquidityPool = address(0);

		_self.burningRate = DEFAULT_BURNING_RATE;
		_self.lastBurningTime = 0;

		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
	}

	/**
	 * @dev Verifies whether or not a liquidity pool is migrating or
	 *      has migrated. This method is exposed publicly.
	 * @return _hasMigrated A boolean indicating whether or not the pool
	 *                      migration has started.
	 */
	function hasMigrated(Self storage _self) public view returns (bool _hasMigrated)
	{
		return _self.state == State.Migrating || _self.state == State.Migrated;
	}

	/**
	 * @dev Moves the current balances (if any) of stakes and shares tokens
	 *      to the liquidity pool. This method is exposed publicly.
	 */
	function gulpPoolAssets(Self storage _self) public
	{
		if (!_self._hasPool()) return;
		G.joinPool(_self.liquidityPool, _self.stakesToken, G.getBalance(_self.stakesToken));
		G.joinPool(_self.liquidityPool, _self.sharesToken, G.getBalance(_self.sharesToken));
	}

	/**
	 * @dev Sets the liquidity pool burning rate. This method is exposed
	 *      publicly.
	 * @param _burningRate The percent value of the liquidity pool to be
	 *                     burned at each 7-day period.
	 */
	function setBurningRate(Self storage _self, uint256 _burningRate) public
	{
		require(_burningRate <= MAXIMUM_BURNING_RATE, "invalid rate");
		_self.burningRate = _burningRate;
	}

	/**
	 * @dev Burns a portion of the liquidity pool according to the defined
	 *      burning rate. It must happen at most once every 7-days. This
	 *      method does not actually burn the funds, but it will redeem
	 *      the amounts from the pool to the caller contract, which is then
	 *      assumed to perform the burn. This method is exposed publicly.
	 * @return _stakesAmount The amount of stakes (GRO) redeemed from the pool.
	 * @return _sharesAmount The amount of shares (gToken) redeemed from the pool.
	 */
	function burnPoolPortion(Self storage _self) public returns (uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_self._hasPool(), "pool not available");
		require(now >= _self.lastBurningTime + BURNING_INTERVAL, "must wait lock interval");
		_self.lastBurningTime = now;
		return G.exitPool(_self.liquidityPool, _self.burningRate);
	}

	/**
	 * @dev Creates a fresh new liquidity pool and deposits the initial
	 *      amounts of the stakes token and the shares token. The pool
	 *      if configure 50%/50% with a 10% swap fee. This method is exposed
	 *      publicly.
	 * @param _stakesAmount The amount of stakes token initially deposited
	 *                      into the pool.
	 * @param _sharesAmount The amount of shares token initially deposited
	 *                      into the pool.
	 */
	function allocatePool(Self storage _self, uint256 _stakesAmount, uint256 _sharesAmount) public
	{
		require(_self.state == State.Created, "pool cannot be allocated");
		_self.state = State.Allocated;
		_self.liquidityPool = G.createPool(_self.stakesToken, _stakesAmount, _self.sharesToken, _sharesAmount);
	}

	/**
	 * @dev Initiates the liquidity pool migration by setting a funds
	 *      recipent and starting the clock towards the 7-day grace period.
	 *      This method is exposed publicly.
	 * @param _migrationRecipient The recipient address to where funds will
	 *                            be transfered.
	 */
	function initiatePoolMigration(Self storage _self, address _migrationRecipient) public
	{
		require(_self.state == State.Allocated || _self.state == State.Migrated, "migration unavailable");
		_self.state = State.Migrating;
		_self.migrationRecipient = _migrationRecipient;
		_self.migrationUnlockTime = now + MIGRATION_INTERVAL;
	}

	/**
	 * @dev Cancels the liquidity pool migration by reseting the procedure
	 *      to its original state. This method is exposed publicly.
	 * @return _migrationRecipient The address of the former recipient.
	 */
	function cancelPoolMigration(Self storage _self) public returns (address _migrationRecipient)
	{
		require(_self.state == State.Migrating, "migration not initiated");
		_migrationRecipient = _self.migrationRecipient;
		_self.state = State.Allocated;
		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
		return _migrationRecipient;
	}

	/**
	 * @dev Completes the liquidity pool migration by redeeming all funds
	 *      from the pool. This method does not actually transfer the
	 *      redemeed funds to the recipient, it assumes the caller contract
	 *      will perform that. This method is exposed publicly.
	 * @return _migrationRecipient The address of the recipient.
	 * @return _stakesAmount The amount of stakes (GRO) redeemed from the pool.
	 * @return _sharesAmount The amount of shares (gToken) redeemed from the pool.
	 */
	function completePoolMigration(Self storage _self) public returns (address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_self.state == State.Migrating, "migration not initiated");
		require(now >= _self.migrationUnlockTime, "must wait lock interval");
		_migrationRecipient = _self.migrationRecipient;
		_self.state = State.Migrated;
		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
		(_stakesAmount, _sharesAmount) = G.exitPool(_self.liquidityPool, 1e18);
		return (_migrationRecipient, _stakesAmount, _sharesAmount);
	}

	/**
	 * @dev Verifies whether or not a liquidity pool has been allocated.
	 * @return _poolAvailable A boolean indicating whether or not the pool
	 *                        is available.
	 */
	function _hasPool(Self storage _self) internal view returns (bool _poolAvailable)
	{
		return _self.state != State.Created;
	}
}

// File: contracts/GCLeveragedReserveManager.sol

pragma solidity ^0.6.0;

/**
 * @dev This library implements data structure abstraction for the leveraged
 *      reserve management code in order to circuvent the EVM contract size limit.
 *      It is therefore a public library shared by all gToken Type 1 contracts and
 *      needs to be published alongside them. See GTokenType1.sol for further
 *      documentation.
 */
library GCLeveragedReserveManager
{
	using SafeMath for uint256;
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	uint256 constant MAXIMUM_COLLATERALIZATION_RATIO = 98e16; // 98% of 75% = 73.5%
	uint256 constant DEFAULT_COLLATERALIZATION_RATIO = 94e16; // 94% of 75% = 70.5%
	uint256 constant DEFAULT_COLLATERALIZATION_MARGIN = 2e16; // 2% of 75% = 1.5%

	struct Self {
		address reserveToken;
		address underlyingToken;

		address exchange;

		address miningToken;
		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		uint256 collateralizationRatio;
		uint256 collateralizationMargin;
	}

	/**
	 * @dev Initializes the data structure. This method is exposed publicly.
	 * @param _reserveToken The ERC-20 token address of the reserve token (cToken).
	 * @param _underlyingToken The ERC-20 token address of the underlying
	 *                         token that backs up the reserve token.
	 * @param _miningToken The ERC-20 token address to be collected from
	 *                     liquidity mining (COMP).
	 */
	function init(Self storage _self, address _reserveToken, address _underlyingToken, address _miningToken) public
	{
		_self.reserveToken = _reserveToken;
		_self.underlyingToken = _underlyingToken;

		_self.exchange = address(0);

		_self.miningToken = _miningToken;
		_self.miningMinGulpAmount = 0;
		_self.miningMaxGulpAmount = 0;

		_self.collateralizationRatio = DEFAULT_COLLATERALIZATION_RATIO;
		_self.collateralizationMargin = DEFAULT_COLLATERALIZATION_MARGIN;

		G.safeEnter(_reserveToken);
	}

	/**
	 * @dev Sets the contract address for asset conversion delegation.
	 *      This library converts the miningToken into the underlyingToken
	 *      and use the assets to back the reserveToken. See GExchange.sol
	 *      for further documentation. This method is exposed publicly.
	 * @param _exchange The address of the contract that implements the
	 *                  GExchange interface.
	 */
	function setExchange(Self storage _self, address _exchange) public
	{
		_self.exchange = _exchange;
	}

	/**
	 * @dev Sets the range for converting liquidity mining assets. This
	 *      method is exposed publicly.
	 * @param _miningMinGulpAmount The minimum amount, funds will only be
	 *                             converted once the minimum is accumulated.
	 * @param _miningMaxGulpAmount The maximum amount, funds beyond this
	 *                             limit will not be converted and are left
	 *                             for future rounds of conversion.
	 */
	function setMiningGulpRange(Self storage _self, uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public
	{
		require(_miningMinGulpAmount <= _miningMaxGulpAmount, "invalid range");
		_self.miningMinGulpAmount = _miningMinGulpAmount;
		_self.miningMaxGulpAmount = _miningMaxGulpAmount;
	}

	/**
	 * @dev Sets the collateralization ratio and margin. These values are
	 *      percentual and relative to the maximum collateralization ratio
	 *      provided by the underlying asset. This method is exposed publicly.
	 * @param _collateralizationRatio The target collateralization ratio,
	 *                                between lend and borrow, that the
	 *                                reserve will try to maintain.
	 * @param _collateralizationMargin The deviation from the target ratio
	 *                                 that should be accepted.
	 */
	function setCollateralizationRatio(Self storage _self, uint256 _collateralizationRatio, uint256 _collateralizationMargin) public
	{
		require(_collateralizationMargin <= _collateralizationRatio && _collateralizationRatio.add(_collateralizationMargin) <= MAXIMUM_COLLATERALIZATION_RATIO, "invalid ratio");
		_self.collateralizationRatio = _collateralizationRatio;
		_self.collateralizationMargin = _collateralizationMargin;
	}

	/**
	 * @dev Performs the reserve adjustment actions leaving a liquidity room,
	 *      if necessary. It will attempt to incorporate the liquidity mining
	 *      assets into the reserve and adjust the collateralization
	 *      targeting the configured ratio. This method is exposed publicly.
	 * @param _roomAmount The underlying token amount to be available after the
	 *                    operation. This is revelant for withdrawals, once the
	 *                    room amount is withdrawn the reserve should reflect
	 *                    the configured collateralization ratio.
	 * @return _success A boolean indicating whether or not both actions suceeded.
	 */
	function adjustReserve(Self storage _self, uint256 _roomAmount) public returns (bool _success)
	{
		bool success1 = _self._gulpMiningAssets();
		bool success2 = _self._adjustLeverage(_roomAmount);
		return success1 && success2;
	}

	/**
	 * @dev Calculates the collateralization ratio and range relative to the
	 *      maximum collateralization ratio provided by the underlying asset.
	 * @return _collateralizationRatio The target absolute collateralization ratio.
	 * @return _minCollateralizationRatio The minimum absolute collateralization ratio.
	 * @return _maxCollateralizationRatio The maximum absolute collateralization ratio.
	 */
	function _calcCollateralizationRatio(Self storage _self) internal view returns (uint256 _collateralizationRatio, uint256 _minCollateralizationRatio, uint256 _maxCollateralizationRatio)
	{
		uint256 _collateralRatio = G.getCollateralRatio(_self.reserveToken);
		_collateralizationRatio = _collateralRatio.mul(_self.collateralizationRatio).div(1e18);
		_minCollateralizationRatio = _collateralRatio.mul(_self.collateralizationRatio.sub(_self.collateralizationMargin)).div(1e18);
		_maxCollateralizationRatio = _collateralRatio.mul(_self.collateralizationRatio.add(_self.collateralizationMargin)).div(1e18);
		return (_collateralizationRatio, _minCollateralizationRatio, _maxCollateralizationRatio);
	}

	/**
	 * @dev Incorporates the liquidity mining assets into the reserve. Assets
	 *      are converted to the underlying asset and then added to the reserve.
	 *      If the amount available is below the minimum, or if the exchange
	 *      contract is not set, nothing is done. Otherwise the operation is
	 *      performed, limited to the maximum amount. Note that this operation
	 *      will incorporate to the reserve all the underlying token balance
	 *      including funds sent to it or left over somehow.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _gulpMiningAssets(Self storage _self) internal returns (bool _success)
	{
		if (_self.exchange == address(0)) return true;
		uint256 _miningAmount = G.getBalance(_self.miningToken);
		if (_miningAmount == 0) return true;
		if (_miningAmount < _self.miningMinGulpAmount) return true;
		_self._convertMiningToUnderlying(G.min(_miningAmount, _self.miningMaxGulpAmount));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	/**
	 * @dev Adjusts the reserve to match the configured collateralization
	 *      ratio. It calculates how much the collateralization must be
	 *      increased or decreased and either: 1) lend/borrow, or
	 *      2) repay/redeem, respectivelly. The funds required to perform
	 *      the operation are obtained via FlashLoan to avoid having to
	 *      maneuver around margin when moving in/out of leverage.
	 * @param _roomAmount The amount of underlying token to be liquid after
	 *                    the operation.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _adjustLeverage(Self storage _self, uint256 _roomAmount) internal returns (bool _success)
	{
		// the reserve is the diference between lend and borrow
		uint256 _lendAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _borrowAmount = G.fetchBorrowAmount(_self.reserveToken);
		uint256 _reserveAmount = _lendAmount.sub(_borrowAmount);
		// caps the room in case it is larger than the reserve
		_roomAmount = G.min(_roomAmount, _reserveAmount);
		// The new reserve must deduct the room requested
		uint256 _newReserveAmount = _reserveAmount.sub(_roomAmount);
		// caculates the assumed lend amount deducting the requested room
		uint256 _oldLendAmount = _lendAmount.sub(_roomAmount);
		// the new lend amount is the new reserve with leverage applied
		uint256 _newLendAmount;
		uint256 _minNewLendAmount;
		uint256 _maxNewLendAmount;
		{
			(uint256 _collateralizationRatio, uint256 _minCollateralizationRatio, uint256 _maxCollateralizationRatio) = _self._calcCollateralizationRatio();
			_newLendAmount = _newReserveAmount.mul(1e18).div(uint256(1e18).sub(_collateralizationRatio));
			_minNewLendAmount = _newReserveAmount.mul(1e18).div(uint256(1e18).sub(_minCollateralizationRatio));
			_maxNewLendAmount = _newReserveAmount.mul(1e18).div(uint256(1e18).sub(_maxCollateralizationRatio));
		}
		// adjust the reserve by:
		// 1- increasing collateralization by the difference
		// 2- decreasing collateralization by the difference
		if (_minNewLendAmount > _oldLendAmount) return _self._dispatchFlashLoan(_newLendAmount.sub(_oldLendAmount), 1);
		if (_maxNewLendAmount < _oldLendAmount) return _self._dispatchFlashLoan(_oldLendAmount.sub(_newLendAmount), 2);
		return true;
	}

	/**
	 * @dev This is the continuation of _adjustLeverage once funds are
	 *      borrowed via the FlashLoan callback.
	 * @param _amount The borrowed amount as requested.
	 * @param _fee The additional fee that needs to be paid for the FlashLoan.
	 * @param _which A flag indicating whether the funds were borrowed to
	 *               1) increase or 2) decrease the collateralization ratio.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _continueAdjustLeverage(Self storage _self, uint256 _amount, uint256 _fee, uint256 _which) internal returns (bool _success)
	{
		// note that the reserve adjustment is not 100% accurate as we
		// did not account for FlashLoan fees in the initial calculation
		if (_which == 1) {
			bool _success1 = G.lend(_self.reserveToken, _amount.sub(_fee));
			bool _success2 = G.borrow(_self.reserveToken, _amount);
			return _success1 && _success2;
		}
		if (_which == 2) {
			bool _success1 = G.repay(_self.reserveToken, _amount);
			bool _success2 = G.redeem(_self.reserveToken, _amount.add(_fee));
			return _success1 && _success2;
		}
		assert(false);
	}

	/**
	 * @dev Abstracts the details of dispatching the FlashLoan by encoding
	 *      the extra parameters.
	 * @param _amount The amount to be borrowed.
	 * @param _which A flag indicating whether the funds are borrowed to
	 *               1) increase or 2) decrease the collateralization ratio.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _dispatchFlashLoan(Self storage _self, uint256 _amount, uint256 _which) internal returns (bool _success)
	{
		return G.requestFlashLoan(_self.underlyingToken, _amount, abi.encode(_which));
	}

	/**
	 * @dev Abstracts the details of receiving a FlashLoan by decoding
	 *      the extra parameters.
	 * @param _token The asset being borrowed.
	 * @param _amount The borrowed amount.
	 * @param _fee The fees to be paid along with the borrowed amount.
	 * @param _params Additional encoded parameters to be decoded.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _receiveFlashLoan(Self storage _self, address _token, uint256 _amount, uint256 _fee, bytes memory _params) external returns (bool _success)
	{
		assert(_token == _self.underlyingToken);
		uint256 _which = abi.decode(_params, (uint256));
		return _self._continueAdjustLeverage(_amount, _fee, _which);
	}

	/**
	 * @dev Converts a given amount of the mining token to the underlying
	 *      token using the external exchange contract. Both amounts are
	 *      deducted and credited, respectively, from the current contract.
	 * @param _inputAmount The amount to be converted.
	 */
	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.dynamicConvertFunds(_self.exchange, _self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}
}

// File: contracts/GTokenBase.sol

pragma solidity ^0.6.0;

/**
 * @notice This abstract contract provides the basis implementation for all
 *         gTokens. It extends the ERC20 functionality by implementing all
 *         the methods of the GToken interface. The gToken basic functionality
 *         comprises of a reserve, provided in the reserve token, and a supply
 *         of shares. Every time someone deposits into the contract some amount
 *         of reserve tokens it will receive a given amount of this gToken
 *         shares. Conversely, upon withdrawal, someone redeems their previously
 *         deposited assets by providing the associated amount of gToken shares.
 *         The nominal price of a gToken is given by the ratio between the
 *         reserve balance and the total supply of shares. Upon deposit and
 *         withdrawal of funds a 1% fee is applied and collected from shares.
 *         Half of it is immediately burned, which is equivalent to
 *         redistributing it to all gToken holders, and the other half is
 *         provided to a liquidity pool configured as a 50% GRO/50% gToken with
 *         a 10% swap fee. Every week a percentage of the liquidity pool is
 *         burned to account for the accumulated swap fees for that period.
 *         Finally, the gToken contract provides functionality to migrate the
 *         total amount of funds locked in the liquidity pool to an external
 *         address, this mechanism is provided to facilitate the upgrade of
 *         this gToken contract by future implementations. After migration has
 *         started the fee for deposits becomes 2% and the fee for withdrawals
 *         becomes 0%, in order to incentivise others to follow the migration.
 */
abstract contract GTokenBase is ERC20, Ownable, ReentrancyGuard, GToken
{
	using GLiquidityPoolManager for GLiquidityPoolManager.Self;

	uint256 constant DEPOSIT_FEE = 1e16; // 1%
	uint256 constant WITHDRAWAL_FEE = 1e16; // 1%
	uint256 constant DEPOSIT_FEE_AFTER_MIGRATION = 2e16; // 2%
	uint256 constant WITHDRAWAL_FEE_AFTER_MIGRATION = 0e16; // 0%

	address public immutable override stakesToken;
	address public immutable override reserveToken;

	GLiquidityPoolManager.Self lpm;

	/**
	 * @dev Constructor for the gToken contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken)
		ERC20(_name, _symbol) public
	{
		_setupDecimals(_decimals);
		stakesToken = _stakesToken;
		reserveToken = _reserveToken;
		lpm.init(_stakesToken, address(this));
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         received/minted upon depositing to the contract.
	 * @param _cost The amount of reserve token being deposited.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @return _netShares The net amount of shares being received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of
	 *         reserve token to be deposited in order to receive the desired
	 *         amount of shares.
	 * @param _netShares The amount of this gToken shares to receive.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @return _cost The cost, in the reserve token, to be paid.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         given/burned upon withdrawing from the contract.
	 * @param _cost The amount of reserve token being withdrawn.
	 * @param _totalReserve The reserve balance as obtained by totalReserve()
	 * @param _totalSupply The shares supply as obtained by totalSupply()
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee()
	 * @return _grossShares The total amount of shares being deducted,
	 *                      including fees.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of
	 *         reserve token to be withdrawn given the desired amount of
	 *         shares.
	 * @param _grossShares The amount of this gToken shares to provide.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee().
	 * @return _cost The cost, in the reserve token, to be received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @notice Provides the amount of reserve tokens currently being help by
	 *         this contract.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's balance.
	 */
	function totalReserve() public view virtual override returns (uint256 _totalReserve)
	{
		return G.getBalance(reserveToken);
	}

	/**
	 * @notice Provides the current minting/deposit fee. This fee is
	 *         applied to the amount of this gToken shares being created
	 *         upon deposit. The fee defaults to 1% and is set to 2%
	 *         after the liquidity pool has been migrated.
	 * @return _depositFee A percent value that accounts for the percentage
	 *                     of shares being minted at each deposit that be
	 *                     collected as fee.
	 */
	function depositFee() public view override returns (uint256 _depositFee) {
		return lpm.hasMigrated() ? DEPOSIT_FEE_AFTER_MIGRATION : DEPOSIT_FEE;
	}

	/**
	 * @notice Provides the current burning/withdrawal fee. This fee is
	 *         applied to the amount of this gToken shares being redeemed
	 *         upon withdrawal. The fee defaults to 1% and is set to 0%
	 *         after the liquidity pool is migrated.
	 * @return _withdrawalFee A percent value that accounts for the
	 *                        percentage of shares being burned at each
	 *                        withdrawal that be collected as fee.
	 */
	function withdrawalFee() public view override returns (uint256 _withdrawalFee) {
		return lpm.hasMigrated() ? WITHDRAWAL_FEE_AFTER_MIGRATION : WITHDRAWAL_FEE;
	}

	/**
	 * @notice Provides the address of the liquidity pool contract.
	 * @return _liquidityPool An address identifying the liquidity pool.
	 */
	function liquidityPool() public view override returns (address _liquidityPool)
	{
		return lpm.liquidityPool;
	}

	/**
	 * @notice Provides the percentage of the liquidity pool to be burned.
	 *         This amount should account approximately for the swap fees
	 *         collected by the liquidity pool during a 7-day period.
	 * @return _burningRate A percent value that corresponds to the current
	 *                      amount of the liquidity pool to be burned at
	 *                      each 7-day cycle.
	 */
	function liquidityPoolBurningRate() public view override returns (uint256 _burningRate)
	{
		return lpm.burningRate;
	}

	/**
	 * @notice Marks when the last liquidity pool burn took place. There is
	 *         a minimum 7-day grace period between consecutive burnings of
	 *         the liquidity pool.
	 * @return _lastBurningTime A timestamp for when the liquidity pool
	 *                          burning took place for the last time.
	 */
	function liquidityPoolLastBurningTime() public view override returns (uint256 _lastBurningTime)
	{
		return lpm.lastBurningTime;
	}

	/**
	 * @notice Provides the address receiving the liquidity pool migration.
	 * @return _migrationRecipient An address to which funds will be sent
	 *                             upon liquidity pool migration completion.
	 */
	function liquidityPoolMigrationRecipient() public view override returns (address _migrationRecipient)
	{
		return lpm.migrationRecipient;
	}

	/**
	 * @notice Provides the timestamp for when the liquidity pool migration
	 *         can be completed.
	 * @return _migrationUnlockTime A timestamp that defines the end of the
	 *                              7-day grace period for liquidity pool
	 *                              migration.
	 */
	function liquidityPoolMigrationUnlockTime() public view override returns (uint256 _migrationUnlockTime)
	{
		return lpm.migrationUnlockTime;
	}

	/**
	 * @notice Performs the minting of gToken shares upon the deposit of the
	 *         reserve token. The actual number of shares being minted can
	 *         be calculated using the calcDepositSharesFromCost function.
	 *         In every deposit, 1% of the shares is retained in terms of
	 *         deposit fee. Half of it is immediately burned and the other
	 *         half is provided to the locked liquidity pool. The funds
	 *         will be pulled in by this contract, therefore they must be
	 *         previously approved.
	 * @param _cost The amount of reserve token being deposited in the
	 *              operation.
	 */
	function deposit(uint256 _cost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "cost must be greater than 0");
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		G.pullFunds(reserveToken, _from, _cost);
		require(_prepareDeposit(_cost), "not available at the moment");
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}

	/**
	 * @notice Performs the burning of gToken shares upon the withdrawal of
	 *         the reserve token. The actual amount of the reserve token to
	 *         be received can be calculated using the
	 *         calcWithdrawalCostFromShares function. In every withdrawal,
	 *         1% of the shares is retained in terms of withdrawal fee.
	 *         Half of it is immediately burned and the other half is
	 *         provided to the locked liquidity pool.
	 * @param _grossShares The gross amount of this gToken shares being
	 *                     redeemed in the operation.
	 */
	function withdraw(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		require(_cost > 0, "cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "not available at the moment");
		_cost = G.min(_cost, G.getBalance(reserveToken));
		G.pushFunds(reserveToken, _from, _cost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}

	/**
	 * @notice Allocates a liquidity pool with the given amount of funds and
	 *         locks it to this contract. This function should be called
	 *         shortly after the contract is created to associated a newly
	 *         created liquidity pool to it, which will collect fees
	 *         associated with the minting and burning of this gToken shares.
	 *         The liquidity pool will consist of a 50%/50% balance of the
	 *         stakes token (GRO) and this gToken shares with a swap fee of
	 *         10%. The rate between the amount of the two assets deposited
	 *         via this function defines the initial price. The minimum
	 *         amount to be provided for each is 1,000,000 wei. The funds
	 *         will be pulled in by this contract, therefore they must be
	 *         previously approved. This is a priviledged function
	 *         restricted to the contract owner.
	 * @param _stakesAmount The initial amount of stakes token.
	 * @param _sharesAmount The initial amount of this gToken shares.
	 */
	function allocateLiquidityPool(uint256 _stakesAmount, uint256 _sharesAmount) public override onlyOwner nonReentrant
	{
		address _from = msg.sender;
		G.pullFunds(stakesToken, _from, _stakesAmount);
		_transfer(_from, address(this), _sharesAmount);
		lpm.allocatePool(_stakesAmount, _sharesAmount);
	}

	/**
	 * @notice Changes the percentual amount of the funds to be burned from
	 *         the liquidity pool at each 7-day period. This is a
	 *         priviledged function restricted to the contract owner.
	 * @param _burningRate The percentage of the liquidity pool to be burned.
	 */
	function setLiquidityPoolBurningRate(uint256 _burningRate) public override onlyOwner nonReentrant
	{
		lpm.setBurningRate(_burningRate);
	}

	/**
	 * @notice Burns part of the liquidity pool funds decreasing the supply
	 *         of both the stakes token and this gToken shares.
	 *         The amount to be burned is set via the function
	 *         setLiquidityPoolBurningRate and defaults to 0.5%.
	 *         After this function is called there must be a 7-day wait
	 *         period before it can be called again.
	 *         The purpose of this function is to burn the aproximate amount
	 *         of fees collected from swaps that take place in the liquidity
	 *         pool during the previous 7-day period. This function will
	 *         emit a BurnLiquidityPoolPortion event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 */
	function burnLiquidityPoolPortion() public override onlyOwner nonReentrant
	{
		(uint256 _stakesAmount, uint256 _sharesAmount) = lpm.burnPoolPortion();
		_burnStakes(_stakesAmount);
		_burn(address(this), _sharesAmount);
		emit BurnLiquidityPoolPortion(_stakesAmount, _sharesAmount);
	}

	/**
	 * @notice Initiates the liquidity pool migration. It consists of
	 *         setting the migration recipient address and starting a
	 *         7-day grace period. After the 7-day grace period the
	 *         migration can be completed via the
	 *         completeLiquidityPoolMigration fuction. Anytime before
	 *         the migration is completed is can be cancelled via
	 *         cancelLiquidityPoolMigration. This function will emit a
	 *         InitiateLiquidityPoolMigration event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 * @param _migrationRecipient The receiver of the liquidity pool funds.
	 */
	function initiateLiquidityPoolMigration(address _migrationRecipient) public override onlyOwner nonReentrant
	{
		lpm.initiatePoolMigration(_migrationRecipient);
		emit InitiateLiquidityPoolMigration(_migrationRecipient);
	}

	/**
	 * @notice Cancels the liquidity pool migration if it has been already
	 *         initiated. This will reset the state of the liquidity pool
	 *         migration. This function will emit a
	 *         CancelLiquidityPoolMigration event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 */
	function cancelLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		address _migrationRecipient = lpm.cancelPoolMigration();
		emit CancelLiquidityPoolMigration(_migrationRecipient);
	}

	/**
	 * @notice Completes the liquidity pool migration at least 7-days after
	 *         it has been started. The migration consists of sendind the
	 *         the full balance held in the liquidity pool, both in the
	 *         stakes token and gToken shares, to the address set when
	 *         the migration was initiated. This function will emit a
	 *         CompleteLiquidityPoolMigration event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 */
	function completeLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		(address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount) = lpm.completePoolMigration();
		G.pushFunds(stakesToken, _migrationRecipient, _stakesAmount);
		_transfer(address(this), _migrationRecipient, _sharesAmount);
		emit CompleteLiquidityPoolMigration(_migrationRecipient, _stakesAmount, _sharesAmount);
	}

	/**
	 * @dev This abstract method must be implemented by subcontracts in
	 *      order to adjust the underlying reserve after a deposit takes
	 *      place. The actual implementation depends on the strategy and
	 *      algorithm used to handle the reserve.
	 * @param _cost The amount of the reserve token being deposited.
	 */
	function _prepareDeposit(uint256 _cost) internal virtual returns (bool _success);

	/**
	 * @dev This abstract method must be implemented by subcontracts in
	 *      order to adjust the underlying reserve before a withdrawal takes
	 *      place. The actual implementation depends on the strategy and
	 *      algorithm used to handle the reserve.
	 * @param _cost The amount of the reserve token being withdrawn.
	 */
	function _prepareWithdrawal(uint256 _cost) internal virtual returns (bool _success);

	/**
	 * @dev Burns the given amount of the stakes token. The default behavior
	 *      of the function for general ERC-20 is to send the funds to
	 *      address(0), but that can be overriden by a subcontract.
	 * @param _stakesAmount The amount of the stakes token being burned.
	 */
	function _burnStakes(uint256 _stakesAmount) internal virtual
	{
		G.pushFunds(stakesToken, address(0), _stakesAmount);
	}
}

// File: contracts/GCTokenBase.sol

pragma solidity ^0.6.0;

/**
 * @notice This abstract contract provides the basis implementation for all
 *         gcTokens, i.e. gTokens that use Compound cTokens as reserve, and
 *         implements the common functionality shared amongst them.
 *         In a nutshell, it extends the functinality of the GTokenBase contract
 *         to support operating directly using the cToken underlying asset.
 *         Therefore this contract provides functions that encapsulate minting
 *         and redeeming of cTokens internally, allowing users to interact with
 *         the contract providing funds directly in their underlying asset.
 */
abstract contract GCTokenBase is GTokenBase, GCToken
{
	address public immutable override miningToken;
	address public immutable override growthToken;
	address public immutable override underlyingToken;

	/**
	 * @dev Constructor for the gcToken contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 * @param _miningToken The ERC-20 token used for liquidity mining on
	 *                     compound (COMP).
	 * @param _growthToken The ERC-20 token address of the associated
	 *                     gcToken Type 1, for gcTokens Type 2, or address(0),
	 *                     if this contract is a gcToken Type 1.
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken, address _miningToken, address _growthToken)
		GTokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken) public
	{
		miningToken = _miningToken;
		growthToken = _growthToken;
		address _underlyingToken = G.getUnderlyingToken(_reserveToken);
		underlyingToken = _underlyingToken;
	}

	/**
	 * @notice Allows for the beforehand calculation of the cToken amount
	 *         given the amount of the underlying token and an exchange rate.
	 * @param _underlyingCost The cost in terms of the cToken underlying asset.
	 * @param _exchangeRate The given exchange rate as provided by exchangeRate().
	 * @return _cost The equivalent cost in terms of cToken
	 */
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) public pure override returns (uint256 _cost)
	{
		return GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of the underlying token
	 *         amount given the cToken amount and an exchange rate.
	 * @param _cost The cost in terms of the cToken.
	 * @param _exchangeRate The given exchange rate as provided by exchangeRate().
	 * @return _underlyingCost The equivalent cost in terms of the cToken underlying asset.
	 */
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost)
	{
		return GCFormulae._calcUnderlyingCostFromCost(_cost, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         received/minted upon depositing the underlying asset to the
	 *         contract.
	 * @param _underlyingCost The amount of the underlying asset being deposited.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _netShares The net amount of shares being received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return GCFormulae._calcDepositSharesFromUnderlyingCost(_underlyingCost, _totalReserve, _totalSupply, _depositFee, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of the
	 *         underlying asset to be deposited in order to receive the desired
	 *         amount of shares.
	 * @param _netShares The amount of this gcToken shares to receive.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _underlyingCost The cost, in the underlying asset, to be paid.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		return GCFormulae._calcDepositUnderlyingCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         given/burned upon withdrawing the underlying asset from the
	 *         contract.
	 * @param _underlyingCost The amount of the underlying asset being withdrawn.
	 * @param _totalReserve The reserve balance as obtained by totalReserve()
	 * @param _totalSupply The shares supply as obtained by totalSupply()
	 * @param _withdrawalFee The current withdrawl fee as obtained by withdrawalFee()
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _grossShares The total amount of shares being deducted,
	 *                      including fees.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return GCFormulae._calcWithdrawalSharesFromUnderlyingCost(_underlyingCost, _totalReserve, _totalSupply, _withdrawalFee, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of the
	 *         underlying asset to be withdrawn given the desired amount of
	 *         shares.
	 * @param _grossShares The amount of this gcToken shares to provide.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee().
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _underlyingCost The cost, in the underlying asset, to be received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		return GCFormulae._calcWithdrawalUnderlyingCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee, _exchangeRate);
	}

	/**
	 * @notice Provides the compound exchange rate since their last update.
	 * @return _exchangeRate The exchange rate between cToken and its
	 *                       underlying asset
	 */
	function exchangeRate() public view override returns (uint256 _exchangeRate)
	{
		return G.getExchangeRate(reserveToken);
	}

	/**
	 * @notice Provides the total amount kept in the reserve in terms of the
	 *         underlying asset.
	 * @return _totalReserveUnderlying The underlying asset balance on reserve.
	 */
	function totalReserveUnderlying() public view virtual override returns (uint256 _totalReserveUnderlying)
	{
		return GCFormulae._calcUnderlyingCostFromCost(totalReserve(), exchangeRate());
	}

	/**
	 * @notice Provides the total amount of the underlying asset (or equivalent)
	 *         this contract is currently lending on Compound.
	 * @return _lendingReserveUnderlying The underlying asset lending
	 *                                   balance on Compound.
	 */
	function lendingReserveUnderlying() public view virtual override returns (uint256 _lendingReserveUnderlying)
	{
		return G.getLendAmount(reserveToken);
	}

	/**
	 * @notice Provides the total amount of the underlying asset (or equivalent)
	 *         this contract is currently borrowing on Compound.
	 * @return _borrowingReserveUnderlying The underlying asset borrowing
	 *                                     balance on Compound.
	 */
	function borrowingReserveUnderlying() public view virtual override returns (uint256 _borrowingReserveUnderlying)
	{
		return G.getBorrowAmount(reserveToken);
	}

	/**
	 * @notice Performs the minting of gcToken shares upon the deposit of the
	 *         cToken underlying asset. The funds will be pulled in by this
	 *         contract, therefore they must be previously approved. This
	 *         function builds upon the GTokenBase deposit function. See
	 *         GTokenBase.sol for further documentation.
	 * @param _underlyingCost The amount of the underlying asset being
	 *                        deposited in the operation.
	 */
	function depositUnderlying(uint256 _underlyingCost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		uint256 _cost = GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, exchangeRate());
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		G.pullFunds(underlyingToken, _from, _underlyingCost);
		G.safeLend(reserveToken, _underlyingCost);
		require(_prepareDeposit(_cost), "not available at the moment");
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}

	/**
	 * @notice Performs the burning of gcToken shares upon the withdrawal of
	 *         the underlying asset. This function builds upon the
	 *         GTokenBase withdrawal function. See GTokenBase.sol for
	 *         further documentation.
	 * @param _grossShares The gross amount of this gcToken shares being
	 *                     redeemed in the operation.
	 */
	function withdrawUnderlying(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = GCFormulae._calcUnderlyingCostFromCost(_cost, exchangeRate());
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "not available at the moment");
		_underlyingCost = G.min(_underlyingCost, G.getLendAmount(reserveToken));
		G.safeRedeem(reserveToken, _underlyingCost);
		G.pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}
}

// File: contracts/GFlashBorrower.sol

pragma solidity ^0.6.0;

/**
 * @dev This abstract contract provides an uniform interface for receiving
 *      flash loans. It encapsulates the required functionality provided by
 *      both Aave and Dydx. It performs the basic validation to ensure that
 *      only Aave/Dydx contracts can dispatch the operation and only the
 *      current contract (that inherits from it) can initiate it.
 */
abstract contract GFlashBorrower is FlashLoanReceiver, ICallee
{
	using SafeMath for uint256;

	uint256 private allowOperationLevel = 0;

	/**
	 * @dev Handy definition to ensure that flash loans are only initiated
	 *      from within the current contract.
	 */
	modifier mayFlashBorrow()
	{
		allowOperationLevel++;
		_;
		allowOperationLevel--;
	}

	/**
	 * @dev Handles Aave callback. Delegates the processing of the funds
	 *      to the virtual function _processFlashLoan and later takes care
	 *      of paying it back.
	 * @param _token The ERC-20 contract address.
	 * @param _amount The amount being borrowed.
	 * @param _fee The fee, in addition to the amount borrowed, to be repaid.
	 * @param _params Additional user parameters provided when the flash
	 *                loan was requested.
	 */
	function executeOperation(address _token, uint256 _amount, uint256 _fee, bytes calldata _params) external override
	{
		assert(allowOperationLevel > 0);
		address _from = msg.sender;
		address _pool = $.Aave_AAVE_LENDING_POOL;
		assert(_from == _pool);
		require(_processFlashLoan(_token, _amount, _fee, _params)/*, "failure processing flash loan"*/);
		G.paybackFlashLoan(FlashLoans.Provider.Aave, _token, _amount.add(_fee));
	}

	/**
	 * @dev Handles Dydx callback. Delegates the processing of the funds
	 *      to the virtual function _processFlashLoan and later takes care
	 *      of paying it back.
	 * @param _sender The contract address of the initiator of the flash
	 *                loan, expected to be the current contract.
	 * @param _account Dydx account info provided in the callback.
	 * @param _data Aditional external data provided to the Dydx callback,
	 *              this is used by the Dydx module to pass the ERC-20 token
	 *              address, the amount and fee, as well as user parameters.
	 */
	function callFunction(address _sender, Account.Info memory _account, bytes memory _data) external override
	{
		assert(allowOperationLevel > 0);
		address _from = msg.sender;
		address _solo = $.Dydx_SOLO_MARGIN;
		assert(_from == _solo);
		assert(_sender == address(this));
		assert(_account.owner == address(this));
		(address _token, uint256 _amount, uint256 _fee, bytes memory _params) = abi.decode(_data, (address,uint256,uint256,bytes));
		require(_processFlashLoan(_token, _amount, _fee, _params)/*, "failure processing flash loan"*/);
		G.paybackFlashLoan(FlashLoans.Provider.Dydx, _token, _amount.add(_fee));
	}

	/**
	 * @dev Internal function that abstracts the algorithm to be performed
	 *      with borrowed funds. It receives the funds, deposited in the
	 *      current contract, and must ensure they are available as balance
	 *      of the current contract, including fees, before it returns.
	 * @param _token The ERC-20 contract address.
	 * @param _amount The amount being borrowed.
	 * @param _fee The fee, in addition to the amount borrowed, to be repaid.
	 * @param _params Additional user parameters provided when the flash
	 *                loan was requested.
	 * @return _success A boolean indicating success.
	 */
	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal virtual returns (bool _success);
}

// File: contracts/GCTokenType1.sol

pragma solidity ^0.6.0;

/**
 * @notice This contract implements the functionality for the gcToken Type 1.
 *         As with all gcTokens, gcTokens Type 1 use a Compound cToken as
 *         reserve token. Furthermore, Type 1 tokens may apply leverage to the
 *         reserve by using the cToken balance to borrow its associated
 *         underlying asset which in turn is used to mint more cToken. This
 *         process is performed to the limit where the actual reserve balance
 *         ends up accounting for the difference between the total amount lent
 *         and the total amount borrowed. One may observe that there is
 *         always a net loss when considering just the yield accrued for
 *         lending minus the yield accrued for borrowing on Compound. However,
 *         if we consider COMP being credited for liquidity mining the net
 *         balance may become positive and that is when the leverage mechanism
 *         should be applied. The COMP is periodically converted to the
 *         underlying asset and naturally becomes part of the reserve.
 *         In order to easily and efficiently adjust the leverage, this contract
 *         performs flash loans. See GCTokenBase, GFlashBorrower and
 *         GCLeveragedReserveManager for further documentation.
 */
contract GCTokenType1 is GCTokenBase, GFlashBorrower
{
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	GCLeveragedReserveManager.Self lrm;

	/**
	 * @dev Constructor for the gcToken Type 1 contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 * @param _miningToken The ERC-20 token used for liquidity mining on
	 *                     compound (COMP).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken, address _miningToken)
		GCTokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken, _miningToken, address(0)) public
	{
		address _underlyingToken = G.getUnderlyingToken(_reserveToken);
		lrm.init(_reserveToken, _underlyingToken, _miningToken);
	}

	/**
	 * @notice Overrides the default total reserve definition in order to
	 *         account only for the diference between assets being lent
	 *         and assets being borrowed.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's worth.
	 */
	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return GCFormulae._calcCostFromUnderlyingCost(totalReserveUnderlying(), exchangeRate());
	}

	/**
	 * @notice Overrides the default total underlying reserve definition in
	 *         order to account only for the diference between assets being
	 *         lent and assets being borrowed.
	 * @return _totalReserveUnderlying The amount of the underlying asset
	 *                                 corresponding to this contract's worth.
	 */
	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		return lendingReserveUnderlying().sub(borrowingReserveUnderlying());
	}

	/**
	 * @notice Provides the contract address for the GExchange implementation
	 *         currently being used to convert the mining token (COMP) into
	 *         the underlying asset.
	 * @return _exchange A GExchange compatible contract address, or address(0)
	 *                   if it has not been set.
	 */
	function exchange() public view override returns (address _exchange)
	{
		return lrm.exchange;
	}

	/**
	 * @notice Provides the minimum and maximum amount of the mining token to
	 *         be processed on every operation. If the contract balance
	 *         is below the minimum it waits until more accumulates.
	 *         If the total amount is beyond the maximum it processes the
	 *         maximum and leaf the rest for future operations. The mining
	 *         token accumulated via liquidity mining is converted to the
	 *         underlying asset and used to mint the associated cToken.
	 *         This range is used to avoid wasting gas converting small
	 *         amounts as well as mitigating slipage converting large amounts.
	 * @return _miningMinGulpAmount The minimum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 * @return _miningMaxGulpAmount The maximum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 */
	function miningGulpRange() public view override returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount)
	{
		return (lrm.miningMinGulpAmount, lrm.miningMaxGulpAmount);
	}

	/**
	 * @notice Provides the minimum and maximum amount of the gcToken Type 1 to
	 *         be processed on every operation. This method applies only to
	 *         gcTokens Type 2 and is not relevant for gcTokens Type 1.
	 * @return _growthMinGulpAmount The minimum amount of the gcToken Type 1
	 *                              to be processed per deposit/withdrawal
	 *                              (always 0).
	 * @return _growthMaxGulpAmount The maximum amount of the gcToken Type 1
	 *                              to be processed per deposit/withdrawal
	 *                              (always 0).
	 */
	function growthGulpRange() public view override returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount)
	{
		return (0, 0);
	}

	/**
	 * @notice Provides the target collateralization ratio and margin to be
	 *         maintained by this contract. The amount is relative to the
	 *         maximum collateralization available for the associated cToken
	 *         on Compound. The amount is relative to the maximum
	 *         collateralization available for the associated cToken
	 *         on Compound. gcToken Type 1 use leveraged collateralization
	 *         where the cToken is used to borrow its underlying token which
	 *         in turn is used to mint new cToken and repeat. This is
	 *         performed to the maximal level where the actual reserve
	 *         ends up corresponding to the difference between the amount
	 *         lent and the amount borrowed.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 96%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 0%)
	 */
	function collateralizationRatio() public view override returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin)
	{
		return (lrm.collateralizationRatio, lrm.collateralizationMargin);
	}

	/**
	 * @notice Sets the contract address for the GExchange implementation
	 *         to be used in converting the mining token (COMP) into
	 *         the underlying asset. This is a priviledged function
	 *         restricted to the contract owner.
	 * @param _exchange A GExchange compatible contract address.
	 */
	function setExchange(address _exchange) public override onlyOwner nonReentrant
	{
		lrm.setExchange(_exchange);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the mining token to
	 *         be processed on every operation. See miningGulpRange().
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _miningMinGulpAmount The minimum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 * @param _miningMaxGulpAmount The maximum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 */
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public override onlyOwner nonReentrant
	{
		lrm.setMiningGulpRange(_miningMinGulpAmount, _miningMaxGulpAmount);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the gcToken Type 1 to
	 *         be processed on every operation. This method applies only to
	 *         gcTokens Type 2 and is not relevant for gcTokens Type 1.
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _growthMinGulpAmount The minimum amount of the gcToken Type 1
	 *                             to be processed per deposit/withdrawal
	 *                             (ignored).
	 * @param _growthMaxGulpAmount The maximum amount of the gcToken Type 1
	 *                             to be processed per deposit/withdrawal
	 *                             (ignored).
	 */
	function setGrowthGulpRange(uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) public override /*onlyOwner nonReentrant*/
	{
		_growthMinGulpAmount; _growthMaxGulpAmount; // silences warnings
	}

	/**
	 * @notice Sets the target collateralization ratio and margin to be
	 *         maintained by this contract. See collateralizationRatio().
	 *         Setting both parameters to 0 turns off collateralization and
	 *         leveraging. This is a priviledged function restricted to the
	 *         contract owner.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 96%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 0%)
	 */
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) public override onlyOwner nonReentrant
	{
		lrm.setCollateralizationRatio(_collateralizationRatio, _collateralizationMargin);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      after a deposit comes along. It basically adjusts the
	 *      collateralization/leverage to reflect the new increased reserve
	 *      balance. This method uses the GCLeveragedReserveManager to
	 *      adjust the reserve and this is done via flash loans.
	 *      See GCLeveragedReserveManager().
	 * @param _cost The amount of reserve being deposited (ignored).
	 * @return _success A boolean indicating whether or not the operation
	 *                  succeeded. This operation should not fail unless
	 *                  any of the underlying components (Compound, Aave,
	 *                  Dydx) also fails.
	 */
	function _prepareDeposit(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		_cost; // silences warnings
		return lrm.adjustReserve(0);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      before a withdrawal comes along. It basically calculates the
	 *      the amount will be left in the reserve, in terms of cToken cost,
	 *      and adjusts the collateralization/leverage accordingly. This
	 *      method uses the GCLeveragedReserveManager to adjust the reserve
	 *      and this is done via flash loans. See GCLeveragedReserveManager().
	 * @param _cost The amount of reserve being withdrawn and that needs to
	 *              be immediately liquid.
	 * @return _success A boolean indicating whether or not the operation succeeded.
	 *                  The operation may fail if it is not possible to recover
	 *                  the required liquidity (e.g. low liquidity in the markets).
	 */
	function _prepareWithdrawal(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		return lrm.adjustReserve(GCFormulae._calcUnderlyingCostFromCost(_cost, G.fetchExchangeRate(reserveToken)));
	}

	/**
	 * @dev This method dispatches the flash loan callback back to the
	 *      GCLeveragedReserveManager library. See GCLeveragedReserveManager.sol
	 *      and GFlashBorrower.sol.
	 */
	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal override returns (bool _success)
	{
		return lrm._receiveFlashLoan(_token, _amount, _fee, _params);
	}
}

// File: contracts/GTokens.sol

pragma solidity ^0.6.0;

/**
 * @notice Definition of gcDAI. As a gcToken Type 1, it uses cDAI as reserve
 * and employs leverage to maximize returns.
 */
contract gcDAI is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
}