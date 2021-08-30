/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity >=0.6.2 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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


// Dependency file: contracts/libraries/TransferHelper.sol

// pragma solidity >=0.6.5 <0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/libraries/Upgradable.sol

// pragma solidity >=0.6.5 <0.8.0;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, "FORBIDDEN");
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), "INVALID_ADDRESS");
        require(_newImpl != impl, "NO_CHANGE");
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(
        address indexed _oldGovernor,
        address indexed _newGovernor
    );

    constructor() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, "FORBIDDEN");
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), "INVALID_ADDRESS");
        require(_newGovernor != governor, "NO_CHANGE");
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/ERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

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


// Dependency file: contracts/libraries/Convert.sol

// pragma solidity >=0.6.5 <0.8.0;

pragma experimental ABIEncoderV2;

// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/math/SafeMath.sol';

contract Convert {
	using SafeMath for uint256;

	function convertTokenAmount(
		address _fromToken,
		address _toToken,
		uint256 _fromAmount
	) public view returns (uint256 toAmount) {
		uint256 fromDecimals = uint256(ERC20(_fromToken).decimals());
		uint256 toDecimals = uint256(ERC20(_toToken).decimals());
		if (fromDecimals > toDecimals) {
			toAmount = _fromAmount.div(10**(fromDecimals.sub(toDecimals)));
		} else if (toDecimals > fromDecimals) {
			toAmount = _fromAmount.mul(10**(toDecimals.sub(fromDecimals)));
		} else {
			toAmount = _fromAmount;
		}
		return toAmount;
	}
}


// Dependency file: contracts/interfaces/IERC20Burnable.sol

// pragma solidity >=0.6.5 <0.8.0;

interface IERC20Burnable {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}


// Dependency file: contracts/interfaces/IDetailedERC20.sol

// pragma solidity >=0.6.5 <0.8.0;

interface IDetailedERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


// Root file: contracts/Oven.sol

pragma solidity >=0.6.5 <0.8.0;



contract Oven is ReentrancyGuard, UpgradableProduct, Convert {
	using SafeMath for uint256;
	using TransferHelper for address;
	using Address for address;

	address public constant ZERO_ADDRESS = address(0);
	uint256 public EXCHANGE_PERIOD;

	address public friesToken;
	address public token;

	mapping(address => uint256) public depositedFriesTokens;
	mapping(address => uint256) public tokensInBucket;
	mapping(address => uint256) public realisedTokens;
	mapping(address => uint256) public lastDividendPoints;

	mapping(address => bool) public userIsKnown;
	mapping(uint256 => address) public userList;
	uint256 public nextUser;

	uint256 public totalSupplyFriesTokens;
	uint256 public buffer;
	uint256 public lastDepositBlock;

	uint256 public pointMultiplier = 10**18;

	// SHARE
	uint256 public totalDividendPoints;
	// DAI/USDT/USDC Income
	uint256 public unclaimedDividends;

	address public upgradeAddress;
	uint256 public upgradeTime;
	uint256 public upgradeAmount;

	mapping(address => bool) public whiteList;

	event UpgradeSettingUpdate(address upgradeAddress, uint256 upgradeTime, uint256 upgradeAmount);
	event Upgrade(address upgradeAddress, uint256 upgradeAmount);
	event ExchangerPeriodUpdated(uint256 newTransmutationPeriod);

	constructor(address _friesToken, address _token) public {
		friesToken = _friesToken;
		token = _token;
		EXCHANGE_PERIOD = 50;
	}

	///@return displays the user's share of the pooled friesTokens.
	function dividendsOwing(address account) public view returns (uint256) {
		uint256 newDividendPoints = totalDividendPoints.sub(lastDividendPoints[account]);
		return depositedFriesTokens[account].mul(newDividendPoints).div(pointMultiplier);
	}

	///@dev modifier to fill the bucket and keep bookkeeping correct incase of increase/decrease in shares
	modifier updateAccount(address account) {
		uint256 owing = dividendsOwing(account);
		if (owing > 0) {
			unclaimedDividends = unclaimedDividends.sub(owing);
			tokensInBucket[account] = tokensInBucket[account].add(owing);
		}
		lastDividendPoints[account] = totalDividendPoints;
		_;
	}
	///@dev modifier add users to userlist. Users are indexed in order to keep track of when a bond has been filled
	modifier checkIfNewUser() {
		if (!userIsKnown[msg.sender]) {
			userList[nextUser] = msg.sender;
			userIsKnown[msg.sender] = true;
			nextUser++;
		}
		_;
	}

	///@dev run the phased distribution of the buffered funds
	modifier runPhasedDistribution() {
		uint256 _lastDepositBlock = lastDepositBlock;
		uint256 _currentBlock = block.number;
		uint256 _toDistribute = 0;
		uint256 _buffer = buffer;

		// check if there is something in bufffer
		if (_buffer > 0) {
			// NOTE: if last deposit was updated in the same block as the current call
			// then the below logic gates will fail

			//calculate diffrence in time
			uint256 deltaTime = _currentBlock.sub(_lastDepositBlock);

			// distribute all if bigger than timeframe
			if (deltaTime >= EXCHANGE_PERIOD) {
				_toDistribute = _buffer;
			} else {
				//needs to be bigger than 0 cuzz solidity no decimals
				if (_buffer.mul(deltaTime) > EXCHANGE_PERIOD) {
					_toDistribute = _buffer.mul(deltaTime).div(EXCHANGE_PERIOD);
				}
			}

			// factually allocate if any needs distribution
			if (_toDistribute > 0) {
				// remove from buffer
				buffer = _buffer.sub(_toDistribute);

				// increase the allocation
				increaseAllocations(_toDistribute);
			}
		}

		// current timeframe is now the last
		lastDepositBlock = _currentBlock;
		_;
	}

	/// @dev A modifier which checks if whitelisted for minting.
	modifier onlyWhitelisted() {
		require(whiteList[msg.sender], '!whitelisted');
		_;
	}

	///@dev set the EXCHANGE_PERIOD variable
	///
	/// sets the length (in blocks) of one full distribution phase
	function setExchangePeriod(uint256 newExchangePeriod) public requireImpl {
		EXCHANGE_PERIOD = newExchangePeriod;
		emit ExchangerPeriodUpdated(EXCHANGE_PERIOD);
	}

	///@dev claims the base token after it has been exchange
	///
	///This function reverts if there is no realisedToken balance
	function claim() public nonReentrant {
		address sender = msg.sender;
		require(realisedTokens[sender] > 0);
		uint256 value = realisedTokens[sender];
		realisedTokens[sender] = 0;
		token.safeTransfer(sender, value);
	}

	///@dev Withdraws staked friesTokens from the exchange
	///
	/// This function reverts if you try to draw more tokens than you deposited
	///
	///@param amount the amount of friesTokens to unstake
	function unstake(uint256 amount) public nonReentrant runPhasedDistribution() updateAccount(msg.sender) {
		// by calling this function before transmuting you forfeit your gained allocation
		address sender = msg.sender;

		uint256 tokenAmount = convertTokenAmount(friesToken, token, amount);
		amount = convertTokenAmount(token, friesToken, tokenAmount);
		require(tokenAmount > 0, 'The amount is too small');

		require(depositedFriesTokens[sender] >= amount, 'unstake amount exceeds deposited amount');
		depositedFriesTokens[sender] = depositedFriesTokens[sender].sub(amount);
		totalSupplyFriesTokens = totalSupplyFriesTokens.sub(amount);
		friesToken.safeTransfer(sender, amount);
	}

	///@dev Deposits friesTokens into the exchange
	///
	///@param amount the amount of friesTokens to stake
	function stake(uint256 amount)
		public
		nonReentrant
		runPhasedDistribution()
		updateAccount(msg.sender)
		checkIfNewUser()
	{
		// precision
		uint256 tokenAmount = convertTokenAmount(friesToken, token, amount);
		amount = convertTokenAmount(token, friesToken, tokenAmount);
		require(tokenAmount > 0, 'The amount is too small');

		// requires approval of AlToken first
		address sender = msg.sender;
		//require tokens transferred in;
		friesToken.safeTransferFrom(sender, address(this), amount);
		totalSupplyFriesTokens = totalSupplyFriesTokens.add(amount);
		depositedFriesTokens[sender] = depositedFriesTokens[sender].add(amount);
	}

	function exchange() public nonReentrant runPhasedDistribution() updateAccount(msg.sender) {
		address sender = msg.sender;
		uint256 pendingz = tokensInBucket[sender]; //
		uint256 pendingzToFries = convertTokenAmount(token, friesToken, pendingz); // fries
		uint256 diff; // token

		require(pendingz > 0 && pendingzToFries > 0, 'need to have pending in bucket');

		tokensInBucket[sender] = 0;

		// check bucket overflow
		if (pendingzToFries > depositedFriesTokens[sender]) {
			diff = convertTokenAmount(friesToken, token, pendingzToFries.sub(depositedFriesTokens[sender]));
			// remove overflow
			pendingzToFries = depositedFriesTokens[sender];
			pendingz = convertTokenAmount(friesToken, token, pendingzToFries);
			require(pendingz > 0 && pendingzToFries > 0, 'need to have pending in bucket');
		}

		// decrease friesTokens
		depositedFriesTokens[sender] = depositedFriesTokens[sender].sub(pendingzToFries);

		// BURN friesTokens
		IERC20Burnable(friesToken).burn(pendingzToFries);

		// adjust total
		totalSupplyFriesTokens = totalSupplyFriesTokens.sub(pendingzToFries);

		// reallocate overflow
		increaseAllocations(diff);

		// add payout
		realisedTokens[sender] = realisedTokens[sender].add(pendingz);
	}

	function forceExchange(address toExchange)
		public
		nonReentrant
		runPhasedDistribution()
		updateAccount(msg.sender)
		updateAccount(toExchange)
	{
		//load into memory
		address sender = msg.sender;
		uint256 pendingz = tokensInBucket[toExchange];
		uint256 pendingzToFries = convertTokenAmount(token, friesToken, pendingz);
		// check restrictions
		require(pendingzToFries > depositedFriesTokens[toExchange], '!overflow');

		// empty bucket
		tokensInBucket[toExchange] = 0;

		address _toExchange = toExchange;

		// calculaate diffrence
		uint256 diff = convertTokenAmount(friesToken, token, pendingzToFries.sub(depositedFriesTokens[_toExchange]));

		// remove overflow
		pendingzToFries = depositedFriesTokens[_toExchange];

		// decrease friesTokens
		depositedFriesTokens[_toExchange] = 0;

		// BURN friesTokens
		IERC20Burnable(friesToken).burn(pendingzToFries);

		// adjust total
		totalSupplyFriesTokens = totalSupplyFriesTokens.sub(pendingzToFries);

		// reallocate overflow
		tokensInBucket[sender] = tokensInBucket[sender].add(diff);

		uint256 payout = convertTokenAmount(friesToken, token, pendingzToFries);

		// add payout
		realisedTokens[_toExchange] = realisedTokens[_toExchange].add(payout);

		// force payout of realised tokens of the toExchange address
		if (realisedTokens[_toExchange] > 0) {
			uint256 value = realisedTokens[_toExchange];
			realisedTokens[_toExchange] = 0;
			token.safeTransfer(_toExchange, value);
		}
	}

	function exit() public {
		exchange();
		uint256 toWithdraw = depositedFriesTokens[msg.sender];
		unstake(toWithdraw);
	}

	function exchangeAndClaim() public {
		exchange();
		claim();
	}

	function exchangeClaimAndWithdraw() public {
		exchange();
		claim();
		uint256 toWithdraw = depositedFriesTokens[msg.sender];
		unstake(toWithdraw);
	}

	/// @dev Distributes the base token proportionally to all alToken stakers.
	///
	/// This function is meant to be called by the Fries contract for when it is sending yield to the exchange.
	/// Anyone can call this and add funds, idk why they would do that though...
	///
	/// @param origin the account that is sending the tokens to be distributed.
	/// @param amount the amount of base tokens to be distributed to the exchange.
	function distribute(address origin, uint256 amount) public onlyWhitelisted runPhasedDistribution {
		token.safeTransferFrom(origin, address(this), amount);
		buffer = buffer.add(amount);
	}

	/// @dev Allocates the incoming yield proportionally to all alToken stakers.
	///
	/// @param amount the amount of base tokens to be distributed in the exchange.
	function increaseAllocations(uint256 amount) internal {
		if (totalSupplyFriesTokens > 0 && amount > 0) {
			totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(totalSupplyFriesTokens));
			unclaimedDividends = unclaimedDividends.add(amount);
		} else {
			buffer = buffer.add(amount);
		}
	}

	/// @dev Gets the status of a user's staking position.
	///
	/// The total amount allocated to a user is the sum of pendingdivs and inbucket.
	///
	/// @param user the address of the user you wish to query.
	///
	/// returns user status

	function userInfo(address user)
		public
		view
		returns (
			uint256 depositedToken,
			uint256 pendingdivs,
			uint256 inbucket,
			uint256 realised
		)
	{
		uint256 _depositedToken = depositedFriesTokens[user];
		uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(EXCHANGE_PERIOD);
		if (block.number.sub(lastDepositBlock) > EXCHANGE_PERIOD) {
			_toDistribute = buffer;
		}
		uint256 _pendingdivs = 0;

		if (totalSupplyFriesTokens > 0) {
			_pendingdivs = _toDistribute.mul(depositedFriesTokens[user]).div(totalSupplyFriesTokens);
		}
		uint256 _inbucket = tokensInBucket[user].add(dividendsOwing(user));
		uint256 _realised = realisedTokens[user];
		return (_depositedToken, _pendingdivs, _inbucket, _realised);
	}

	/// @dev Gets the status of multiple users in one call
	///
	/// This function is used to query the contract to check for
	/// accounts that have overfilled positions in order to check
	/// who can be force exchange.
	///
	/// @param from the first index of the userList
	/// @param to the last index of the userList
	///
	/// returns the userList with their staking status in paginated form.
	function getMultipleUserInfo(uint256 from, uint256 to)
		public
		view
		returns (address[] memory theUserList, uint256[] memory theUserData)
	{
		uint256 i = from;
		uint256 delta = to - from;
		address[] memory _theUserList = new address[](delta); //user
		uint256[] memory _theUserData = new uint256[](delta * 2); //deposited-bucket
		uint256 y = 0;
		uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(EXCHANGE_PERIOD);
		if (block.number.sub(lastDepositBlock) > EXCHANGE_PERIOD) {
			_toDistribute = buffer;
		}
		for (uint256 x = 0; x < delta; x += 1) {
			_theUserList[x] = userList[i];
			_theUserData[y] = depositedFriesTokens[userList[i]];

			uint256 pending = 0;
			if (totalSupplyFriesTokens > 0) {
				pending = _toDistribute.mul(depositedFriesTokens[userList[i]]).div(totalSupplyFriesTokens);
			}

			_theUserData[y + 1] = dividendsOwing(userList[i]).add(tokensInBucket[userList[i]]).add(pending);
			y += 2;
			i += 1;
		}
		return (_theUserList, _theUserData);
	}

	/// @dev Gets info on the buffer
	///
	/// This function is used to query the contract to get the
	/// latest state of the buffer
	///
	/// @return _toDistribute the amount ready to be distributed
	/// @return _deltaBlocks the amount of time since the last phased distribution
	/// @return _buffer the amount in the buffer
	function bufferInfo()
		public
		view
		returns (
			uint256 _toDistribute,
			uint256 _deltaBlocks,
			uint256 _buffer
		)
	{
		_deltaBlocks = block.number.sub(lastDepositBlock);
		_buffer = buffer;
		_toDistribute = _buffer.mul(_deltaBlocks).div(EXCHANGE_PERIOD);
	}

	/// This function reverts if the caller is not governance
	///
	/// @param _toWhitelist the account to mint tokens to.
	/// @param _state the whitelist state.
	function setWhitelist(address _toWhitelist, bool _state) external requireImpl {
		whiteList[_toWhitelist] = _state;
	}

	/// @notice Ensure that oven is invalid first!! then upgradesetting could be called.
	function upgradeSetting(
		address _upgradeAddress,
		uint256 _upgradeTime,
		uint256 _upgradeAmount
	) external requireImpl {
		require(_upgradeAddress != address(0) && _upgradeAddress != address(this), '!upgradeAddress');
		require(_upgradeTime > block.timestamp, '!upgradeTime');
		require(_upgradeAmount > 0, '!upgradeAmount');

		upgradeAddress = _upgradeAddress;
		upgradeTime = _upgradeTime;
		upgradeAmount = _upgradeAmount;
		emit UpgradeSettingUpdate(upgradeAddress, upgradeTime, upgradeAmount);
	}

	/// @notice Operation notice!
	/// @notice The assets((DAI/USDT/USDC)) total value should be equal or more than user's fryUSD.
	/// @notice Require upgradeAmount <=  DAI/USDT/USDC - fryUSD
	function upgrade() external requireImpl {
		require(
			upgradeAddress != address(0) && upgradeAmount > 0 && block.timestamp > upgradeTime && upgradeTime > 0,
			'!upgrade'
		);
		token.safeApprove(upgradeAddress, upgradeAmount);
		Oven(upgradeAddress).distribute(address(this), upgradeAmount);
		upgradeAddress = address(0);
		upgradeAmount = 0;
		upgradeTime = 0;
		emit Upgrade(upgradeAddress, upgradeAmount);
	}
}