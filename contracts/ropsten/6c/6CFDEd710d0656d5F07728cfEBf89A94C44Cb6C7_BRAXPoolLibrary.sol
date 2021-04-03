/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

//SPDX-License-Identifier: MIT 
pragma solidity 0.6.11; 
pragma experimental ABIEncoderV2;


// File: contracts\Math\SafeMath.sol
// License: MIT

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\Utils\ContractGuard.sol
// License: MIT

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;
    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }
    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }
    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            'ContractGuard: one block, one function'
        );
        require(
            !checkSameSenderReentranted(),
            'ContractGuard: one block, one function'
        );
        _;
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// File: contracts\Common\Context.sol
// License: MIT

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\ERC20\IERC20.sol
// License: MIT



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts\BXS\IBRAXShares.sol
// License: MIT
interface IBRAXShares is IERC20 {  
    function pool_mint(address m_address, uint256 m_amount) external; 
    function pool_burn_from(address b_address, uint256 b_amount) external; 
}

// File: contracts\Oracle\IUniswapPairOracle.sol
// License: MIT

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
interface IUniswapPairOracle { 
    function getPairToken(address token) external view returns(address);
    function containsToken(address token) external view returns(bool);
    function getSwapTokenReserve(address token) external view returns(uint256);
    function update() external;
    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}

// File: contracts\BRAX\IBRAXStablecoin.sol
// License: MIT


interface IBRAXStablecoin {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function owner_address() external returns (address);
    function creator_address() external returns (address);
    function timelock_address() external returns (address); 
    function genesis_supply() external returns (uint256);
    function brax_pools_array() external returns (address[] memory);
    function brax_step() external returns (uint256);
    function refresh_cooldown() external returns (uint256);
    function price_target() external returns (uint256);
    function price_band() external returns (uint256);
    function DEFAULT_ADMIN_ADDRESS() external returns (address);
    function COLLATERAL_RATIO_PAUSER() external returns (bytes32);
    function collateral_ratio_paused() external returns (bool);
    function last_call_time() external returns (uint256);
    function BraxUsdOracle() external returns (IUniswapPairOracle);
    function BraxBxsOracle() external returns (IUniswapPairOracle); 
    /* ========== VIEWS ========== */
    function brax_pools(address a) external view returns (bool);
    function global_collateral_ratio() external view returns (uint256);
    function brax_price() external view returns (uint256);
    function bxs_price()  external view returns (uint256);
    function bxs_price_in_brax()  external view returns (uint256); 
    function globalCollateralValue() external view returns (uint256);
    /* ========== PUBLIC FUNCTIONS ========== */
    function refreshCollateralRatio() external;
    function swapCollateralAmount() external view returns(uint256);
    function pool_mint(address m_address, uint256 m_amount) external;
    function pool_burn_from(address b_address, uint256 b_amount) external;
}

// File: contracts\Utils\Address.sol
// License: MIT

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

// File: contracts\ERC20\ERC20.sol
// License: MIT





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
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
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts\Utils\EnumerableSet.sol
// License: MIT

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.
            bytes32 lastvalue = set._values[lastIndex];
            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    // AddressSet
    struct AddressSet {
        Set _inner;
    }
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }
    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
    // UintSet
    struct UintSet {
        Set _inner;
    }
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts\Governance\AccessControl.sol
// License: MIT




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }
    mapping (bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; //bytes32(uint256(0x4B437D01b575618140442A4975db38850e3f8f5f) << 96);
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }
    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }
    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }
    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }
    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }
    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }
    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts\BRAX\Pools\BRAXPoolLibrary.sol
// License: MIT



library BRAXPoolLibrary {
    using SafeMath for uint256;
    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    // ================ Structs ================
    // Needed to lower stack size
    struct MintFB_Params {
        uint256 bxs_price_usd; 
        uint256 col_price_usd;
        uint256 bxs_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }
    struct BuybackBXS_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 bxs_price_usd;
        uint256 col_price_usd;
        uint256 bxs_amount;
    }
    // ================ Functions ================
    function calcMint1t1BRAX(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18.mul(col_price)).div(1e6);
    }
    function calcMintAlgorithmicBRAX(uint256 bxs_price_usd, uint256 bxs_amount_d18) public pure returns (uint256) {
        return bxs_amount_d18.mul(bxs_price_usd).div(1e6);
    }
    // Must be internal because of the struct
    function calcMintFractionalBRAX(MintFB_Params memory params) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint BRAX. We do this by seeing the minimum mintable BRAX based on each amount 
        uint256 bxs_dollar_value_d18;
        uint256 c_dollar_value_d18;
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the FXS
            bxs_dollar_value_d18 = params.bxs_amount.mul(params.bxs_price_usd).div(1e6);
            c_dollar_value_d18 = params.collateral_amount.mul(params.col_price_usd).div(1e6);
        }
        uint calculated_bxs_dollar_value_d18 = 
                    (c_dollar_value_d18.mul(1e6).div(params.col_ratio))
                    .sub(c_dollar_value_d18);
        uint calculated_bxs_needed = calculated_bxs_dollar_value_d18.mul(1e6).div(params.bxs_price_usd);
        return (
            c_dollar_value_d18.add(calculated_bxs_dollar_value_d18),
            calculated_bxs_needed
        );
    }
    function calcRedeem1t1BRAX(uint256 col_price_usd, uint256 brax_amount) public pure returns (uint256) {
        return brax_amount.mul(1e6).div(col_price_usd);
    }
    // Must be internal because of the struct
    function calcBuyBackBXS(BuybackBXS_Params memory params) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible FXS with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");
        // Make sure not to take more than is available
        uint256 bxs_dollar_value_d18 = params.bxs_amount.mul(params.bxs_price_usd).div(1e6);
        require(bxs_dollar_value_d18 <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");
        // Get the equivalent amount of collateral based on the market value of FXS provided 
        uint256 collateral_equivalent_d18 = bxs_dollar_value_d18.mul(1e6).div(params.col_price_usd);
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));
        return (
            collateral_equivalent_d18
        );
    }
    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = total_supply.mul(global_collateral_ratio).div(1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value.sub(global_collat_value); // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }
    function calcRecollateralizeBRAXInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 frax_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = collateral_amount.mul(col_price).div(1e6);
        uint256 effective_collateral_ratio = global_collat_value.mul(1e6).div(frax_total_supply); //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio.mul(frax_total_supply).sub(frax_total_supply.mul(effective_collateral_ratio))).div(1e6);
        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }
        return (amount_to_recollat.mul(1e6).div(col_price), amount_to_recollat);
    }
}

// File: contracts\BRAX\Pools\BraxPool.sol
// License: MIT










abstract contract BraxPool is ContractGuard,AccessControl {
    using SafeMath for uint256;
    /* ========== STATE VARIABLES ========== */
    ERC20 public collateral_token;
    address public collateral_address;
    address public owner_address;
    address public community_address;
    address public brax_contract_address;
    address public bxs_contract_address;
    address public timelock_address;
    IBRAXShares private BXS;
    IBRAXStablecoin private BRAX; 
    uint256 public last_required_reserve_ratio;
    uint256 public minting_tax_base;
    uint256 public minting_tax_multiplier; 
    uint256 public minting_required_reserve_ratio;
    uint256 public redemption_tax_base;
    uint256 public redemption_tax_multiplier;
    uint256 public redemption_tax_exponent;
    uint256 public redemption_required_reserve_ratio;
    uint256 public buyback_tax;
    uint256 public recollat_tax;
    uint256 public community_rate_ratio;
    uint256 public community_rate_in_brax;
    uint256 public community_rate_in_bxs;
    mapping (address => uint256) public redeemBXSBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolBXS;
    mapping (address => uint256) public lastRedeemed;
    // Constants for various precisions
    uint256 public constant PRECISION = 1e6;
    uint256 public constant PRICE_PRECISION = 1e6;
    uint256 public constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 public constant RESERVE_RATIO_PRECISION = 1e6;    
    uint256 public constant COLLATERAL_RATIO_MAX = 1e6;
    // Number of decimals needed to get to 18
    uint256 public immutable missing_decimals;
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pool_ceiling = 10000000000e18;
    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;
    // Bonus rate on BXS minted during recollateralizeBRAX(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;
    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;
    // AccessControl Roles
    bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
    bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 private constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    bytes32 private constant COMMUNITY_RATER = keccak256("COMMUNITY_RATER");
    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;
    /* ========== MODIFIERS ========== */
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
        _;
    }
    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        require(redemptionOpened() == true,"Redeeming is closed");
        _;
    }
    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        require(mintingOpened() == true,"Minting is closed");
        _;
    }
    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _brax_contract_address,
        address _bxs_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        address _community_address
    ) public {
        BRAX = IBRAXStablecoin(_brax_contract_address);
        BXS = IBRAXShares(_bxs_contract_address);
        brax_contract_address = _brax_contract_address;
        bxs_contract_address = _bxs_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        community_address = _community_address;
        collateral_token = ERC20(_collateral_address); 
        missing_decimals = uint(18).sub(collateral_token.decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MINT_PAUSER, timelock_address);
        grantRole(REDEEM_PAUSER, timelock_address);
        grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
        grantRole(BUYBACK_PAUSER, timelock_address);
        grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
        grantRole(COMMUNITY_RATER, _community_address);
    }
    /* ========== VIEWS ========== */
    // Returns dollar value of collateral held in this BRAX pool
    function collatDollarBalance() public view returns (uint256) {
        uint256 collateral_amount = collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral);
        uint256 collat_usd_price = collateralPricePaused == true ? pausedPrice : getCollateralPrice();
        return collateral_amount.mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); 
    }
    // Returns the value of excess collateral held in this BRAX pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {      
        uint256 total_supply = BRAX.totalSupply();       
        uint256 global_collat_value = BRAX.globalCollateralValue();
        uint256 global_collateral_ratio = BRAX.global_collateral_ratio();
        // Handles an overcollateralized contract with CR > 1
        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) {
            global_collateral_ratio = COLLATERAL_RATIO_PRECISION; 
        }
        // Calculates collateral needed to back each 1 BRAX with $1 of collateral at current collat ratio
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION);
        if (global_collat_value > required_collat_dollar_value_d18) {
           return global_collat_value.sub(required_collat_dollar_value_d18);
        }
        return 0;
    }
    /* ========== PUBLIC FUNCTIONS ========== */ 
    function getCollateralPrice() public view virtual returns (uint256);
    function getCollateralAmount()   public view  returns (uint256){
        return collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral);
    }
    function requiredReserveRatio() public view returns(uint256){
        uint256 pool_collateral_amount = getCollateralAmount();
        uint256 swap_collateral_amount = BRAX.swapCollateralAmount();
        require(swap_collateral_amount>0,"swap collateral is empty?");
        return pool_collateral_amount.mul(RESERVE_RATIO_PRECISION).div(swap_collateral_amount);
    }
    function mintingOpened() public view returns(bool){
        return  (last_required_reserve_ratio >= minting_required_reserve_ratio);
    }
    function redemptionOpened() public view returns(bool){
        return  (last_required_reserve_ratio >= redemption_required_reserve_ratio);
    }
    //
    function mintingTax() public view returns(uint256){
        uint256 _dynamicTax =  minting_tax_multiplier.mul(last_required_reserve_ratio).div(RESERVE_RATIO_PRECISION); 
        return  minting_tax_base + _dynamicTax;       
    }
    function dynamicRedemptionTax(uint256 ratio,uint256 multiplier,uint256 exponent) public pure returns(uint256){        
        return multiplier.mul(RESERVE_RATIO_PRECISION**exponent).div(ratio**exponent);
    }
    //
    function redemptionTax() public view returns(uint256){
        uint256 _dynamicTax =dynamicRedemptionTax(last_required_reserve_ratio,redemption_tax_multiplier,redemption_tax_exponent);
        return  redemption_tax_base + _dynamicTax;       
    } 
    function updateOraclePrice() public { 
        IUniswapPairOracle _braxUsdOracle = BRAX.BraxUsdOracle();
        IUniswapPairOracle _braxBxsOracle = BRAX.BraxBxsOracle();
        _braxUsdOracle.update();
        _braxBxsOracle.update(); 
    }
    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1Brax(uint256 collateral_amount, uint256 brax_out_min) external onlyOneBlock notMintPaused { 
        updateOraclePrice();       
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        require(BRAX.global_collateral_ratio() >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require(getCollateralAmount().add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        (uint256 brax_amount_d18) = BRAXPoolLibrary.calcMint1t1BRAX(
            getCollateralPrice(),
            collateral_amount_d18
        ); //1 BRAX for each $1 worth of collateral
        community_rate_in_brax  =  community_rate_in_brax.add(brax_amount_d18.mul(community_rate_ratio).div(PRECISION));
        brax_amount_d18 = (brax_amount_d18.mul(uint(1e6).sub(mintingTax()))).div(1e6); //remove precision at the end
        require(brax_out_min <= brax_amount_d18, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        BRAX.pool_mint(msg.sender, brax_amount_d18); 
        //prevent flash loans
        last_required_reserve_ratio = requiredReserveRatio();
    }
    // 0% collateral-backed
    function mintAlgorithmicBRAX(uint256 bxs_amount_d18, uint256 brax_out_min) external onlyOneBlock notMintPaused {
        updateOraclePrice();
        uint256 bxs_price = BRAX.bxs_price();
        require(BRAX.global_collateral_ratio() == 0, "Collateral ratio must be 0");
        (uint256 brax_amount_d18) = BRAXPoolLibrary.calcMintAlgorithmicBRAX(
            bxs_price, // X BXS / 1 USD
            bxs_amount_d18
        );
        community_rate_in_brax  =  community_rate_in_brax.add(brax_amount_d18.mul(community_rate_ratio).div(PRECISION));
        brax_amount_d18 = (brax_amount_d18.mul(uint(1e6).sub(mintingTax()))).div(1e6);
        require(brax_out_min <= brax_amount_d18, "Slippage limit reached");
        BXS.pool_burn_from(msg.sender, bxs_amount_d18);
        BRAX.pool_mint(msg.sender, brax_amount_d18);
        //prevent flash loans
        last_required_reserve_ratio = requiredReserveRatio();
    }
    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalBRAX(uint256 collateral_amount, uint256 bxs_amount, uint256 brax_out_min) external onlyOneBlock notMintPaused {
        updateOraclePrice();
        uint256 bxs_price = BRAX.bxs_price();
        uint256 global_collateral_ratio = BRAX.global_collateral_ratio();
        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(getCollateralAmount().add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more BRAX can be minted with this collateral");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        BRAXPoolLibrary.MintFB_Params memory input_params = BRAXPoolLibrary.MintFB_Params(
            bxs_price,
            getCollateralPrice(),
            bxs_amount,
            collateral_amount_d18,
            global_collateral_ratio
        );
        (uint256 mint_amount, uint256 bxs_needed) = BRAXPoolLibrary.calcMintFractionalBRAX(input_params);
        community_rate_in_brax  =  community_rate_in_brax.add(mint_amount.mul(community_rate_ratio).div(PRECISION));
        mint_amount = (mint_amount.mul(uint(1e6).sub(mintingTax()))).div(1e6);
        require(brax_out_min <= mint_amount, "Slippage limit reached");
        require(bxs_needed <= bxs_amount, "Not enough BXS inputted");
        BXS.pool_burn_from(msg.sender, bxs_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        BRAX.pool_mint(msg.sender, mint_amount);
        //prevent flash loans
        last_required_reserve_ratio = requiredReserveRatio();
    }
    // Redeem collateral. 100% collateral-backed
    function redeem1t1BRAX(uint256 brax_amount, uint256 COLLATERAL_out_min) external onlyOneBlock notRedeemPaused {
        updateOraclePrice();
        require(BRAX.global_collateral_ratio() == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");
        // Need to adjust for decimals of collateral
        uint256 brax_amount_precision = brax_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = BRAXPoolLibrary.calcRedeem1t1BRAX(
            getCollateralPrice(),
            brax_amount_precision
        );
        community_rate_in_brax  =  community_rate_in_brax.add(brax_amount.mul(community_rate_ratio).div(PRECISION));
        collateral_needed = (collateral_needed.mul(uint(1e6).sub(redemptionTax()))).div(1e6);
        require(collateral_needed <= getCollateralAmount(), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
        lastRedeemed[msg.sender] = block.number;
        // Move all external functions to the end
        BRAX.pool_burn_from(msg.sender, brax_amount);
        //prevent flash loans
        last_required_reserve_ratio = requiredReserveRatio();
    }
    // Will fail if fully collateralized or algorithmic
    // Redeem BRAX for collateral and BXS. > 0% and < 100% collateral-backed
    function redeemFractionalBRAX(uint256 brax_amount, uint256 bxs_out_min, uint256 COLLATERAL_out_min) external onlyOneBlock notRedeemPaused {
        updateOraclePrice();
        uint256 global_collateral_ratio = BRAX.global_collateral_ratio();
        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        uint256 brax_amount_post_tax = (brax_amount.mul(uint(1e6).sub(redemptionTax()))).div(PRICE_PRECISION);
        uint256 bxs_dollar_value_d18 = brax_amount_post_tax.sub(brax_amount_post_tax.mul(global_collateral_ratio).div(PRICE_PRECISION));
        uint256 bxs_amount = bxs_dollar_value_d18.mul(PRICE_PRECISION).div(BRAX.bxs_price());
        // Need to adjust for decimals of collateral
        uint256 brax_amount_precision = brax_amount_post_tax.div(10 ** missing_decimals);
        uint256 collateral_dollar_value = brax_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
        uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(getCollateralPrice());
        require(collateral_amount <= getCollateralAmount(), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(bxs_out_min <= bxs_amount, "Slippage limit reached [BXS]");
        community_rate_in_brax  =  community_rate_in_brax.add(brax_amount.mul(community_rate_ratio).div(PRECISION));
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);
        redeemBXSBalances[msg.sender] = redeemBXSBalances[msg.sender].add(bxs_amount);
        unclaimedPoolBXS = unclaimedPoolBXS.add(bxs_amount);
        lastRedeemed[msg.sender] = block.number;
        // Move all external functions to the end
        BRAX.pool_burn_from(msg.sender, brax_amount);
        BXS.pool_mint(address(this), bxs_amount);
        //prevent flash loans
        last_required_reserve_ratio = requiredReserveRatio();
    }
    // Redeem BRAX for BXS. 0% collateral-backed
    function redeemAlgorithmicBRAX(uint256 brax_amount, uint256 bxs_out_min) external onlyOneBlock notRedeemPaused {
        updateOraclePrice();
        uint256 bxs_price = BRAX.bxs_price();
        uint256 global_collateral_ratio = BRAX.global_collateral_ratio();
        require(global_collateral_ratio == 0, "Collateral ratio must be 0"); 
        uint256 bxs_dollar_value_d18 = brax_amount;
        bxs_dollar_value_d18 = (bxs_dollar_value_d18.mul(uint(1e6).sub(redemptionTax()))).div(PRICE_PRECISION); //apply taxes
        uint256 bxs_amount = bxs_dollar_value_d18.mul(PRICE_PRECISION).div(bxs_price);
        redeemBXSBalances[msg.sender] = redeemBXSBalances[msg.sender].add(bxs_amount);
        unclaimedPoolBXS = unclaimedPoolBXS.add(bxs_amount);
        lastRedeemed[msg.sender] = block.number;
        require(bxs_out_min <= bxs_amount, "Slippage limit reached");
        community_rate_in_brax  =  community_rate_in_brax.add(brax_amount.mul(community_rate_ratio).div(PRECISION));
        // Move all external functions to the end
        BRAX.pool_burn_from(msg.sender, brax_amount);
        BXS.pool_mint(address(this), bxs_amount);
        //prevent flash loans
        last_required_reserve_ratio = requiredReserveRatio();
    }
    // After a redemption happens, transfer the newly minted BXS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out BRAX/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external onlyOneBlock{        
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendBxs = false;
        bool sendCollateral = false;
        uint bxsAmount;
        uint CollateralAmount;
        // Use Checks-Effects-Interactions pattern
        if(redeemBXSBalances[msg.sender] > 0){
            bxsAmount = redeemBXSBalances[msg.sender];
            redeemBXSBalances[msg.sender] = 0;
            unclaimedPoolBXS = unclaimedPoolBXS.sub(bxsAmount);
            sendBxs = true;
        }
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);
            sendCollateral = true;
        }
        if(sendBxs == true){
            BXS.transfer(msg.sender, bxsAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
    }
    // When the protocol is recollateralizing, we need to give a discount of BXS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get BXS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of BXS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra BXS value from the bonus rate as an arb opportunity
    function recollateralizeBRAX(uint256 collateral_amount, uint256 bxs_out_min) external onlyOneBlock {
        require(recollateralizePaused == false, "Recollateralize is paused");
        updateOraclePrice();
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 bxs_price = BRAX.bxs_price();
        uint256 brax_total_supply = BRAX.totalSupply();
        uint256 global_collateral_ratio = BRAX.global_collateral_ratio();
        uint256 global_collat_value = BRAX.globalCollateralValue();
        (uint256 collateral_units, uint256 amount_to_recollat) = BRAXPoolLibrary.calcRecollateralizeBRAXInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            brax_total_supply,
            global_collateral_ratio
        ); 
        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);
        uint256 bxs_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate).sub(recollat_tax)).div(bxs_price);
        require(bxs_out_min <= bxs_paid_back, "Slippage limit reached");
        community_rate_in_bxs =  community_rate_in_bxs.add(bxs_paid_back.mul(community_rate_ratio).div(PRECISION));
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        BXS.pool_mint(msg.sender, bxs_paid_back);
    }
    // Function can be called by an BXS holder to have the protocol buy back BXS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackBXS(uint256 bxs_amount, uint256 COLLATERAL_out_min) external onlyOneBlock {
        require(buyBackPaused == false, "Buyback is paused");
        updateOraclePrice();
        uint256 bxs_price = BRAX.bxs_price();
        BRAXPoolLibrary.BuybackBXS_Params memory input_params = BRAXPoolLibrary.BuybackBXS_Params(
            availableExcessCollatDV(),
            bxs_price,
            getCollateralPrice(),
            bxs_amount
        );
        (uint256 collateral_equivalent_d18) = (BRAXPoolLibrary.calcBuyBackBXS(input_params)).mul(uint(1e6).sub(buyback_tax)).div(1e6);
        uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);
        require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
        community_rate_in_bxs  =  community_rate_in_bxs.add(bxs_amount.mul(community_rate_ratio).div(PRECISION));
        // Give the sender their desired collateral and burn the BXS
        BXS.pool_burn_from(msg.sender, bxs_amount);
        collateral_token.transfer(msg.sender, collateral_precision);
    }
    /* ========== RESTRICTED FUNCTIONS ========== */
    function toggleMinting() external {
        require(hasRole(MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }
    function toggleRedeeming() external {
        require(hasRole(REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }
    function toggleRecollateralize() external {
        require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }
    function toggleBuyBack() external {
        require(hasRole(BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
    }
    function toggleCollateralPrice(uint256 _new_price) external {
        require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = _new_price;
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;
    }
    function toggleCommunityInBxsRate(uint256 _rate) external{
        require(community_rate_in_bxs>0,"No bxs rate");
        require(hasRole(COMMUNITY_RATER, msg.sender));
        uint256 _amount_rate = community_rate_in_bxs.mul(_rate).div(PRECISION);
        community_rate_in_bxs = community_rate_in_bxs.sub(_amount_rate);
        BXS.pool_mint(msg.sender,_amount_rate);  
    }
    function toggleCommunityInBraxRate(uint256 _rate) external{
        require(community_rate_in_brax>0,"No brax rate");
        require(hasRole(COMMUNITY_RATER, msg.sender));
        uint256 _amount_rate_brax = community_rate_in_brax.mul(_rate).div(PRECISION);        
        community_rate_in_brax = community_rate_in_brax.sub(_amount_rate_brax);
        uint256 _bxs_price_brax = BRAX.bxs_price_in_brax();
        uint256 _amount_rate = _amount_rate_brax.mul(PRICE_PRECISION).div(_bxs_price_brax);
        BXS.pool_mint(msg.sender,_amount_rate);  
    }
    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_ceiling, 
                               uint256 new_bonus_rate, 
                               uint256 new_redemption_delay, 
                               uint256 new_buyback_tax, 
                               uint256 new_recollat_tax) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay; 
        buyback_tax = new_buyback_tax;
        recollat_tax = new_recollat_tax;
    }
    function setMintingParameters(uint256 _ratioLevel,
                                  uint256 _tax_base,
                                  uint256 _tax_multiplier) external onlyByOwnerOrGovernance{
        minting_required_reserve_ratio = _ratioLevel;
        minting_tax_base = _tax_base;
        minting_tax_multiplier = _tax_multiplier;
    }
    function setRedemptionParameters(uint256 _ratioLevel,
                                     uint256 _tax_base,
                                     uint256 _tax_multiplier,
                                     uint256 _tax_exponent) external onlyByOwnerOrGovernance{
        redemption_required_reserve_ratio = _ratioLevel;
        redemption_tax_base = _tax_base;
        redemption_tax_multiplier = _tax_multiplier;
        redemption_tax_exponent = _tax_exponent;
    }
    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }
    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }
    function setCommunityParameters(address _community_address,uint256 _ratio) external onlyByOwnerOrGovernance {
        community_address = _community_address;
        community_rate_ratio = _ratio;
    } 
    /* ========== EVENTS ========== */
}

// File: contracts\BRAX\Pools\Pool_DAI.sol
// License: MIT


contract Pool_DAI is BraxPool {
    address public DAI_address;
    constructor(
        address _brax_contract_address,
        address _bxs_contract_address,
        address _collateral_address,
        address _creator_address, 
        address _timelock_address,
        address _community_address
    ) 
    BraxPool(_brax_contract_address, _bxs_contract_address, _collateral_address, _creator_address, _timelock_address,_community_address)
    public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DAI_address = _collateral_address;
    }
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view override returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else { 
            //Only For Dai
            return 1 * PRICE_PRECISION; 
        }
    } 
}