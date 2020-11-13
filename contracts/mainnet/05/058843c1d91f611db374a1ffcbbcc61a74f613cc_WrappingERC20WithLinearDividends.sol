// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


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

// File: openzeppelin-solidity/contracts/GSN/Context.sol


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

// File: openzeppelin-solidity/contracts/utils/Address.sol


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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



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

// File: contracts/oracle/ILinearDividendOracle.sol


/**
 * @title ILinearDividendOracle
 * @notice provides dividend information and calculation strategies for linear dividends.
*/
interface ILinearDividendOracle {

    /**
     * @notice calculate the total dividend accrued since last dividend checkpoint to now
     * @param tokenAmount           amount of token being held
     * @param timestamp             timestamp to start calculating dividend accrued
     * @param fromIndex             index in the dividend history that the timestamp falls into
     * @return amount of dividend accrued in 1e18, and the latest dividend index
     */
    function calculateAccruedDividends(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex
    ) external view returns (uint256, uint256);

    /**
     * @notice calculate the total dividend accrued since last dividend checkpoint to (inclusive) a given dividend index
     * @param tokenAmount           amount of token being held
     * @param timestamp             timestamp to start calculating dividend accrued
     * @param fromIndex             index in the dividend history that the timestamp falls into
     * @param toIndex               index in the dividend history to stop the calculation at, inclusive
     * @return amount of dividend accrued in 1e18, dividend index and timestamp to use for remaining dividends
     */
    function calculateAccruedDividendsBounded(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice get the current dividend index
     * @return the latest dividend index
     */
    function getCurrentIndex() external view returns (uint256);

    /**
     * @notice return the current dividend accrual rate, in USD per second
     * @return dividend in USD per second
     */
    function getCurrentValue() external view returns (uint256);

    /**
     * @notice return the dividend accrual rate, in USD per second, of a given dividend index
     * @return dividend in USD per second of the corresponding dividend phase.
     */
    function getHistoricalValue(uint256 dividendIndex) external view returns (uint256);
}

// File: contracts/standardTokens/WrappingERC20WithLinearDividends.sol



/**
 * @title WrappingERC20WithLinearDividends
 * @dev a wrapped token from another ERC 20 token with linear dividends delegation
*/
contract WrappingERC20WithLinearDividends is ERC20 {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    event DividendClaimed(address indexed from, uint256 value);

    /**
    * @dev records an address's dividend state
    **/
    struct DividendState {
        // amount of dividend that has been consolidated
        uint256 consolidatedAmount;

        // timestamp to start calculating newly accrued dividends from
        uint256 timestamp;

        // index of the dividend phase that the timestamp falls into
        uint256 index;
    }

    IERC20 public _backingToken;

    IERC20 public _dai;

    ILinearDividendOracle public _dividendOracle;

    // track account balances, only original holders of backing tokens can unlock their tokens
    mapping (address => uint256) public _lockedBalances;

    // track account dividend states
    mapping (address => DividendState) public _dividends;

    constructor(
        address backingTokenAddress,
        address daiAddress,
        address dividendOracleAddress,

        string memory name,
        string memory symbol
    ) public ERC20(name, symbol) {
        require(backingTokenAddress != address(0), "Backing token must be defined");
        require(dividendOracleAddress != address(0), "Dividend oracle must be defined");

        _backingToken = IERC20(backingTokenAddress);
        _dai = IERC20(daiAddress);
        _dividendOracle = ILinearDividendOracle(dividendOracleAddress);
    }

    /**
     * @notice deposit backing tokens to be locked, and generate wrapped tokens to sender
     * @param amount            amount of token to wrap
     * @return true if successful
     */
    function wrap(uint256 amount) external returns(bool) {
        return wrapTo(msg.sender, amount);
    }

    /**
     * @notice deposit backing tokens to be locked, and generate wrapped tokens to recipient
     * @param recipient         address to receive wrapped tokens
     * @param amount            amount of tokens to wrap
     * @return true if successful
     */
    function wrapTo(address recipient, uint256 amount) public returns(bool) {
        require(recipient != address(0), "Recipient cannot be zero address");

        // transfer backing token from sender to this contract to be locked
        _backingToken.transferFrom(msg.sender, address(this), amount);

        // update how many tokens the sender has locked in total
        _lockedBalances[msg.sender] = _lockedBalances[msg.sender].add(amount);

        // mint wTokens to recipient
        _mint(recipient, amount);

        emit Mint(recipient, amount);
        return true;
    }

    /**
     * @notice burn wrapped tokens to unlock backing tokens to sender
     * @param amount    amount of token to unlock
     * @return true if successful
     */
    function unwrap(uint256 amount) external returns(bool) {
        return unwrapTo(msg.sender, amount);
    }

    /**
     * @notice burn wrapped tokens to unlock backing tokens to recipient
     * @param recipient   address to receive backing tokens
     * @param amount      amount of tokens to unlock
     * @return true if successful
     */
    function unwrapTo(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Recipient cannot be zero address");

        // burn wTokens from sender, burn should revert if not enough balance
        _burn(msg.sender, amount);

        // update how many tokens the sender has locked in total
        _lockedBalances[msg.sender] = _lockedBalances[msg.sender].sub(amount, "Cannot unlock more than the locked amount");

        // transfer backing token from this contract to recipient
        _backingToken.transfer(recipient, amount);

        emit Burn(msg.sender, amount);
        return true;
    }

    /**
     * @notice return locked balances of backing tokens for a given account
     * @param account      account to query for
     * @return balance of backing token being locked
     */
    function lockedBalance(address account) external view returns (uint256) {
        return _lockedBalances[account];
    }

    /**
     * @notice withdraw all accrued dividends by the sender to the sender
     * @return true if successful
     */
    function claimAllDividends() external returns (bool) {
        return claimAllDividendsTo(msg.sender);
    }

    /**
     * @notice withdraw all accrued dividends by the sender to the recipient
     * @param recipient     address to receive dividends
     * @return true if successful
     */
    function claimAllDividendsTo(address recipient) public returns (bool) {
        require(recipient != address(0), "Recipient cannot be zero address");

        consolidateDividends(msg.sender);

        uint256 dividends = _dividends[msg.sender].consolidatedAmount;

        _dividends[msg.sender].consolidatedAmount = 0;

        _dai.transfer(recipient, dividends);

        emit DividendClaimed(msg.sender, dividends);
        return true;
    }

    /**
     * @notice withdraw portion of dividends by the sender to the sender
     * @return true if successful
     */
    function claimDividends(uint256 amount) external returns (bool) {
        return claimDividendsTo(msg.sender, amount);
    }

    /**
     * @notice withdraw portion of dividends by the sender to the recipient
     * @param recipient     address to receive dividends
     * @param amount        amount of dividends to withdraw
     * @return true if successful
     */
    function claimDividendsTo(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Recipient cannot be zero address");

        consolidateDividends(msg.sender);

        uint256 dividends = _dividends[msg.sender].consolidatedAmount;
        require(amount <= dividends, "Insufficient dividend balance");

        _dividends[msg.sender].consolidatedAmount = dividends.sub(amount);

        _dai.transfer(recipient, amount);

        emit DividendClaimed(msg.sender, amount);
        return true;
    }

    /**
     * @notice view total accrued dividends of a given account
     * @param account     address of the account to query for
     * @return total accrued dividends
     */
    function dividendsAvailable(address account) external view returns (uint256) {
        uint256 balance = balanceOf(account);

        // short circut if balance is 0 to avoid potentially looping from 0 dividend index
        if (balance == 0) {
            return _dividends[account].consolidatedAmount;
        }

        (uint256 dividends,) = _dividendOracle.calculateAccruedDividends(
                balance,
                _dividends[account].timestamp,
                _dividends[account].index
            );

        return _dividends[account].consolidatedAmount.add(dividends);
    }

    /**
     * @notice view dividend state of an account
     * @param account     address of the account to query for
     * @return consolidatedAmount, timestamp, and index
     */
    function getDividendState(address account) external view returns (uint256, uint256, uint256) {
        return (_dividends[account].consolidatedAmount, _dividends[account].timestamp, _dividends[account].index);
    }

    /**
     * @notice calculate all dividends accrued since the last consolidation, and add to the consolidated amount
     * @dev anybody can consolidation dividends for any account
     * @param account     account to perform dividend consolidation on
     * @return true if success
     */
    function consolidateDividends(address account) public returns (bool) {
        uint256 balance = balanceOf(account);

        // balance is at 0, re-initialize dividend state
        if (balance == 0) {
            initializeDividendState(account);
            return true;
        }

        (uint256 dividends, uint256 newIndex) = _dividendOracle.calculateAccruedDividends(
                balance,
                _dividends[account].timestamp,
                _dividends[account].index
            );

        _dividends[account].consolidatedAmount = _dividends[account].consolidatedAmount.add(dividends);
        _dividends[account].timestamp = block.timestamp;
        _dividends[account].index = newIndex;

        return true;
    }

    /**
     * @notice perform dividend consolidation to the given dividend index
     * @dev this function can be used if consolidateDividends fails due to running out of gas in an unbounded loop.
     *  In such case, dividend consolidation can be broken into several transactions.
     *  However, dividend rates do not change frequently,
     *  this function should not be needed unless account stays dormant for a long time, e.g. a decade.
     * @param account               account to perform dividend consolidation on
     * @param toDividendIndex       dividend index to stop consolidation at, inclusive
     * @return true if success
     */
    function consolidateDividendsToIndex(address account, uint256 toDividendIndex) external returns (bool) {
        uint256 balance = balanceOf(account);

        // balance is at 0, re-initialize dividend state
        if (balance == 0) {
            initializeDividendState(account);
            return true;
        }

        (uint256 dividends, uint256 newIndex, uint256 newTimestamp) = _dividendOracle.calculateAccruedDividendsBounded(
                balance,
                _dividends[account].timestamp,
                _dividends[account].index,
                toDividendIndex
            );

        _dividends[account].consolidatedAmount = _dividends[account].consolidatedAmount.add(dividends);
        _dividends[account].timestamp = newTimestamp;
        _dividends[account].index = newIndex;

        return true;
    }

    /**
     * @notice setups for parameters for dividend accrual calculations
     * @param account     account to setup for
     */
    function initializeDividendState(address account) internal {
        // initialize the time to start dividend accrual
        _dividends[account].timestamp = block.timestamp;
        // initialize the dividend index to start dividend accrual
        _dividends[account].index = _dividendOracle.getCurrentIndex();
    }


    /**
     * @notice consolidate dividends with the balance as is, the new balance will initiate dividend calculations from 0 again
     * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        if (from != address(0)) {
            consolidateDividends(from);
        }
        if (to != address(0) && to != from) {
            consolidateDividends(to);
        }
    }
}