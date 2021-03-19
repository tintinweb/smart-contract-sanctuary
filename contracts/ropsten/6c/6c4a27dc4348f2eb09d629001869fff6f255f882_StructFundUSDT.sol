/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: contracts/@openzeppelin/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/@openzeppelin/math/Math.sol


pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    //rand() - added by Roc 20200907
    function rand(uint256 number) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        return random%number;
    }
}

// File: contracts/@openzeppelin/GSN/Context.sol


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

// File: contracts/@openzeppelin/token/ERC20/IERC20.sol


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

// File: contracts/@openzeppelin/utils/Address.sol


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

// File: contracts/@openzeppelin/token/ERC20/ERC20.sol


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

// File: contracts/@openzeppelin/token/ERC20/SafeERC20.sol


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

// File: contracts/@openzeppelin/access/Ownable.sol


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

    function isOwner(address addr) public view returns(bool){
        return _owner == addr;
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

// File: contracts/ProxyOwnable.sol

pragma solidity >=0.6.0 <0.7.0;



abstract contract ProxyOwnable is Context{
    Ownable _ownable;

    constructor() public{
        
    }

    function setOwnable(address ownable) internal{ //仅仅子类可调用
        require(ownable!=address(0),"setOwnable should not be 0");
        _ownable=Ownable(ownable);
    }

    modifier onlyOwner {
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        require(_ownable.isOwner(_msgSender()),"Not owner");
        _;
    }

    function owner() view public returns(address){
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        return _ownable.owner();
    }

    function isOwner(address addr) public view returns(bool){
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        return _ownable.isOwner(addr);
    }

}

// File: contracts/DSPausable.sol

pragma solidity >=0.6.0 <0.7.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract DSPausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

}

// File: contracts/DSToken.sol

pragma solidity >=0.6.0 <0.7.0;



//项目内所有token的合约，不同的token只是不同的合约实例。
//包括：项目代币STRUCT，母基金代币FDS，优先级分级基金代币PFDS，劣后级分级基金代币IFDS
//注意，不同币种又对应不同的代币token，在上述代币加后缀（后缀可以把相关的代币排序在一起）：USDT - SDTu,FDSu,PFDSu,IFDSu
//附加的功能：
//  1. 可燃烧（代币拥有者合约燃烧自己的代币）
//  2. 可铸造（合法的铸造者合约可以铸造，铸造者由管理员审核和注册）
contract DSToken is ERC20 , DSPausable
{
    mapping(address=>bool) private _minerMap;

    constructor(uint256 initialSupply,string memory tokenName,string memory tokenSymbol,uint8 decimals, address ownable) public
        ERC20(tokenName,tokenSymbol)
    {
        require(ownable!=address(0),"The ownable address should not be 0");
        _mint(_msgSender(), initialSupply);
        _setupDecimals(decimals);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
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
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function isMiner(address miner) public view returns (bool) {
        return _minerMap[miner];
    }

    //设置可挖矿账户地址
    function addMiners(address[] memory miners) external onlyOwner{
        for(uint256 i=0; i<miners.length; i++) {
            _minerMap[miners[i]] = true;
        }
    }

    //删除可挖矿账户地址
    function removeMiners(address[] memory miners) external onlyOwner{
        for(uint256 i=0; i<miners.length; i++){
            _minerMap[miners[i]] = false;
        }
    }

    modifier onlyMiner {
        require(_minerMap[_msgSender()]==true,"not miner");
        _;
    }

    function mint(address account, uint256 amount) public onlyMiner whenNotPaused{
        _mint(account, amount);
    }

}

// File: contracts/PurchaseQueue.sol

pragma solidity >=0.6.0 <0.7.0;


//申购动作，排队用
struct PurchaseAction
{
    address user;
    uint256 amount;
    uint256 timestamp;
}


struct QueueStruct {
    PurchaseAction[200] data;
    uint256 front;
    uint256 rear;
}


library Queue
{
    using SafeMath for uint256;

    // Queue length
    function length(QueueStruct storage q) view internal returns (uint256) {
        return q.rear - q.front;
    }

    // push
    function push(QueueStruct storage q, PurchaseAction memory data) internal
    {
        if ((q.rear + 1) % q.data.length == q.front)
            pop(q,0); // throw first;
        q.data[q.rear] = data;
        q.rear = (q.rear + 1) % q.data.length;
    }

    // pop (amount==0 表示整个最近一个排队项)
    //如果amount大于最近 的一个排队项，则pop此排队项。否则只部分pop此排队项（相当于改为剩余的数量，此排队项还是队列头）
    function pop(QueueStruct storage q,uint256 amount) internal returns (PurchaseAction memory )
    {
        require (q.rear != q.front,"Failed to pop from empty queue");
        PurchaseAction storage action = q.data[q.front];
        if (amount==0 || action.amount<=amount){
            PurchaseAction memory userAction=q.data[q.front];
            delete q.data[q.front];
            q.front = (q.front + 1) % q.data.length;
            return userAction;
        }else{ //amount 不足以pop队列头的action
            action.amount=action.amount.sub(amount);
            return PurchaseAction(action.user,amount,action.timestamp);
        }
    }

    function header(QueueStruct storage q) internal view returns(PurchaseAction memory){
        require (q.rear != q.front,"Failed to get header from empty queue");
        return q.data[q.front];
    }
}


contract PurchaseQueue
{
    using SafeMath for uint256;
    using Queue for QueueStruct;
    QueueStruct requests;
    mapping(address/*user*/=>uint256) _cancelledAmount;

    mapping(address=>uint256) userAmount;

    constructor(uint256 maxCount) public {
        //requests.data=new PurchaseAction[](maxCount);
    }

    function addRequest(address actionUser,uint256 actionAmount,uint256 actionTimestamp) public{
        requests.push(PurchaseAction(actionUser,actionAmount,actionTimestamp));
        userAmount[actionUser] = userAmount[actionUser].add(actionAmount);
    }

    //pop 出来的项的amount可能小于amount（需要外部loop处理）。
    //如果amount大于当前的项的amount，将只修改当前项的amount为剩余的值，不做真正的pop动作。看上去就像把当前项劈开为两个，而pop了前面的一个。
    function popRequest(uint256 amount) public returns (address actionUser,uint256 actionAmount,uint256 actionTimestamp) {
        require(requests.length()>0,"Empty queue");
        PurchaseAction memory action =requests.pop(amount);
        for (;_cancelledAmount[action.user]!=0;){//有预撤销记录
            if (action.amount>_cancelledAmount[action.user]){//当前项有剩余，修改当前项的amount并返回
                action.amount=action.amount.sub(_cancelledAmount[action.user]);
                _cancelledAmount[action.user]=0;
                break;
            }else{//skip 完整的当前项
                _cancelledAmount[action.user]=_cancelledAmount[action.user].sub(action.amount);
                action =requests.pop(amount);
            }
        }

        userAmount[actionUser] = userAmount[action.user].sub(action.amount);
        return (action.user,action.amount,action.timestamp);
    }

    function queueLength() view public returns (uint256) {
        return requests.length();
    }

    function getActionAmount(address user) view public returns(uint256){
        return userAmount[user];
    }

    function cancelRequest(address actionUser,uint256 actionAmount) public{
        require(userAmount[actionUser]>=actionAmount,"Not enough amount to cancel lineup");
        userAmount[actionUser]=userAmount[actionUser].sub(actionAmount);
        _cancelledAmount[actionUser]=_cancelledAmount[actionUser].add(actionAmount);  //先记录，避免loop查找。pop时候skip已经取消的item。
    }
}

// File: contracts/IVault.sol

pragma solidity >=0.6.0 <0.7.0;


//机枪池统一接口。不同的机枪池接口不同，每个对应一个adapter合约，从本接口继承。
abstract contract IVault {
    //申购
    function purchase(uint256 capitalAmount) public virtual returns(uint256) ; //返回此次调用新产生的机枪池token的数额
    //赎回
    function redeem(uint256 tokenAmount) public virtual;
//    //得到单位净值
//    function averageNAV() view public  virtual returns(uint256);
    //得到capitalToken
    function capitalTokenAddress() view public  virtual returns(address);
    //得到机枪池token地址
    function tokenAddress() view public  virtual returns(address);

//    //得到机枪池token的价格。即：获得一个机枪池token需要付出的资金token的数量（单位为 wei）或赎回一个机枪池token后得到的资金token的数量。
//    function queryPrice() view public virtual returns(uint256);

    function tokenAmount(address account) view public returns(uint256){
        ERC20 vaultToken=ERC20(tokenAddress());
        return vaultToken.balanceOf(account);
    }

    function capitalAmount(address account) view public returns(uint256){
        ERC20 capitalToken=ERC20(capitalTokenAddress());
        return capitalToken.balanceOf(account);
    }

}

// File: contracts/CtrlPanel.sol

pragma solidity >=0.6.0 <0.7.0;


contract CtrlPanel is Ownable{
    address  public structToken; //项目代币token


    constructor() public{

    }

    function setStructToken(address structTokenAddr) public{
        structToken=structTokenAddr;
    }



}

// File: contracts/StructFund.sol

pragma solidity >=0.6.0 <0.7.0;











contract StructFund is DSPausable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;
    using SafeERC20 for DSToken;

    enum Grade { Priority, Inferior } // 分级级别

    IVault public vault;  //对应的机枪池
    ERC20 public capitalToken; //资金币token合约

    //DSToken public structToken; //项目代币 //项目代币奖励通过一池实现

    //config
    uint256 public maxIssueAmount; //最大发行资金（
    uint256 public structFundRate; //优先级劣后级比例（比如: 3 = 3:1）

    uint256 public priorityAnnualizedReturn; //优先级固定年化收益

    uint256 public lockinTime; //封闭期开始时间
    uint256 public fixedDays ; //定期天数

    //member
    uint256 public currentIssueAmount; //当前已经发行资金

    //分级基金数据结构
    struct StructFundInfo
    {
        DSToken fdsToken; //基金token合约
        uint256 amount;  //排队资金总额
        PurchaseQueue bookkeeping; //排队的用户资金账本
        uint256 nav;            //净值，没有到期前为0
        uint256 settlementAmount; //结算后分得的资金额，没有到期前为0
    }

    //两个分级基金（0：优先级，1：劣后级）
    StructFundInfo[2]  public structFundInfos;

    bool public expired; //是否到期开放赎回
    //uint256 public expiredAverageNAV; //到期时机枪池的单位净值(*1000后的值)

    uint256 public principalAmount; //用户本金总额,不包括排队资金。只增不减
//    function lineupPrincipalAmount() view public returns(uint256){ //排队资金，暂存在本合约
//        //return _capitalToken.balanceOf(address(this));
//        return structFundInfos[0].amount.add(structFundInfos[1].amount);
//    }

    function totalLockedFundsAmount() view public returns(uint256){
        return principalAmount.add(structFundInfos[0].amount.add(structFundInfos[1].amount));
    }
    uint256 public expiredRevenueAmount; //总收益额（此基金计算后才有，否则为0）

    event IssueAmountChanged(uint256 currentIssueAmount_,uint256 maxIssueAmount_);
    event Purchased(Grade grade,address user,uint256 amount);
    event Redeemed(Grade grade,address user,uint256 amount);
    event LineupPurchased(Grade grade,address user,uint256 amount);
    event Expired();


    constructor(address vaultAddress,uint256 maxIssueAmount_,address priorityFdsToken,address inferiorFdsToken, address ctrlPanel) public{
        require(vaultAddress!=address(0));
        vault =IVault(vaultAddress);
        require(vault.capitalTokenAddress()!=address(0));
        capitalToken =ERC20(vault.capitalTokenAddress());

        maxIssueAmount =maxIssueAmount_;

        structFundInfos[uint256(Grade.Priority)]=StructFundInfo(DSToken(priorityFdsToken),0,new PurchaseQueue(2000),0,0);
        structFundInfos[uint256(Grade.Inferior)]=StructFundInfo(DSToken(inferiorFdsToken),0,new PurchaseQueue(2000),0,0);

        require(address(structFundInfos[uint256(Grade.Priority)].bookkeeping)!=address(0),"bookkeeping must be none zone");

        expired=false;
        structFundRate=3;
        priorityAnnualizedReturn=0.02 ether; //2%
        fixedDays=180; //半年
    }

    function capitalSymbol() view public returns(string memory){
        return capitalToken.symbol();
    }

    function setParams(uint256 structFundRate_,uint256 priorityAnnualizedReturn_,uint256 fixedDays_) external onlyOwner {
        structFundRate=structFundRate_;
        priorityAnnualizedReturn=priorityAnnualizedReturn_;
        fixedDays=fixedDays_;
    }

    //进入封闭期
    function lockin() public onlyOwner{
        lockinTime=now;
    }
 
    //到期时间
    function expiredTime() public view returns(uint256){
        return lockinTime.add(fixedDays.mul(86400));
    }

    //得到指定的发行量里面，指定的分级基金的按比例可以分得的发行量
    function _getCirculation(Grade grade,uint256 circulation) view internal returns(uint256){
        if (grade==Grade.Priority){
            return circulation.mul(structFundRate).div(structFundRate.add(1));
        }else{
            return circulation.div(structFundRate.add(1));
        }
    }



    function _purchaseFund(Grade grade,uint256 amount) internal {
        StructFundInfo storage fundInfo = structFundInfos[uint256(grade)];

        uint256 totalActionAmount = 0;
        uint256 todoAmount = amount;
        // while (totalActionAmount<amount){
        while (todoAmount > 0) {
            // (address actionUser,uint256 actionAmount,) = fundInfo.bookkeeping.popRequest(amount);
            (address actionUser,uint256 actionAmount,) = fundInfo.bookkeeping.popRequest(todoAmount);
            require(actionUser!=address(0),"action user is zero");
            require(actionAmount!=0,"action amount is zero");
            actionAmount = Math.min(actionAmount, todoAmount);

            //从资金队列转入当前合约；目前都是当前按合约，所以屏蔽下述语句
            //_capitalToken.transferFrom(_msgSender(),address(this),amount);
            //从当前合约转到机枪池(当前合约得到机枪池token)
            capitalToken.safeApprove(address(vault),actionAmount);
            uint256 actionVaultTokenAmount= vault.purchase(actionAmount);
            //产生分级基金token
            fundInfo.fdsToken.mint(actionUser,actionVaultTokenAmount);

            emit Purchased(Grade.Priority,actionUser,actionAmount);
            totalActionAmount=totalActionAmount.add(actionAmount);
            todoAmount = todoAmount.sub(actionAmount);
        }
        structFundInfos[uint256(grade)].amount=structFundInfos[uint256(grade)].amount.sub(amount);
        principalAmount = principalAmount.add(totalActionAmount);

        require(totalActionAmount==amount,"Internal error for _purchaseFund");
    }

    //根据amounts数组，分别执行两个分级基金的申购
    function _purchase(uint256 [2] memory amounts) internal {
        require(amounts[0]>0 && amounts[1]>0,"all amounts must be non-zero");
        uint256 totalAmount = amounts[0].add(amounts[1]);
        require(currentIssueAmount.add(totalAmount)<= maxIssueAmount,"Exceeding the maximum circulation");

        _purchaseFund(Grade.Priority,amounts[0]);
        _purchaseFund(Grade.Inferior,amounts[1]);

        currentIssueAmount = currentIssueAmount.add(totalAmount);
        emit IssueAmountChanged(currentIssueAmount, maxIssueAmount);
    }

    //根据现有排队情况，匹配找出总额
    function _getPurchaseValidAmount() view internal returns(uint256 [2] memory){
        if (structFundInfos[0].amount<= structFundInfos[1].amount.mul(structFundRate)){
            //优先排队资金量少，以优先为基本
            uint256 inferiorAmount = structFundInfos[0].amount.div(structFundRate);
            assert(inferiorAmount<= structFundInfos[1].amount);
            return [structFundInfos[0].amount, inferiorAmount];
        }else{
            //劣后排队资金量少，以劣后为基本
            assert(structFundInfos[1].amount*structFundRate<= structFundInfos[0].amount);
            return [structFundInfos[1].amount*structFundRate, structFundInfos[1].amount];
        }
    }


    function executePurchase() public whenNotPaused{
        uint256 [2] memory purchaseAmounts =_getPurchaseValidAmount();
        if (purchaseAmounts[1]>0){
            _purchase(purchaseAmounts);
        }
    }

//    //得到购买tokenAmount份数的基金需要付出的资金token的数量。
//    function queryPurchaseCost(uint256 tokenAmount) view public returns(uint256){
//        uint256 vaultTokenPrice=_vault.queryPrice();
//        uint256 amount=tokenAmount.mul(vaultTokenPrice);
//        return amount;
//    }

    //购买排队，先需要调用approve给当前合约。如果此次排队达成匹配，则触发真实购买动作。
    //第二个参数只能为资金token amount，如果为基金token amount，计算的资金token amount会和匹配时真实进入机枪池需要的不符合。它时变化的。
    function lineUpPurchase(Grade grade,uint256 amount) external whenNotPaused{
        require(amount>0);
        require(lockinTime==0,"Lock-in period");
        require(capitalToken.balanceOf(_msgSender())>=amount,"Insufficient capital available");
        require(expired==false,"Expired already");
        StructFundInfo storage fundInfo = structFundInfos[uint256(grade)];
        uint256 willQueuedAmount= fundInfo.amount.add(amount);

        require(_getCirculation(grade, currentIssueAmount.add(willQueuedAmount))<=_getCirculation(grade, maxIssueAmount),"Exceeding the maximum circulation");

        //转入相应资金到当前合约
        capitalToken.safeTransferFrom(_msgSender(),address(this),amount);//资金队列合约暂时为当前合约

        require(address(fundInfo.bookkeeping)!=address(0),"bookkeeping must be none zone");

        //排队
        fundInfo.bookkeeping.addRequest(_msgSender(),amount,now);
//        (address user,uint256 userAmount,uint256 ts) = fundInfo.bookkeeping.popRequest(amount);
//        require(user!=address(0),"user==address(0)");
//        require(userAmount!=0,"userAmount==0");
//        require(ts!=0,"ts==0");
//
//        fundInfo.bookkeeping.addRequest(_msgSender(),amount,now);
        //更新排队总资金俩
        fundInfo.amount= fundInfo.amount.add(amount);
        emit LineupPurchased(grade,_msgSender(),amount);
//
        executePurchase();//如果此次排队达成匹配，则触发真实购买动作。
    }


    function cancelLineupPurchase(Grade grade,uint256 amount) external whenNotPaused{
        StructFundInfo storage fundInfo = structFundInfos[uint256(grade)];
        fundInfo.bookkeeping.cancelRequest(_msgSender(),amount);
        fundInfo.amount = fundInfo.amount.sub(amount);
        capitalToken.transfer(_msgSender(),amount);
    }

    //到期，从机枪池提取资金。成功后开放赎回
    function expire() external onlyOwner {
        require(expired==false,"Expired already");
        //从机枪池赎回资金，到当前合约
        //TODO：需要先 approve() 机枪池token。
        //TODO：检查当前合约的机枪池token个数应该和currentCirculation一致

        require(now>=expiredTime(),"Lock-in period");

        IERC20 vaultToken=IERC20(vault.tokenAddress());

        uint256 lineupPrincipalAmount = capitalToken.balanceOf(address(this));
        uint256 vaultTokenBalance=vaultToken.balanceOf(address(this));
        vaultToken.safeApprove(address(vault),vaultTokenBalance); //把本合约的机枪池token approve给机枪池，以便赎回全部资金
        vault.redeem(vaultTokenBalance);
        uint256 totalAmount= capitalToken.balanceOf(address(this));
        expiredRevenueAmount = totalAmount.sub(lineupPrincipalAmount); //用户所有本金及其收益的总额

        //revenueTotal=newPrincipalAmount.sub(principalTotal); //更新收益
        //不清空 currentIssueAmount，保留以便查看

        //expiredAverageNAV= expiredRevenueAmount.mul(1e18).div(principalAmount);
        //(uint256 navPriority,uint256 navInferior)=calcNav(expiredAverageNAV);

        (uint256 settleAmountPriority,uint256 settleAmountInferior) = calcAmount(principalAmount, expiredRevenueAmount);

        //structFundInfos[uint256(Grade.Priority)].nav=navPriority;
        //structFundInfos[uint256(Grade.Inferior)].nav=navInferior;
        structFundInfos[uint256(Grade.Priority)].settlementAmount=settleAmountPriority;
        structFundInfos[uint256(Grade.Inferior)].settlementAmount=settleAmountInferior;

        expired=true;
        emit Expired();
    }

    // 重新打开，为了测试用
    function reOpen() external onlyOwner {
        expired = false;
        principalAmount = 0;
    }

    //根据原始本金和现在得到的金额（包含本金和收益）的情况，得到分级的两种基金的收益金额
    function calcAmount(uint256 beginAmount, uint256 endAmount) public view returns(uint256, uint256) {
        uint256 amtPriority; // amount of A-share, fixed-rate
        uint256 amtInferior; // amount of B-share
        uint256 daysPerYear = 365;
        // amtA = beginAmount*(1 + days/daysPerYear*rateA);

        uint256 beginAmtPriority = beginAmount.mul(structFundRate).div(structFundRate.add(1));
        // amtPriority = beginAmount.mul(fixedDays).mul(priorityAnnualizedReturn).div(daysPerYear).div(1 ether);
        amtPriority = beginAmtPriority.mul(fixedDays).mul(priorityAnnualizedReturn).div(daysPerYear).div(1 ether);        
        amtPriority = amtPriority.add(beginAmtPriority);
        // amtB = endAmount - amtA
        // navB = nav*(1+levB) - navA*levB;
        if (amtPriority > endAmount) {
            amtInferior = 0;
            amtPriority = endAmount;
        } else {
            amtInferior = endAmount.sub(amtPriority);
        }
        return (amtPriority, amtInferior);
    }

    function calcNav(uint256 vaultNav) public view returns(uint256, uint256) {
        uint256 navPriority; // nav of A-share, fixed-rate
        uint256 navInferior; // nav of B-share
        uint256 daysPerYear = 365;
        // navA = 1 + days/daysPerYear*rateA;
        navPriority = fixedDays.mul(priorityAnnualizedReturn).div(daysPerYear).add(1 ether);
        // navB = nav*(1+levB) - navA*levB;
        if (vaultNav.mul(structFundRate.add(1)) < navPriority.mul(structFundRate)) {
            navInferior = 0;
            navPriority = vaultNav.div(structFundRate);
        } else {
            navInferior = vaultNav.mul(structFundRate.add(1)).sub(navPriority.mul(structFundRate));
        }
        return (navPriority, navInferior);
    }


    //用户赎回
    function redeem(Grade grade,uint256 tokenAmount) external whenNotPaused{
        require(expired,"Not yet due");
        require(tokenAmount>0,"Amount must be >0");

        StructFundInfo storage fundInfo = structFundInfos[uint256(grade)];
        DSToken fdsToken= fundInfo.fdsToken;
        require(fdsToken.balanceOf(_msgSender())>=tokenAmount,"Insufficient amount");

        //
        uint256 amount=fundInfo.settlementAmount.mul(tokenAmount).div(fdsToken.totalSupply());

        //收回分级基金代币
        fdsToken.burnFrom(_msgSender(),tokenAmount);

        //从当前合约转出资金代币到用户
        //require(fundInfo.nav>0,"nav does not be 0");
        //uint256 amount = tokenAmount.mul(fundInfo.nav); //TODO: 此种方式可能会有误差，应该从真实从机枪池里面得到的币数量来做计算。
        capitalToken.safeTransfer(_msgSender(),amount);
        //principalAmount = principalAmount.sub(amount);
        //不直接给用户项目代币STRUCT奖励，通过一池。

        emit Redeemed(grade,_msgSender(),amount);
    }


}

// File: instances/StructFundUSDT.sol

pragma solidity ^0.6.12;


contract StructFundUSDT is StructFund {
    constructor(address vault, address pfdsToken, address ifdsToken)
        public
        StructFund(
            vault,
            10000000000000000000000,
            pfdsToken,
            ifdsToken,
            msg.sender
        )
    {}
}