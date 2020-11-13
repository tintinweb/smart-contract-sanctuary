/* 

website: bns.finance

This project is freshly written to change the way ICO is done.

    


BBBBBBBBBBBBBBBBB   NNNNNNNN        NNNNNNNN   SSSSSSSSSSSSSSS         DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFFFFFFFIIIIIIIIII
B::::::::::::::::B  N:::::::N       N::::::N SS:::::::::::::::S        D::::::::::::DDD   E::::::::::::::::::::EF::::::::::::::::::::FI::::::::I
B::::::BBBBBB:::::B N::::::::N      N::::::NS:::::SSSSSS::::::S        D:::::::::::::::DD E::::::::::::::::::::EF::::::::::::::::::::FI::::::::I
BB:::::B     B:::::BN:::::::::N     N::::::NS:::::S     SSSSSSS        DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EFF::::::FFFFFFFFF::::FII::::::II
  B::::B     B:::::BN::::::::::N    N::::::NS:::::S                      D:::::D    D:::::D E:::::E       EEEEEE  F:::::F       FFFFFF  I::::I  
  B::::B     B:::::BN:::::::::::N   N::::::NS:::::S                      D:::::D     D:::::DE:::::E               F:::::F               I::::I  
  B::::BBBBBB:::::B N:::::::N::::N  N::::::N S::::SSSS                   D:::::D     D:::::DE::::::EEEEEEEEEE     F::::::FFFFFFFFFF     I::::I  
  B:::::::::::::BB  N::::::N N::::N N::::::N  SS::::::SSSSS              D:::::D     D:::::DE:::::::::::::::E     F:::::::::::::::F     I::::I  
  B::::BBBBBB:::::B N::::::N  N::::N:::::::N    SSS::::::::SS            D:::::D     D:::::DE:::::::::::::::E     F:::::::::::::::F     I::::I  
  B::::B     B:::::BN::::::N   N:::::::::::N       SSSSSS::::S           D:::::D     D:::::DE::::::EEEEEEEEEE     F::::::FFFFFFFFFF     I::::I  
  B::::B     B:::::BN::::::N    N::::::::::N            S:::::S          D:::::D     D:::::DE:::::E               F:::::F               I::::I  
  B::::B     B:::::BN::::::N     N:::::::::N            S:::::S          D:::::D    D:::::D E:::::E       EEEEEE  F:::::F               I::::I  
BB:::::BBBBBB::::::BN::::::N      N::::::::NSSSSSSS     S:::::S        DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::EFF:::::::FF           II::::::II
B:::::::::::::::::B N::::::N       N:::::::NS::::::SSSSSS:::::S ...... D:::::::::::::::DD E::::::::::::::::::::EF::::::::FF           I::::::::I
B::::::::::::::::B  N::::::N        N::::::NS:::::::::::::::SS  .::::. D::::::::::::DDD   E::::::::::::::::::::EF::::::::FF           I::::::::I
BBBBBBBBBBBBBBBBB   NNNNNNNN         NNNNNNN SSSSSSSSSSSSSSS    ...... DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFF           IIIIIIIIII
                                                                                                                                                
                                                       

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SAO");

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
        require(c / a == b, "SMO");

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
        require(b != 0, errorMessage);
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
        require(address(this).balance >= amount, "IB");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "RR");
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
        require(address(this).balance >= value, "IBC");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "CNC");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "DAB0");
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

        bytes memory returndata = address(token).functionCall(data, "LF1");
        if (returndata.length != 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "LF2");
        }
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimals;

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

    // /**
    //  * @dev Returns the name of the token.
    //  */
    // function name() public view returns (string memory) {
    //     return _name;
    // }

    // /**
    //  * @dev Returns the symbol of the token, usually a shorter version of the
    //  * name.
    //  */
    // function symbol() public view returns (string memory) {
    //     return _symbol;
    // }

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
    // function decimals() public view returns (uint8) {
    //     return _decimals;
    // }

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
        require(sender != address(0), "ISA");
        require(recipient != address(0), "IRA");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "TIF");
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
        require(account != address(0), "M0");

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
        require(account != address(0), "B0");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BIB");
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
        require(owner != address(0), "IA");
        require(spender != address(0), "A0");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // /**
    //  * @dev Sets {decimals} to a value other than the default one of 18.
    //  *
    //  * WARNING: This function should only be called from the constructor. Most
    //  * applications that interact with token contracts will not expect
    //  * {decimals} to ever change, and may work incorrectly if it does.
    //  */
    // function _setupDecimals(uint8 decimals_) internal {
    //     _decimals = decimals_;
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

contract BnsdLaunchPool is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of a raising pool.
    struct RaisePoolInfo {
        IERC20 raiseToken;         // Address of raising token contract.
        uint256 maxTokensPerPerson;     // Maximum tokens a user can buy.
        uint256 totalTokensOnSale;  // Total tokens available on offer.
        uint256 startBlock; // When the sale starts
        uint256 endBlock; // When the sale ends
        uint256 totalTokensSold; // Total tokens sold to users so far
        uint256 tokensDeposited; // Total ICO tokens deposited
        uint256 votes; // Voted by users
        address owner; // Owner of the pool
        bool updateLocked; // No pool info can be updated once this is turned ON
        bool balanceAdded; // Whether ICO tokens are added in correct amount
        bool paymentMethodAdded; // Supported currencies added or not
        string poolName; // Human readable string name of the pool
    }

    struct AirdropPoolInfo {
        uint256 totalTokensAvailable;     // Total tokens staked so far.
        IERC20 airdropToken;         // Address of staking LP token.
        bool airdropExists;
    }

    // Info of a raising pool.
    struct UseCasePoolInfo {
        uint256 tokensAllocated; // Total tokens available for this use
        uint256 tokensClaimed; // Total tokens claimed
        address reserveAdd;  // Address where tokens will be released for that usecase.
        bool tokensDeposited; // No pool info can be updated once this is turned ON
        bool exists; // Whether reserve already exists for a pool
        string useName; // Human readable string name of the pool
        uint256[] unlock_perArray; // Release percent for usecase
        uint256[] unlock_daysArray; // Release days for usecase
    }

    struct DistributionInfo {
        uint256[] percentArray; // Percentage of tokens to be unlocked every phase
        uint256[] daysArray; // Days from the endDate when tokens starts getting unlocked
    }

    // The BNSD TOKEN!
    address public timeLock;
    // Dev address.
    address public devaddr;

    // Temp dev address while switching
    address private potentialAdmin;

    // To store owner diistribution info after sale ends
    mapping (uint256 => DistributionInfo) private ownerDistInfo; 

    // To store user distribution info after sale ends
    mapping (uint256 => DistributionInfo) private userDistInfo;

    // To store tokens on sale and their rates
    mapping (uint256 => mapping (address => uint256)) public saleRateInfo;

    // To store invite codes and corresponding token address and pool owners, INVITE CODE => TOKEN => OWNER => bool
    mapping (uint256 => mapping (address => mapping (address => bool))) private inviteCodeList;

    // To store user contribution for a sale -  POOL => USER => USDT
    mapping (uint256 => mapping (address => mapping (address => uint256))) public userDepositInfo;

    // To store total token promised to a user - POOL => USER
    mapping (uint256 => mapping (address => uint256)) public userTokenAllocation;

    // To store total token claimed by a user already
    mapping (uint256 => mapping (address => uint256)) public userTokenClaimed;

    // To store total token redeemed by users after sale
    mapping (uint256 =>  uint256) public totalTokenClaimed;

    // To store total token raised by a project - POOL => TOKEN => AMT
    mapping (uint256 => mapping (address => uint256)) public fundsRaisedSoFar;

    mapping (uint256 => address) private tempAdmin;

    // To store total token claimed by a project
    mapping (uint256 => mapping (address => uint256)) public fundsClaimedSoFar;

    // To store addresses voted for a project - POOL => USER => BOOL
    mapping (uint256 => mapping (address => bool)) public userVotes;

    // No of blocks in a day  - 6700
    uint256 public constant BLOCKS_PER_DAY = 6700; // Changing to 5 for test cases

    // Info of each pool on blockchain.
    RaisePoolInfo[] public poolInfo;

    // Info of reserve pool of any project - POOL => RESERVE_ADD => USECASEINFO 
    mapping (uint256 => mapping (address => UseCasePoolInfo)) public useCaseInfo;

    // To store total token reserved 
    mapping (uint256 =>  uint256) public totalTokenReserved;

    // To store total reserved claimed 
    mapping (uint256 =>  uint256) public totalReservedTokenClaimed;

    // To store list of all sales associated with a token 
    mapping (address =>  uint256[]) public listSaleTokens;

    // To store list of all currencies allowed for a sale 
    mapping (uint256 =>  address[]) public listSupportedCurrencies;

    // To store list of all reserve addresses for a sale 
    mapping (uint256 =>  address[]) public listReserveAddresses;

    // To check if staking is enabled on a token 
    mapping (address =>  bool) public stakingEnabled;

    // To get staking weight of a token 
    mapping (address =>  uint256) public stakingWeight;

    // To store sum of weight of all staking tokens
    uint256 public totalStakeWeight;

    // To store list of staking addresses 
    address[] public stakingPools;

    // To store stats of staked tokens per sale  
    mapping (uint256 => mapping (address => uint256)) public stakedLPTokensInfo;

    // To store user staked amount for a sale -  POOL => USER => LP_TOKEN
    mapping (uint256 => mapping (address => mapping (address => uint256))) public userStakeInfo;

    // To store reward claimed by a user - POOL => USER => BOOL
    mapping (uint256 => mapping (address => bool)) public rewardClaimed;

    // To store airdrop claimed by a user - POOL => USER => BOOL
    mapping (uint256 => mapping (address => bool)) public airdropClaimed;

    // To store extra airdrop tokens withdrawn by fund raiser - POOL => BOOL
    mapping (uint256 =>  bool) public extraAirdropClaimed;

    // To store airdrop info for a sale  
    mapping (uint256 =>  AirdropPoolInfo) public airdropInfo;

    // To store airdrop tokens balance of a user , TOKEN => USER => BAL
    mapping (address => mapping (address => uint256)) public airdropBalances;

    uint256 public fee = 300; // To be divided by 1e4 before using it anywhere => 3.00%

    uint256 public constant rewardPer = 8000; // To be divided by 1e4 before using it anywhere => 80.00%

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Stake(address indexed user, address indexed lptoken, uint256 indexed pid, uint256 amount);
    event UnStake(address indexed user, address indexed lptoken, uint256 indexed pid, uint256 amount);
    event MoveStake(address indexed user, address indexed lptoken, uint256 pid, uint256 indexed pidnew, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawAirdrop(address indexed user, address indexed token, uint256 amount);
    event ClaimAirdrop(address indexed user, address indexed token, uint256 amount);
    event AirdropDeposit(address indexed user, address indexed token, uint256 indexed pid, uint256 amount);
    event AirdropExtraWithdraw(address indexed user, address indexed token, uint256 indexed pid, uint256 amount);
    event Voted(address indexed user, uint256 indexed pid);

    constructor() public {
        devaddr = _msgSender();
    }

    modifier onlyAdmin() {
        require(devaddr == _msgSender(), "ND");
        _;
    }

    modifier onlyAdminOrTimeLock() {
        require((devaddr == _msgSender() || timeLock == _msgSender()), "ND");
        _;
    }

    function setTimeLockAdd(address _add) public onlyAdmin {
        timeLock = _add;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getListOfSale(address _token) external view returns (uint256[] memory) {
        return listSaleTokens[_token];
    }
    
    function getUserDistPercent(uint256 _pid) external view returns (uint256[] memory) {
        return userDistInfo[_pid].percentArray;
    }
    
    function getUserDistDays(uint256 _pid) external view returns (uint256[] memory) {
        return userDistInfo[_pid].daysArray;
    }

    function getReserveUnlockPercent(uint256 _pid, address _reserveAdd) external view returns (uint256[] memory) {
        return useCaseInfo[_pid][_reserveAdd].unlock_perArray;
    }
    
    function getReserveUnlockDays(uint256 _pid, address _reserveAdd) external view returns (uint256[] memory) {
        return useCaseInfo[_pid][_reserveAdd].unlock_daysArray;
    }

    function getUserDistBlocks(uint256 _pid) external view returns (uint256[] memory) {
        uint256[] memory daysArray =  userDistInfo[_pid].daysArray;

        uint256 endPool = poolInfo[_pid].endBlock;
        for(uint256 i=0; i<daysArray.length; i++){
            daysArray[i] = (daysArray[i].mul(BLOCKS_PER_DAY)).add(endPool);
        }
        return daysArray;
    }

    function getOwnerDistPercent(uint256 _pid) external view returns (uint256[] memory) {
        return ownerDistInfo[_pid].percentArray;
    }
    
    function getOwnerDistDays(uint256 _pid) external view returns (uint256[] memory) {
        return ownerDistInfo[_pid].daysArray;
    }

    // Add a new token sale to the pool. Can only be called by the person having the invite code.
    
    function addNewPool(uint256 totalTokens, uint256 maxPerPerson, uint256 startBlock, uint256 endBlock, string memory namePool, IERC20 tokenAddress, uint256 _inviteCode) external returns (uint256) {
        require(endBlock > startBlock, "ESC"); // END START COMPARISON FAILED
        require(startBlock > block.number, "TLS"); // TIME LIMIT START SALE
        require(maxPerPerson !=0 && totalTokens!=0, "IIP"); // INVALID INDIVIDUAL PER PERSON
        require(inviteCodeList[_inviteCode][address(tokenAddress)][_msgSender()]==true,"IIC"); // INVALID INVITE CODE
        poolInfo.push(RaisePoolInfo({
            raiseToken: tokenAddress,
            maxTokensPerPerson: maxPerPerson,
            totalTokensOnSale: totalTokens,
            startBlock: startBlock,
            endBlock: endBlock,
            poolName: namePool,
            updateLocked: false,
            owner: _msgSender(),
            totalTokensSold: 0,
            balanceAdded: false,
            tokensDeposited: 0,
            paymentMethodAdded: false,
            votes: 0
        }));
        uint256 poolId = (poolInfo.length - 1);
        listSaleTokens[address(tokenAddress)].push(poolId);
        // This makes the invite code claimed
        inviteCodeList[_inviteCode][address(tokenAddress)][_msgSender()] = false;
        return poolId;
    }

    function _checkSumArray(uint256[] memory _percentArray) internal pure returns (bool) {
        uint256 _sum;
        for (uint256 i = 0; i < _percentArray.length; i++) {
            _sum = _sum.add(_percentArray[i]);
        }
        return (_sum==10000);
    }

    function _checkValidDaysArray(uint256[] memory _daysArray) internal pure returns (bool) {
        uint256 _lastDay = _daysArray[0];
        for (uint256 i = 1; i < _daysArray.length; i++) {
            if(_lastDay < _daysArray[i]){
                _lastDay = _daysArray[i];
            }
            else {
                return false;
            }
        }
        return true;
    }

    function _checkUpdateAllowed(uint256 _pid) internal view{
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(pool.updateLocked == false, "CT2"); // CRITICAL TERMINATION 2
        require(pool.owner==_msgSender(), "OAU"); // OWNER AUTHORIZATION FAILED
        require(pool.startBlock > block.number, "CT"); // CRITICAL TERMINATION
    }

    // Add rule for funds locking after sale
    function updateUserDistributionRule(uint256 _pid, uint256[] memory _percentArray, uint256[] memory _daysArray) external {
        require(_percentArray.length == _daysArray.length, "LM"); // LENGTH MISMATCH
        _checkUpdateAllowed(_pid);
        require(_checkSumArray(_percentArray), "SE"); // SUM OF PERCENT INVALID
        require(_checkValidDaysArray(_daysArray), "DMI"); // DAYS SHOULD BE MONOTONIICALLY INCREASING
        userDistInfo[_pid] = DistributionInfo({
            percentArray: _percentArray,
            daysArray: _daysArray
        });
    }


    // Add rule for funds unlocking of the fund raiser after sale
    function updateOwnerDistributionRule(uint256 _pid, uint256[] memory _percentArray, uint256[] memory _daysArray) external {
        require(_percentArray.length == _daysArray.length, "LM"); // LENGTH MISMATCH
        _checkUpdateAllowed(_pid);
        require(_checkSumArray(_percentArray), "SE"); // SUM OF PERCENT INVALID
        require(_checkValidDaysArray(_daysArray), "DMI"); // DAYS SHOULD BE MONOTONIICALLY INCREASING
        ownerDistInfo[_pid] = DistributionInfo({
            percentArray: _percentArray,
            daysArray: _daysArray
        });
    }


    // Lock sale detail changes in future
    function lockPool(uint256 _pid) external {
        require(poolInfo[_pid].paymentMethodAdded==true, "CP"); // CHECK PAYMENT METHOD FAILED
        _checkUpdateAllowed(_pid);
        poolInfo[_pid].updateLocked = true;
    }

    
    // Add supported currencies and their rate w.r.t token on sale
    // rateToken = price of one satoshi of the token in terms of token to be raised * 1e18
    // 1 BNSD =  0.00021 ETH => 1e18 BNSD Satoshi = 0.00021 * 1e18 ETH satoshi => 1 BNSD Satoshi = 0.00021 ETH satoshi => rateToken = 0.00021 * 1e18 = 21 * 1e13
    // rateToken for BNSD/ETH pair = 21 * 1e13;
    function addSupportedCurrencies(uint256 _pid, address _tokenRaise, uint256 rateToken) external {
        _checkUpdateAllowed(_pid);
        require(rateToken!=0, "IR"); // INVALID RATE
        require(_tokenRaise!=address(poolInfo[_pid].raiseToken), "IT"); // INVALIID PURCHASE TOKEN
        if(saleRateInfo[_pid][_tokenRaise] == 0){
            listSupportedCurrencies[_pid].push(_tokenRaise);
        }
        saleRateInfo[_pid][_tokenRaise] = rateToken;
        poolInfo[_pid].paymentMethodAdded = true; 
    }

    function getSupportedCurrencies(uint256 _pid) external view returns (address[] memory) {
        return listSupportedCurrencies[_pid];
    }

    function _checkUpdateReserveAllowed(uint256 _pid, address _resAdd) internal view returns (bool) {
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        return (poolU.exists == false || poolU.tokensDeposited == false);
        // if(poolU.exists == false || poolU.tokensDeposited == false){
        //     return true;
        // }
        // return false;
    }

    function addReservePool(uint256 _pid, address _reserveAdd, string memory _nameReserve, uint256 _totalTokens, uint256[] memory _perArray, uint256[] memory _daysArray) external {
        _checkUpdateAllowed(_pid);
        require(_checkUpdateReserveAllowed(_pid, _reserveAdd) == true, "UB"); // UPDATE RESERVE FAILED
        require(_checkSumArray(_perArray), "SE"); // SUM OF PERCENT INVALID
        require(_checkValidDaysArray(_daysArray), "DMI"); // DAYS SHOULD BE MONOTONIICALLY INCREASING
        require(_perArray.length==_daysArray.length, "IAL"); // INVALID ARRAY LENGTH
        if(useCaseInfo[_pid][_reserveAdd].exists == false){
            listReserveAddresses[_pid].push(_reserveAdd);
        }
        useCaseInfo[_pid][_reserveAdd] = UseCasePoolInfo({
            reserveAdd: _reserveAdd,
            useName: _nameReserve,
            tokensAllocated: _totalTokens,
            unlock_perArray: _perArray,
            unlock_daysArray: _daysArray,
            tokensDeposited: false,
            tokensClaimed: 0,
            exists: true
        });
    }

    function getReserveAddresses(uint256 _pid) external view returns (address[] memory) {
        return listReserveAddresses[_pid];
    }

    function tokensPurchaseAmt(uint256 _pid, address _tokenAdd, uint256 amt) public view returns (uint256) {
        uint256 rateToken = saleRateInfo[_pid][_tokenAdd];
        require(rateToken!=0, "NAT"); // NOT AVAILABLE TOKEN
        return (amt.mul(1e18)).div(rateToken);
    }

    // Check if user can deposit specfic amount of funds to the pool 
    function _checkDepositAllowed(uint256 _pid, address _tokenAdd, uint256 _amt) internal view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        uint256 userBought = userTokenAllocation[_pid][_msgSender()];
        uint256 purchasePossible = tokensPurchaseAmt(_pid, _tokenAdd, _amt);
        require(pool.balanceAdded == true, "NA"); // NOT AVAILABLE
        require(pool.startBlock <= block.number, "NT1"); // NOT AVAILABLE TIME 1
        require(pool.endBlock >= block.number, "NT2"); // NOT AVAILABLE TIME 2
        require(pool.totalTokensSold.add(purchasePossible) <= pool.totalTokensOnSale, "PLE"); // POOL LIMIT EXCEEDED
        require(userBought.add(purchasePossible) <= pool.maxTokensPerPerson, "ILE"); // INDIVIDUAL LIMIT EXCEEDED
        return purchasePossible;
    }


    // Check max a user can deposit right now
    function getMaxDepositAllowed(uint256 _pid, address _tokenAdd, address _user) external view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        uint256 maxBuyPossible = (pool.maxTokensPerPerson).sub(userTokenAllocation[_pid][_user]);
        uint256 maxBuyPossiblePoolLimit = (pool.totalTokensOnSale).sub(pool.totalTokensSold);

        if(maxBuyPossiblePoolLimit < maxBuyPossible){
            maxBuyPossible = maxBuyPossiblePoolLimit;
        }

        if(block.number >= pool.startBlock && block.number <= pool.endBlock && pool.balanceAdded == true){
            uint256 rateToken = saleRateInfo[_pid][_tokenAdd];
            return (maxBuyPossible.mul(rateToken).div(1e18));
        }
        else {
            return 0;
        }
    }


    // Check if deposit is enabled for a pool
    function checkDepositEnabled(uint256 _pid) external view returns (bool){
        RaisePoolInfo storage pool = poolInfo[_pid];

        if(pool.balanceAdded == true && pool.startBlock <= block.number && pool.endBlock >= block.number && pool.totalTokensSold <= pool.totalTokensOnSale && pool.paymentMethodAdded==true){
            return true;
        }
        else {
            return false;
        }
    }


    // Deposit ICO tokens to start a pool for ICO.
    function depositICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        address msgSender = _msgSender();
        require(_tokenAdd == pool.raiseToken, "NOT"); // NOT VALID TOKEN
        require(msgSender == pool.owner, "NAU"); // NOT AUTHORISED USER
        require(block.number < pool.endBlock, "NT"); // No point adding tokens after sale has ended - Possible deadlock case
        _tokenAdd.safeTransferFrom(msgSender, address(this), _amount);
        pool.tokensDeposited = (pool.tokensDeposited).add(_amount);
        if(pool.tokensDeposited >= pool.totalTokensOnSale){
            pool.balanceAdded = true;
        }
        emit Deposit(msgSender, _pid, _amount);
    }

    // Deposit Airdrop tokens anytime before end of the sale.
    function depositAirdropTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.endBlock, "NT"); // NOT VALID TIME
        AirdropPoolInfo storage airdrop = airdropInfo[_pid];
        require((_tokenAdd == airdrop.airdropToken || airdrop.airdropExists==false), "NOT"); // NOT VALID TOKEN
        require(_msgSender() == pool.owner || _msgSender() == devaddr , "NAU"); // NOT AUTHORISED USER
        _tokenAdd.safeTransferFrom(_msgSender(), address(this), _amount);
        airdrop.totalTokensAvailable = (airdrop.totalTokensAvailable).add(_amount);
        if(!airdrop.airdropExists){
            airdrop.airdropToken = _tokenAdd;
            airdrop.airdropExists = true;
        }
        emit AirdropDeposit(_msgSender(), address(_tokenAdd), _pid, _amount);
    }

    // Withdraw extra airdrop tokens - Possible only if no one added liquidity to one of the pools
    function withdrawExtraAirdropTokens(uint256 _pid) external {
        require(extraAirdropClaimed[_pid]==false, "NA"); // NOT AVAILABLE
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number > pool.endBlock, "NSE"); // SALE NOT ENDED
        address msgSender = _msgSender();
        require(msgSender == pool.owner, "NAU"); //  NOT AUTHORISED USER
        uint256 extraTokens = calculateExtraAirdropTokens(_pid);
        require(extraTokens!=0, "NAT"); // NOT AVAILABLE TOKEN
        extraAirdropClaimed[_pid] = true;
        airdropInfo[_pid].airdropToken.safeTransfer(msgSender, extraTokens);
        emit AirdropExtraWithdraw(msg.sender, address(airdropInfo[_pid].airdropToken), _pid, extraTokens);
    }

    function calculateExtraAirdropTokens(uint256 _pid) public view returns (uint256){
        if(extraAirdropClaimed[_pid] == true) return 0;
        uint256 _totalTokens;
        for (uint256 i=0; i<stakingPools.length; i++){
            uint256 stake = stakedLPTokensInfo[_pid][stakingPools[i]];
            if(stake == 0){
                _totalTokens = _totalTokens.add(((stakingWeight[stakingPools[i]]).mul(airdropInfo[_pid].totalTokensAvailable)).div(totalStakeWeight));
            }
        }
        return _totalTokens;
    }

    // Deposit LP tokens for a sale.
    function stakeLPTokens(uint256 _pid, uint256 _amount, IERC20 _lpAdd) external {
        require(stakingEnabled[address(_lpAdd)]==true, "NST"); // NOT STAKING TOKEN
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.startBlock, "NT"); // NOT VALID TIME
        address msgSender = _msgSender();
        _lpAdd.safeTransferFrom(msgSender, address(this), _amount);
        stakedLPTokensInfo[_pid][address(_lpAdd)] = (stakedLPTokensInfo[_pid][address(_lpAdd)]).add(_amount);
        userStakeInfo[_pid][msgSender][address(_lpAdd)] = (userStakeInfo[_pid][msgSender][address(_lpAdd)]).add(_amount);
        emit Stake(msg.sender, address(_lpAdd), _pid, _amount);
    }

    // Withdraw LP tokens from a sale after it's over => Automatically claims rewards and airdrops also
    function withdrawLPTokens(uint256 _pid, uint256 _amount, IERC20 _lpAdd) external {
        require(stakingEnabled[address(_lpAdd)]==true, "NAT"); // NOT AUTHORISED TOKEN
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number > pool.endBlock, "SE"); // SALE NOT ENDED
        address msgSender = _msgSender();
        claimRewardAndAirdrop(_pid);
        userStakeInfo[_pid][msgSender][address(_lpAdd)] = (userStakeInfo[_pid][msgSender][address(_lpAdd)]).sub(_amount);
        _lpAdd.safeTransfer(msgSender, _amount);
        emit UnStake(msg.sender, address(_lpAdd), _pid, _amount);
    }

    // Withdraw airdrop tokens accumulated over one or more than one sale.
    function withdrawAirdropTokens(IERC20 _token, uint256 _amount) external {
        address msgSender = _msgSender();
        airdropBalances[address(_token)][msgSender] = (airdropBalances[address(_token)][msgSender]).sub(_amount);
        _token.safeTransfer(msgSender, _amount);
        emit WithdrawAirdrop(msgSender, address(_token), _amount);
    }

    // Move LP tokens from one sale to another directly => Automatically claims rewards and airdrops also
    function moveLPTokens(uint256 _pid, uint256 _newpid, uint256 _amount, address _lpAdd) external {
        require(stakingEnabled[_lpAdd]==true, "NAT1"); // NOT AUTHORISED TOKEN 1
        RaisePoolInfo storage poolOld = poolInfo[_pid];
        RaisePoolInfo storage poolNew = poolInfo[_newpid];
        require(block.number > poolOld.endBlock, "NUA"); // OLD SALE NOT ENDED
        require(block.number < poolNew.startBlock, "NSA"); // SALE START CHECK FAILED
        address msgSender = _msgSender();
        claimRewardAndAirdrop(_pid);
        userStakeInfo[_pid][msgSender][_lpAdd] = (userStakeInfo[_pid][msgSender][_lpAdd]).sub(_amount);
        userStakeInfo[_newpid][msgSender][_lpAdd] = (userStakeInfo[_newpid][msgSender][_lpAdd]).add(_amount);
        emit MoveStake(msg.sender, _lpAdd, _pid, _newpid, _amount);
    }

    function claimRewardAndAirdrop(uint256 _pid) public {
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number > pool.endBlock, "SE"); // SUM INVALID
        _claimReward(_pid, _msgSender());
        _claimAirdrop(_pid, _msgSender());
    }

    function _claimReward(uint256 _pid, address _user) internal {
        if (rewardClaimed[_pid][_user]==false){
            rewardClaimed[_pid][_user] = true;
            for (uint256 i=0; i<stakingPools.length; i++){
                for(uint256 j=0; j<listSupportedCurrencies[_pid].length; j++){
                    uint256 _tokenAmt = getReward(_pid, _user, stakingPools[i], listSupportedCurrencies[_pid][j]);
                    _creditAirdrop(_user, listSupportedCurrencies[_pid][j], _tokenAmt);
                }
            }
        }
    }

    function _claimAirdrop(uint256 _pid, address _user) internal {
        if (airdropClaimed[_pid][_user]==false){
            airdropClaimed[_pid][_user] = true;
            address _airdropToken = address(airdropInfo[_pid].airdropToken);
            uint256 _tokenAmt = 0;
            for (uint256 i=0; i<stakingPools.length; i++){
                _tokenAmt = _tokenAmt.add(getAirdrop(_pid, _user, stakingPools[i]));
            }
            if(_tokenAmt !=0){
                _creditAirdrop(_user, _airdropToken, _tokenAmt);
            }
        }
    }

    function _creditAirdrop(address _user, address _token, uint256 _amt) internal {
        airdropBalances[_token][_user] = (airdropBalances[_token][_user]).add(_amt);
        emit ClaimAirdrop(_user, _token, _amt);
    }

    function getReward(uint256 _pid, address _user, address _lpAdd, address _token) public view returns (uint256) {
          uint256 stake = stakedLPTokensInfo[_pid][_lpAdd];
          if(stake==0) return 0;
          uint256 _multipliedData = (userStakeInfo[_pid][_user][_lpAdd]).mul(fundsRaisedSoFar[_pid][_token]);
          _multipliedData = (_multipliedData).mul(rewardPer).mul(fee).mul(stakingWeight[_lpAdd]);
          return (((_multipliedData).div(stake)).div(1e8)).div(totalStakeWeight);
    }

    function getAirdrop(uint256 _pid, address _user, address _lpAdd) public view returns (uint256) {
          uint256 _userStaked = userStakeInfo[_pid][_user][_lpAdd];
          uint256 _totalStaked = stakedLPTokensInfo[_pid][_lpAdd];
          if(_totalStaked==0) return 0;
          return ((((_userStaked).mul(airdropInfo[_pid].totalTokensAvailable).mul(stakingWeight[_lpAdd])).div(_totalStaked))).div(totalStakeWeight);
    }

    // Deposit ICO tokens for a use case as reserve.
    function depositReserveICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd, address _resAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        address msgSender = _msgSender();
        require(_tokenAdd == pool.raiseToken, "NOT"); // NOT AUTHORISED TOKEN
        require(msgSender == pool.owner, "NAU"); // NOT AUTHORISED USER
        require(poolU.tokensDeposited == false, "DR"); // TOKENS NOT DEPOSITED
        require(poolU.tokensAllocated == _amount && _amount!=0, "NA"); // NOT AVAILABLE
        require(block.number < pool.endBlock, "CRN"); // CANNOT_RESERVE_NOW to avoid deadlocks
        _tokenAdd.safeTransferFrom(msgSender, address(this), _amount);
        totalTokenReserved[_pid] = (totalTokenReserved[_pid]).add(_amount);
        poolU.tokensDeposited = true;
        emit Deposit(msg.sender, _pid, _amount);
    }

    

    // Withdraw extra unsold ICO tokens or extra deposited tokens.
    function withdrawExtraICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        address msgSender = _msgSender();

        require(_tokenAdd == pool.raiseToken, "NT"); // NOT AUTHORISED TOKEN
        require(msgSender == pool.owner, "NAU"); // NOT AUTHORISED USER
        require(block.number > pool.endBlock, "NA"); // NOT AVAILABLE TIME

        uint256 _amtAvail = pool.tokensDeposited.sub(pool.totalTokensSold);
        require(_amtAvail >= _amount, "NAT"); // NOT AVAILABLE TOKEN
        pool.tokensDeposited = (pool.tokensDeposited).sub(_amount);
        _tokenAdd.safeTransfer(msgSender, _amount);
        emit Withdraw(msgSender, _pid, _amount);
    }


    // Fetch extra ICO tokens available.
    function fetchExtraICOTokens(uint256 _pid) external view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        return pool.tokensDeposited.sub(pool.totalTokensSold);
    }


    // Deposit tokens to a pool for ICO.
    function deposit(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        address msgSender = _msgSender();
        uint256 _buyThisStep = _checkDepositAllowed(_pid, address(_tokenAdd), _amount);
        // require(_buyThisStep >= _amount, "CDE");
        _tokenAdd.safeTransferFrom(msgSender, address(this), _amount);
        userDepositInfo[_pid][msgSender][address(_tokenAdd)] = userDepositInfo[_pid][msgSender][address(_tokenAdd)].add(_amount);
        userTokenAllocation[_pid][msgSender] = userTokenAllocation[_pid][msgSender].add(_buyThisStep);
        poolInfo[_pid].totalTokensSold = poolInfo[_pid].totalTokensSold.add(_buyThisStep);
        fundsRaisedSoFar[_pid][address(_tokenAdd)] = fundsRaisedSoFar[_pid][address(_tokenAdd)].add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }


    // Vote your favourite ICO project.
    function voteProject(uint256 _pid) external {
        address msgSender = _msgSender();
        require(userVotes[_pid][msgSender]==false,"AVO"); // ALREADY VOTED
        require(poolInfo[_pid].endBlock >= block.number,"CVO"); // CANNOT VOTE NOW
        userVotes[_pid][msgSender] = true;
        poolInfo[_pid].votes = (poolInfo[_pid].votes).add(1);
        emit Voted(msgSender, _pid);
    }

    function _calculatePerAvailable(uint256[] memory _daysArray, uint256[] memory _percentArray, uint256 blockEnd) internal view returns (uint256) {
        uint256 _defaultPer = 10000;
        uint256 _perNow;
        if(_daysArray.length==0){
            return _defaultPer;
        }
        uint256 daysDone = ((block.number).sub(blockEnd)).div(BLOCKS_PER_DAY);
        for (uint256 i = 0; i < _daysArray.length; i++) {
            if(_daysArray[i] <= daysDone){
                _perNow = _perNow.add(_percentArray[i]);
            }
            else {
                break;
            }
        }
        return _perNow;
    }

    function _getPercentAvailable(uint256 _pid, uint256 blockEnd) internal view returns (uint256){
        DistributionInfo storage distInfo = userDistInfo[_pid];
        uint256[] storage _percentArray = distInfo.percentArray;
        uint256[] storage _daysArray = distInfo.daysArray;
        return _calculatePerAvailable(_daysArray, _percentArray, blockEnd);
    }

    // Check amount of ICO tokens withdrawable by user till now - public
    function amountAvailToWithdrawUser(uint256 _pid, address _user) public view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        if(pool.endBlock < block.number){
            uint256 percentAvail = _getPercentAvailable(_pid, pool.endBlock);
            return ((percentAvail).mul(userTokenAllocation[_pid][_user]).div(10000)).sub(userTokenClaimed[_pid][_user]);
        }
        else {
            return 0;
        }
    }

    // Withdraw ICO tokens after sale is over based on distribution rules.
    function withdrawUser(uint256 _pid, uint256 _amount) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        address msgSender = _msgSender();
        uint256 _amtAvail = amountAvailToWithdrawUser(_pid, msgSender);
        require(_amtAvail >= _amount, "NAT"); // NOT AUTHORISED TOKEN
        userTokenClaimed[_pid][msgSender] = userTokenClaimed[_pid][msgSender].add(_amount);
        totalTokenClaimed[_pid] = totalTokenClaimed[_pid].add(_amount);
        pool.raiseToken.safeTransfer(msgSender, _amount);
        emit Withdraw(msgSender, _pid, _amount);
    }


    function _getPercentAvailableFundRaiser(uint256 _pid, uint256 blockEnd) internal view returns (uint256){
        DistributionInfo storage distInfo = ownerDistInfo[_pid];
        uint256[] storage _percentArray = distInfo.percentArray;
        uint256[] storage _daysArray = distInfo.daysArray;
        return _calculatePerAvailable(_daysArray, _percentArray, blockEnd);
    }

    // Check amount of ICO tokens withdrawable by user till now
    function amountAvailToWithdrawFundRaiser(uint256 _pid, IERC20 _tokenAdd) public view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        if(pool.endBlock < block.number){
            uint256 percentAvail = _getPercentAvailableFundRaiser(_pid, pool.endBlock);
            return (((percentAvail).mul(fundsRaisedSoFar[_pid][address(_tokenAdd)]).div(10000))).sub(fundsClaimedSoFar[_pid][address(_tokenAdd)]);
        }
        else {
            return 0;
        }
    }

    function _getPercentAvailableReserve(uint256 _pid, uint256 blockEnd, address _resAdd) internal view returns (uint256){
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        uint256[] storage _percentArray = poolU.unlock_perArray;
        uint256[] storage _daysArray = poolU.unlock_daysArray;
        return _calculatePerAvailable(_daysArray, _percentArray, blockEnd);
    }

    // Check amount of ICO tokens withdrawable by reserve user till now
    function amountAvailToWithdrawReserve(uint256 _pid, address _resAdd) public view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        if(pool.endBlock < block.number){
            uint256 percentAvail = _getPercentAvailableReserve(_pid, pool.endBlock, _resAdd);
            return ((percentAvail).mul(poolU.tokensAllocated).div(10000)).sub(poolU.tokensClaimed);
        }
        else {
            return 0;
        }
    }


    // Withdraw ICO tokens for various use cases as per the schedule promised on provided address.
    function withdrawReserveICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_msgSender()];
        require(poolU.reserveAdd == _msgSender(), "NAUTH"); // NOT AUTHORISED USER
        require(_tokenAdd == poolInfo[_pid].raiseToken, "NT"); // NOT AUTHORISED TOKEN
        uint256 _amtAvail = amountAvailToWithdrawReserve(_pid, _msgSender());
        require(_amtAvail >= _amount, "NAT"); // NOT AVAILABLE USER
        poolU.tokensClaimed = poolU.tokensClaimed.add(_amount);
        totalTokenReserved[_pid] = totalTokenReserved[_pid].sub(_amount);
        totalReservedTokenClaimed[_pid] = totalReservedTokenClaimed[_pid].add(_amount);
        _tokenAdd.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _pid, _amount);
    }


    // Withdraw raised funds after sale is over as per the schedule promised
    function withdrawFundRaiser(uint256 _pid, uint256 _amount, IERC20 _tokenAddress) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(pool.owner == _msgSender(), "NAUTH"); // NOT AUTHORISED USER
        uint256 _amtAvail = amountAvailToWithdrawFundRaiser(_pid, _tokenAddress);
        require(_amtAvail >= _amount, "NAT"); // NOT AUTHORISED TOKEN
        uint256 _fee = ((_amount).mul(fee)).div(1e4);
        uint256 _actualTransfer = _amtAvail.sub(_fee);
        uint256 _feeDev = (_fee).mul(10000 - rewardPer).div(1e4); // Remaining tokens for reward mining 
        fundsClaimedSoFar[_pid][address(_tokenAddress)] = fundsClaimedSoFar[_pid][address(_tokenAddress)].add(_amount);
        _tokenAddress.safeTransfer(_msgSender(), _actualTransfer);
        _tokenAddress.safeTransfer(devaddr, _feeDev);
        emit Withdraw(_msgSender(), _pid, _actualTransfer);
        emit Withdraw(devaddr, _pid, _feeDev);
    }

    // Update dev address by initiating with the previous dev.
    function changeDev(address _newowner) external onlyAdmin {
        potentialAdmin = _newowner;
    }

    function becomeDev() external {
        require(potentialAdmin == msg.sender, "NA"); // NOT ALLOWED
        devaddr = msg.sender;
    }

    // Update temp pool owner address by initiating with the previous pool owner.
    function changePoolOwner(uint256 _pid, address _newowner) external {
        require(_msgSender()==poolInfo[_pid].owner, "OA"); // NOT AUTHORISED USER
        tempAdmin[_pid] = _newowner;
    }

    // Claim pool ownership with new address
    function becomePoolOwner(uint256 _pid) external {
        if (tempAdmin[_pid] == _msgSender()) poolInfo[_pid].owner = _msgSender();
    }

    // Update fee, can never be more than 3%.
    function changeFee(uint256 _fee) external onlyAdmin{
        require(_fee <= 300, "MAX3"); // MAX FEE POSSIBLE
        fee = _fee;
    }

    // To generate a new invite code
    function generateNewCode(address _token, address _poolOwner) external onlyAdminOrTimeLock returns (uint256) {
        uint256 inviteCode = block.number;
        inviteCodeList[inviteCode][_token][_poolOwner] = true;
        return inviteCode;
    }

    // To invalidate an invite code
    function invalidateOldCode(uint256 _inviteCode, address _token, address _poolOwner) external onlyAdmin {
        inviteCodeList[_inviteCode][_token][_poolOwner] = false;
    }


    // To add or update a staking pool with weight
    function addStakingPool(address _token, uint256 _weight) external onlyAdmin {
        if(stakingEnabled[_token]==false){
            stakingPools.push(_token);  
            stakingEnabled[_token] = true;  
        }
        totalStakeWeight = totalStakeWeight.sub(stakingWeight[_token]).add(_weight);
        stakingWeight[_token] = _weight;
    }

}