/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.5.0;


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
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
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
    function _mint(address account, uint256 amount) internal {
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
    function _burn(address account, uint256 amount) internal {
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
    function _approve(address owner, address spender, uint256 amount) internal {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

contract IOneSplitConsts {
    // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
    uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
    uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
    uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
    uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
    uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
    uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
    uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
    uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
    uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
    uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
    uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
    uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
    uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
    uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
    uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
    uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
    uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
    uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
    uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
    uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
    uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
    uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
    uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x10000000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x20000000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x40000000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 0x80000000000000; // Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP = 0x100000000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 0x4000000000000000;
}

contract IOneSplit is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    )
        public
        payable
        returns(uint256 returnAmount);
}

contract IOneSplitMulti is IOneSplit {
    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    )
        public
        payable
        returns(uint256 returnAmount);
}

interface IOracle {
	function getiTokenDetails(uint _poolIndex) external returns(string memory, string memory); 
     function getTokenDetails(uint _poolIndex) external returns(address[] memory,uint[] memory,uint ,uint);
}

interface Iitokendeployer {
	function createnewitoken(string calldata _name, string calldata _symbol) external returns(address);
}

interface Iitoken {
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
}

interface IMAsterChef {
	function depositFromDAA(uint256 _pid, uint256 _amount, uint256 voult, address _sender) external returns (bool);
	function distributeExitFeeShare(uint256 _amount) external;
}

interface IPoolConfiguration {
	 function checkDao(address daoAddress) external returns(bool);
	 function getperformancefees() external view returns(uint256);
	 function getslippagerate() external view returns(uint256);
	 function getoracleaddress() external view returns(address);
	 function getEarlyExitfees() external view returns(uint256);
}

contract PoolV1 {
    
    using SafeMath for uint;

	

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
   	address public EXCHANGE_CONTRACT = 0x5e676a2Ed7CBe15119EBe7E96e1BB0f3d157206F;
	address public WETH_ADDRESS = 0x7816fBBEd2C321c24bdB2e2477AF965Efafb7aC0;
	address public DAI_ADDRESS = 0xc6196e00Fd2970BD91777AADd387E08574cDf92a;

	address public distributor;

	address public ASTRTokenAddress;
	
	address public managerAddresses;
	address public ChefAddress;
	address public _poolConf;
	address public poolChef;

	uint256[] public holders;
	
	uint256 public WethBalance;

    address public itokendeployer;
	
	struct PoolInfo {
        address[] tokens;    
        uint256[]  weights;        
        uint256 totalWeight;      
        bool active;          
        uint256 rebaltime;
        uint256 threshold;
        uint256 currentRebalance;
        uint256 lastrebalance;
		string name;
		string symbol;
		address itokenaddr;
		address owner;
    }
    struct PoolUser 
    { 
        uint256 currentBalance; 
        uint256 currentPool; 
        uint256 pendingBalance; 
		uint256 USDTdeposit;
		uint256 Itokens;
        bool active;
        bool isenabled;
    } 
    
    mapping ( uint256 =>mapping(address => PoolUser)) public poolUserInfo; 
    PoolInfo[] public poolInfo;
    
    uint256[] buf; 
    
    address[] _Tokens;
    uint256[] _Values;
    
    address[] _TokensDAI;
    uint256[] _ValuesDAI;
    
	mapping(uint256 => mapping(address => uint256)) public tokenBalances;
	
	mapping(uint256 => mapping(address => uint256)) public daatokenBalances;
	
	mapping(uint256 => uint256) public totalPoolbalance;
	
	mapping(uint256 => uint256) public poolPendingbalance;
	//Track the initial block where user deposit amount.
	mapping(address =>mapping (uint256 => uint256)) public initalDeposit;
	//Track the last block when user deposit from pool.
	mapping(address => uint256) public lastWithdrawTime;

	//Check if user already exist or not.
	mapping(address =>mapping (uint256 => bool)) public existingUser;

	bool public active = true; 

	mapping(address => bool) public systemAddresses;
	
	modifier systemOnly {
	    require(systemAddresses[msg.sender], "system only");
	    _;
	}
	
	modifier DaoOnly{
	    require(IPoolConfiguration(_poolConf).checkDao(msg.sender), "dao only");
	    _;
	}
	
	modifier whitelistManager {
	    require(managerAddresses == msg.sender, "Manager only");
	    _;
	}

	modifier OracleOnly {
		require(IPoolConfiguration(_poolConf).getoracleaddress() == msg.sender, "Only Oracle contract");
		_;
	}
	
	event Transfer(address indexed src, address indexed dst, uint wad);
	event Withdrawn(address indexed from, uint value);
	event WithdrawnToken(address indexed from, address indexed token, uint amount);
	
	
	constructor(string memory name, string memory symbol, address _ASTRTokenAddress, address poolConfiguration,address _itokendeployer, address _chef) public {
		systemAddresses[msg.sender] = true;
		ASTRTokenAddress = _ASTRTokenAddress;
		managerAddresses = msg.sender;
		_poolConf = poolConfiguration;
		itokendeployer = _itokendeployer;
		poolChef = _chef;
		distributor = 0x3C0579211A530ac1839CC672847973182bd2da31;
	}
	
	/**
	 * @notice Set Contract Addresses. Can only be called by the owner.
	 * @param _exchange : Exchange contract address
	 * @param _weth : Weth contract address
	 * @param _dai : Dai contract address
     * @dev Update the Exhchange/Weth/DAI address this is only for testing phase in live version it will be removed.
     */
     
	function configurePoolContracts(address _exchange, address _weth, address _dai) public systemOnly{
		   	EXCHANGE_CONTRACT = _exchange;
	        WETH_ADDRESS = _exchange;
	        DAI_ADDRESS = _dai;		
	}
	
	/**
     * @notice White users address
     * @param _address Account that needs to be whitelisted.
	 * @param _poolIndex Pool Index in which user wants to invest.
	 * @dev Whitelist users for deposit on pool. Without this user will not be able to deposit.
     */
     

    function whitelistaddress(address _address, uint _poolIndex) public whitelistManager {
		require(_poolIndex<poolInfo.length, "whitelistaddress: Invalid Pool Index");
	    require(!poolUserInfo[_poolIndex][_address].active,"whitelistaddress: Already whitelisted");
	    PoolUser memory newPoolUser = PoolUser(0, poolInfo[_poolIndex].currentRebalance,0,0,0,true,true);
        poolUserInfo[_poolIndex][_address] = newPoolUser;
	}

	/**
     * @notice Add public pool
     * @param _tokens tokens to purchase in pool.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _name itoken name.
	 * @param _symbol itoken symbol.
	 * @dev Add new public pool by any users.Here any users can add there custom pools
     */
	function addPublicPool(address[] memory _tokens, uint[] memory _weights,uint _threshold,uint _rebalanceTime,string memory _name,string memory _symbol) public{
        require (_tokens.length == _weights.length, "addNewList: Invalid config length");
        uint _totalWeight;
		address _itokenaddr;
		for(uint i = 0; i < _tokens.length; i++) {
			_totalWeight += _weights[i];
		}
        _itokenaddr = Iitokendeployer(itokendeployer).createnewitoken(_name, _symbol);
		poolInfo.push(PoolInfo({
            tokens : _tokens,   
            weights : _weights,        
            totalWeight : _totalWeight,      
            active : true,          
            rebaltime : _rebalanceTime,
            currentRebalance : 0,
            threshold: _threshold,
            lastrebalance: block.timestamp,
			name: _name,
			symbol: _symbol,
		    itokenaddr: _itokenaddr,
			owner: msg.sender
        }));
    }

	/**
	 * @notice Add new pool managed by AI
     * @dev Add new public pool by any Astra its details will came from Oracle contract addresses
     */

    function addNewList() public systemOnly{
        uint _poolIndex = poolInfo.length;
        address[] memory _tokens; 
        uint[] memory _weights;
		uint _threshold;
		uint _rebalanceTime;
		string memory _name;
		string memory _symbol;
		address _itokenaddr;
		(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getTokenDetails(_poolIndex);
        (_name,_symbol) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getiTokenDetails(_poolIndex);
	    require (_tokens.length == _weights.length, "addNewList: Invalid config length");
        uint _totalWeight;
		for(uint i = 0; i < _tokens.length; i++) {
			_totalWeight += _weights[i];
		}
        _itokenaddr = Iitokendeployer(itokendeployer).createnewitoken(_name, _symbol);

		poolInfo.push(PoolInfo({
            tokens : _tokens,   
            weights : _weights,        
            totalWeight : _totalWeight,      
            active : true,          
            rebaltime : _rebalanceTime,
            currentRebalance : 0,
            threshold: _threshold,
            lastrebalance: block.timestamp,
			name: _name,
			symbol: _symbol,
			itokenaddr: _itokenaddr,
			owner: address(this)
        }));
    }

	/**
	* @notice Internal function to Buy Astra Tokens
	* @param _amount Amount of Astra token to buy.
    * @dev Buy Astra Tokens if user want to pay fees early exit fees by deposit in Astra
    */
	function buyAstraToken(uint _amount) internal returns(uint256){ 
		uint[] memory _distribution;
		IERC20(DAI_ADDRESS).approve(EXCHANGE_CONTRACT, _amount);
	 	(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(DAI_ADDRESS), IERC20(ASTRTokenAddress), _amount, 2, 0);
		uint256 minReturn = calculateMinimumRetrun(_amount);
		IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(DAI_ADDRESS), IERC20(ASTRTokenAddress), _amount, minReturn, _distribution, 0);
		return _amount;
	}

	/**
    * @dev Stake Astra tokens for purchased amount
    */
	function stakeAstra(uint _amount)internal{
		IERC20(DAI_ADDRESS).approve(address(_poolConf),_amount);
		bool update = IMAsterChef(_poolConf).depositFromDAA(0,_amount,6,msg.sender);
		require(update,"Error in deposit");
	}	

	/**
	* @dev Calculate Early Exit fees
	* feeRate = Early Exit fee rate (Const 2%)
    * startBlock = Deposit block
    *  withdrawBlock = Withdrawal block 
    *  n = number of blocks between n1 and n2  
    *  Averageblockperday = Average block per day (assumed: 6500) 
    *  feeconstant =early exit fee cool down period (const 182) 
    *  Wv = withdrawal value
    *  EEFv = Wv x  EEFr  - (EEFr    x n/ABPx t)
    *  If EEFv <=0 then EEFv  = 0 
	 */

	 function calculatefee(address _account, uint _amount,uint _poolIndex)internal returns(uint256){
		 uint256 feeRate = IPoolConfiguration(_poolConf).getEarlyExitfees();
		 uint256 startBlock = initalDeposit[_account][_poolIndex];
		 uint256 withdrawBlock = block.number;
		 uint256 Averageblockperday = 6500;
		 uint256 feeconstant = 182;
		 uint256 blocks = withdrawBlock.sub(startBlock);
		 uint feesValue = feeRate.mul(blocks).div(100);
		 feesValue = feesValue.div(Averageblockperday).div(feeconstant);
		 feesValue = _amount.mul(feeRate).div(100).sub(feesValue);
		 return feesValue;
	 }
		
	/**
     * @dev Buy token initially once threshold is reached this can only be called by poolIn function
     */
    function buytokens(uint _poolIndex) internal {
     require(_poolIndex<poolInfo.length, "Invalid Pool Index");
     address[] memory returnedTokens;
	 uint[] memory returnedAmounts;
     uint ethValue = poolPendingbalance[_poolIndex]; 
     uint[] memory buf3;
	 buf = buf3;
     
     (returnedTokens, returnedAmounts) = swap2(DAI_ADDRESS, ethValue, poolInfo[_poolIndex].tokens, poolInfo[_poolIndex].weights, poolInfo[_poolIndex].totalWeight,buf);
     
      for (uint i = 0; i < returnedTokens.length; i++) {
			tokenBalances[_poolIndex][returnedTokens[i]] += returnedAmounts[i];
	  }
	  
	  totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].add(ethValue);
	  poolPendingbalance[_poolIndex] = 0;
	  if (poolInfo[_poolIndex].currentRebalance == 0){
	      poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
	  }
		
    }

	/**
    * @dev Update user Info at the time of deposit in pool
    */
    
    function updateuserinfo(uint _amount,uint _poolIndex) internal { 
        
        if(poolUserInfo[_poolIndex][msg.sender].active){
            if(poolUserInfo[_poolIndex][msg.sender].currentPool < poolInfo[_poolIndex].currentRebalance){
                poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
                poolUserInfo[_poolIndex][msg.sender].currentPool = poolInfo[_poolIndex].currentRebalance;
                poolUserInfo[_poolIndex][msg.sender].pendingBalance = _amount;
            }
            else{
               poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.add(_amount); 
            }
        }
       
    } 

	/**
    * @dev Get user balance deposited in pool
    */
    
    function getuserbalance(uint _poolIndex) public view returns(uint){
        return poolUserInfo[_poolIndex][msg.sender].currentBalance;
    }

	/**
    * @dev Function to calculate the performance fees
    */
    
    function chargePerformancefees(uint _amount,uint _poolIndex) internal returns (uint){
		uint256 perFees = IPoolConfiguration(_poolConf).getperformancefees();
        uint256 fees = _amount.mul(perFees).div(100);		
		uint256 distribution = fees.mul(80).div(100);
				if(poolInfo[_poolIndex].owner==address(this)){
					IERC20(DAI_ADDRESS).transfer(managerAddresses, distribution);
				}else{
					IERC20(DAI_ADDRESS).transfer(poolInfo[_poolIndex].owner, distribution);
				}
		// IMAsterChef(_poolConf).distributeExitFeeShare(fees.sub(distribution));
		IERC20(DAI_ADDRESS).transfer(distributor, fees.sub(distribution));		

        return fees;
        
    }

	/**
    * @dev Function to calculate the Minimum return for slippage
    */
	function calculateMinimumRetrun(uint _amount) internal view returns (uint){
		uint256 sliprate= IPoolConfiguration(_poolConf).getslippagerate();
        uint rate = _amount.mul(sliprate).div(100);
        return _amount.sub(rate);
        
    }
	/**
    * @dev Get amount of itoken to be received.
	* Iv = index value 
    * Pt = total iTokens outstanding 
    * Dv = deposit USDT value 
    * DPv = total USDT value in the pool
    * pTR = iTokens received
    * If Iv = 0 then pTR =  DV
    * If pt > 0 then pTR  =  (Dv/Iv)* Pt
    */
	function getItokenValue(uint256 outstandingValue, uint256 indexValue, uint256 depositValue, uint256 totalDepositValue) public view returns(uint256){
		if(indexValue == uint(0)){
			return depositValue;
		}else if(outstandingValue>0){
			return depositValue.mul(outstandingValue).div(indexValue);
		}
		else{
			return depositValue;
		}
	}

    /**
     * @dev Deposit in Indices pool either public pool or pool created by Astra.
     * @param _tokens Token in which user want to give the amount. Currenly ony DAI stable coin is used.
     * @param _values Amount to spend.
	 * @param _poolIndex Pool Index in which user wants to invest.
     */
	function poolIn(address[] memory _tokens, uint[] memory _values, uint _poolIndex) public payable  {
		require(poolUserInfo[_poolIndex][msg.sender].isenabled, "poolIn: Only whitelisted user");
		require(_poolIndex<poolInfo.length, "poolIn: Invalid Pool Index");
		require(_tokens.length <2 && _values.length<2, "poolIn: Only one token allowed");
		if(!existingUser[msg.sender][_poolIndex]){
			existingUser[msg.sender][_poolIndex] = true;
			initalDeposit[msg.sender][_poolIndex] = block.number;
		}
		uint ethValue;
		uint fees;
		uint DAIValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;
	    
	    _TokensDAI = returnedTokens;
	    _ValuesDAI = returnedAmounts;
		if(_tokens.length == 0) {
			require (msg.value > 0.001 ether, "0.001 ether min pool in");
			ethValue = msg.value;
			_TokensDAI.push(DAI_ADDRESS);
			_ValuesDAI.push(1);
    	    (returnedTokens, returnedAmounts) = swap(ETH_ADDRESS, ethValue, _TokensDAI, _ValuesDAI, 1);
    	    DAIValue = returnedAmounts[0];
     
		} else {
		    bool checkaddress = (address(_tokens[0]) == address(DAI_ADDRESS));
		    require(checkaddress,"poolIn: Can only submit Stable coin");
			require(msg.value == 0, "poolIn: Submit one token at a time");
			require(IERC20(DAI_ADDRESS).balanceOf(msg.sender) >= _values[0], "poolIn: Not enough Dai tokens");
			DAIValue = _values[0];
			require(DAIValue > 0.001 ether,"poolIn: Min 0.001 Ether worth stable coin required");
			IERC20(DAI_ADDRESS).transferFrom(msg.sender,address(this),DAIValue);
		}
		uint256 ItokenValue = getItokenValue(Iitoken(poolInfo[_poolIndex].itokenaddr).totalSupply(), getPoolValue(_poolIndex), DAIValue, totalPoolbalance[_poolIndex]);	
		 poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].add(DAIValue);
		 uint checkbalance = totalPoolbalance[_poolIndex].add(poolPendingbalance[_poolIndex]);
		 updateuserinfo(DAIValue,_poolIndex);
		  if (poolInfo[_poolIndex].currentRebalance == 0){
		     if(poolInfo[_poolIndex].threshold <= checkbalance){
		        buytokens( _poolIndex);
		     }     
		  }
		// poolOutstandingValue[_poolIndex] =  poolOutstandingValue[_poolIndex].add();
		updateuserinfo(0,_poolIndex);
		poolUserInfo[_poolIndex][msg.sender].Itokens = poolUserInfo[_poolIndex][msg.sender].Itokens.add(ItokenValue);
		Iitoken(poolInfo[_poolIndex].itokenaddr).mint(msg.sender, ItokenValue);
	}


	 /**
     * @dev Withdraw from Pool using itoken.
	 * @param _poolIndex Pool Index to withdraw funds from.
     */
	function withdraw(uint _poolIndex, bool stakeEarlyFees, uint withdrawAmount) public {
	    require(_poolIndex<poolInfo.length, "Invalid Pool Index");
		require(Iitoken(poolInfo[_poolIndex].itokenaddr).balanceOf(msg.sender)>=withdrawAmount, "PoolV1: Not enough Itoken for Withdraw");
	    updateuserinfo(0,_poolIndex);
		uint userShare = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance).mul(withdrawAmount).div(poolUserInfo[_poolIndex][msg.sender].Itokens);
		uint _balance;
		uint _pendingAmount;
		if(userShare>poolUserInfo[_poolIndex][msg.sender].pendingBalance){
			_balance = userShare.sub(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
			_pendingAmount = poolUserInfo[_poolIndex][msg.sender].pendingBalance;
		}else{
			_pendingAmount = userShare;
		}
		// uint _balance = poolUserInfo[_poolIndex][msg.sender].currentBalance;
		// uint _balance = Iitoken(poolInfo[_poolIndex].itokenaddr).balanceOf(msg.sender).sub(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
		uint256 _totalAmount = withdrawTokens(_poolIndex,_balance);
		Iitoken(poolInfo[_poolIndex].itokenaddr).burn(msg.sender, _balance);
		uint fees;
		if(_totalAmount>_balance){
			uint256 earlyfees;
			fees = chargePerformancefees(_totalAmount.sub(_balance),_poolIndex);
			earlyfees = earlyfees.add(calculatefee(msg.sender,_totalAmount.sub(fees),_poolIndex));
			IERC20(DAI_ADDRESS).transfer(msg.sender, _totalAmount.sub(fees).sub(earlyfees));
			uint256 pendingEarlyfees = withdrawPendingAmount(_poolIndex,_pendingAmount);
			chargeEarlyFees(earlyfees.add(pendingEarlyfees),stakeEarlyFees,_poolIndex);
		}
		else{
			uint256 earlyfees;
			earlyfees = earlyfees.add(calculatefee(msg.sender,_totalAmount,_poolIndex));
			IERC20(DAI_ADDRESS).transfer(msg.sender, _totalAmount.sub(earlyfees));
			uint256 pendingEarlyfees = withdrawPendingAmount(_poolIndex,_pendingAmount);
			chargeEarlyFees(earlyfees.add(pendingEarlyfees),stakeEarlyFees,_poolIndex);
		}
		poolUserInfo[_poolIndex][msg.sender].Itokens = poolUserInfo[_poolIndex][msg.sender].Itokens.sub(withdrawAmount);
		Iitoken(poolInfo[_poolIndex].itokenaddr).burn(msg.sender, withdrawAmount);

        poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].sub( _pendingAmount);
        poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.sub(_pendingAmount);
        totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].sub(_balance);
		poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.sub(_balance);
		emit Withdrawn(msg.sender, _balance);
	}

	function withdrawTokens(uint _poolIndex,uint _balance) internal returns(uint256){
		uint localWeight;
		if(totalPoolbalance[_poolIndex]>0){
			localWeight = _balance.mul(1 ether).div(totalPoolbalance[_poolIndex]);
			// localWeight = _balance.mul(1 ether).div(Iitoken(poolInfo[_poolIndex].itokenaddr).totalSupply());
		}  
		uint _amount;
		uint _totalAmount;
		
		uint[] memory _distribution;
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
		    uint withdrawBalance = tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]].mul(localWeight).div(1 ether);
		    if (withdrawBalance == 0) {
		        continue;
		    }
		    if (poolInfo[_poolIndex].tokens[i] == DAI_ADDRESS) {
		        _totalAmount += withdrawBalance;
		        continue;
		    }
		    IERC20(poolInfo[_poolIndex].tokens[i]).approve(EXCHANGE_CONTRACT, withdrawBalance);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(DAI_ADDRESS), withdrawBalance, 2, 0);
			if (_amount == 0) {
		        continue;
		    }
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]].sub(_amount);
		    _totalAmount += _amount;
			IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(DAI_ADDRESS), withdrawBalance, _amount, _distribution, 0);
		}
	}

	/**
	* @dev Withdraw the pending amount that is submitted before next.
	*/

	function withdrawPendingAmount(uint256 _poolIndex,uint _pendingAmount)internal returns(uint256){
		uint _earlyfee;
         if(_pendingAmount>0){
		 _earlyfee = calculatefee(msg.sender,_pendingAmount,_poolIndex);
		 IERC20(DAI_ADDRESS).transfer(msg.sender, _pendingAmount.sub(_earlyfee));
		}
		return _earlyfee;
	}

	/**
	* @dev Charge Early fees for the withdraw amount.
	*/
	function chargeEarlyFees(uint256 earlyfees,bool stakeEarlyFees,uint256 _poolIndex)internal{
			uint256 distribution;
			if(earlyfees>uint256(0)){
				if(stakeEarlyFees){
				   // uint returnAmount= buyAstraToken(earlyfees);
			       // stakeAstra(returnAmount);	
				   IERC20(DAI_ADDRESS).transfer(distributor, earlyfees);			
			}else{
				distribution = earlyfees.mul(80).div(100);
				if(poolInfo[_poolIndex].owner==address(this)){
					IERC20(DAI_ADDRESS).transfer(managerAddresses, distribution);
				}else{
					IERC20(DAI_ADDRESS).transfer(poolInfo[_poolIndex].owner, distribution);
				}
				// uint returnAmount= buyAstraToken(earlyfees.sub(distribution));
			    // stakeAstra(returnAmount);
				IERC20(DAI_ADDRESS).transfer(distributor, earlyfees.sub(distribution));
			}	
		}
	}

	 /**
     * @dev Update pool function to do the rebalaning.
     * @param _tokens New tokens to purchase after rebalance.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _poolIndex Pool Index to do rebalance.
     */
	function updatePool(address[] memory _tokens,uint[] memory _weights,uint _threshold,uint _rebalanceTime,uint _poolIndex) public {	    
	    require(block.timestamp >= poolInfo[_poolIndex].rebaltime," Rebalnce time not reached");
		// require(poolUserInfo[_poolIndex][msg.sender].currentBalance>poolInfo[_poolIndex].threshold,"Threshold not reached");
		if(poolInfo[_poolIndex].owner != address(this)){
		    require(_tokens.length == _weights.length, "invalid config length");
			require(poolInfo[_poolIndex].owner == msg.sender, "Only owner can update the punlic pool");
		}else{
			(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getTokenDetails(_poolIndex);
		}

	    address[] memory newTokens;
	    uint[] memory newWeights;
	    uint newTotalWeight;
		
		uint _newTotalWeight;

		for(uint i = 0; i < _tokens.length; i++) {
			require (_tokens[i] != ETH_ADDRESS && _tokens[i] != WETH_ADDRESS);			
			_newTotalWeight += _weights[i];
		}
		
		newTokens = _tokens;
		newWeights = _weights;
		newTotalWeight = _newTotalWeight;

		rebalance(newTokens, newWeights,newTotalWeight,_poolIndex);
		poolInfo[_poolIndex].threshold = _threshold;
		poolInfo[_poolIndex].rebaltime = _rebalanceTime;
		if(poolPendingbalance[_poolIndex]>0){
		 buytokens(_poolIndex);   
		}
		
	}

	/**
	* @dev Enable or disable Pool can only be called by admin
	*/
	function setPoolStatus(bool _active,uint _poolIndex) public systemOnly {
		poolInfo[_poolIndex].active = _active;
	}	
	/** 
	 * @dev sell array of tokens for ether. It was used previoulsy while Ether are accepted
	 */
	function sellTokensForEther(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == WETH_ADDRESS) {
		        _totalAmount += _amounts[i];
		        continue;
		    }
		    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    uint256 minReturn = calculateMinimumRetrun(_amount);
			_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], minReturn, _distribution, 0);

			_totalAmount += _amount;
		}

		return _totalAmount;
	}

	/** 
	 * @dev Get the current value of pool to check the value of pool
	 */

	function getPoolValue(uint256 _poolIndex)public view returns(uint256){
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;

		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(DAI_ADDRESS), tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    _totalAmount += _amount;
		}
		return _totalAmount;
	}
	
	/** 
	 * @dev Sell tokens for DAI is used during the rebalancing to sell previous token and buy new tokens
	 */

	function sellTokensForDAI(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == DAI_ADDRESS) {
		        _totalAmount += _amounts[i];
		        continue;
		    }
		    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(DAI_ADDRESS), _amounts[i], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    uint256 minReturn = calculateMinimumRetrun(_amount);
		    _totalAmount += _amount;
			_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_tokens[i]), IERC20(DAI_ADDRESS), _amounts[i], minReturn, _distribution, 0);

			
		}

		return _totalAmount;
	}

	/** 
	 * @dev Internal function called while updating the pool.
	 */

	function rebalance(address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint _poolIndex) internal {
	    require(poolInfo[_poolIndex].currentRebalance >0, "No balance in Pool");
		uint[] memory buf2;
		buf = buf2;
		uint ethValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;

		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			buf.push(tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]]);
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = 0;
		}
		
		if(totalPoolbalance[_poolIndex]>0){
		 ethValue = sellTokensForDAI(poolInfo[_poolIndex].tokens, buf);   
		}

		poolInfo[_poolIndex].tokens = newTokens;
		poolInfo[_poolIndex].weights = newWeights;
		poolInfo[_poolIndex].totalWeight = newTotalWeight;
		poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
		poolInfo[_poolIndex].lastrebalance = block.timestamp;
		
		if (ethValue == 0) {
		    return;
		}
		
		uint[] memory buf3;
		buf = buf3;
		
		if(totalPoolbalance[_poolIndex]>0){
		 (returnedTokens, returnedAmounts) = swap2(DAI_ADDRESS, ethValue, newTokens, newWeights,newTotalWeight,buf);
		
		for(uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = buf[i];
	    	
		}  
		}
		
	}

	/** 
	 * @dev Function to swap two token. Used by other functions during buying and selling. It used where ether is used like at the time of ether deposit.
	 */

	function swap(address _token, uint _value, address[] memory _tokens, uint[] memory _weights, uint _totalWeight) internal returns(address[] memory, uint[] memory) {
		uint _tokenPart;
		uint _amount;
		uint[] memory _distribution;
        
		for(uint i = 0; i < _tokens.length; i++) { 
		    
		    _tokenPart = _value.mul(_weights[i]).div(_totalWeight);

			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(_tokens[i]), _tokenPart, 2, 0);
		    uint256 minReturn = calculateMinimumRetrun(_amount);
		    _weights[i] = _amount;
			if (_token == ETH_ADDRESS) {
				_amount = IOneSplit(EXCHANGE_CONTRACT).swap.value(_tokenPart)(IERC20(_token), IERC20(_tokens[i]), _tokenPart, minReturn, _distribution, 0);
			} else {
			    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _tokenPart);
				_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(_tokens[i]), _tokenPart, minReturn, _distribution, 0);
			}
			
		}
		
		return (_tokens, _weights);
	}
	/** 
	 * @dev Function to swap two token. It used in case of ERC20 - ERC20 swap.
	 */
	
	function swap2(address _token, uint _value, address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint[] memory _buf) internal returns(address[] memory, uint[] memory) {
		uint _tokenPart;
		uint _amount;
		buf = _buf;
		
		uint[] memory _distribution;
		
		IERC20(_token).approve(EXCHANGE_CONTRACT, _value);
		
		for(uint i = 0; i < newTokens.length; i++) {
            
			_tokenPart = _value.mul(newWeights[i]).div(newTotalWeight);
			
			if(_tokenPart == 0) {
			    buf.push(0);
			    continue;
			}
			
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(newTokens[i]), _tokenPart, 2, 0);
			uint256 minReturn = calculateMinimumRetrun(_amount);
			buf.push(_amount);
            newWeights[i] = _amount;
			_amount= IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(newTokens[i]), _tokenPart, minReturn, _distribution, 0);
		}
		return (newTokens, newWeights);
	}
}