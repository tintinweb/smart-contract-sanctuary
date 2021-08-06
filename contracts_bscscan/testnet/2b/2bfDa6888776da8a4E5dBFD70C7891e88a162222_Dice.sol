/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


// 
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

// 
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

// 
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

// 
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
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
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// 
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

// 
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// 
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

// 
/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
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
     * problems described in {BEP20-approve}.
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal returns(bool) {
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}

// 
// Dice token with Governance.
contract DiceToken is BEP20 {

	constructor(string memory name, string memory symbol) public BEP20(name, symbol) {}

    /// @notice Creates _amount token to _to.
    function mint(address _to, uint256 _amount) external onlyOwner returns(bool) {
        _mint(_to, _amount);
        return true;
    }

	function burn(address _to, uint256 _amount) external onlyOwner {
		_burn(_to, _amount);
	}
}

// 
/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// 
interface ILuckyChipRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapFeeReward() external pure returns (address);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

// 
interface IMasterChef {
    /**
     * @dev Update bonus.
     */
    function updateBonus(uint256 _pid) external;
}

// 
contract Dice is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public prevBankerAmount;
    uint256 public bankerAmount;
    uint256 public netValue;
    uint256 public currentEpoch;
    uint256 public playerEndBlock;
    uint256 public bankerEndBlock;
    uint256 public totalBonusAmount;
    uint256 public masterChefBonusId;
    uint256 public intervalBlocks;
    uint256 public playerTimeBlocks;
    uint256 public bankerTimeBlocks;
    uint256 public constant TOTAL_RATE = 10000; // 100%
    uint256 public gapRate = 500;
    uint256 public lcBackRate = 1000; // 10% in gap
    uint256 public bonusRate = 1000; // 10% in gap
    uint256 public minBetAmount;
    uint256 public maxBetRatio = 5;
    uint256 public maxExposureRatio = 300;
    uint256 public feeAmount;
    uint256 public maxBankerAmount;

    address public adminAddress;
    address public masterChefAddress;
    IBEP20 public token;
    IBEP20 public lcToken;
    DiceToken public diceToken;    
    ILuckyChipRouter02 public swapRouter;

    enum Status {
        Pending,
        Open,
        Lock,
        Claimable,
        Expired
    }

    struct Round {
        uint256 startBlock;
        uint256 lockBlock;
        uint256 secretSentBlock;
        bytes32 bankHash;
        uint256 bankSecret;
        uint256 totalAmount;
        uint256 maxBetAmount;
        uint256[6] betAmounts;
        uint256 lcBackAmount;
        uint256 bonusAmount;
        uint256 swapLcAmount;
        uint256 betUsers;
        uint32 finalNumber;
        Status status;
    }

    struct BetInfo {
        uint256 amount;
        uint16 numberCount;    
        bool[6] numbers;
        bool claimed; // default false
        bool lcClaimed; // default false
    }

    struct BankerInfo {
        uint256 diceTokenAmount;
        uint256 avgBuyValue;
    }

    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;
    mapping(address => BankerInfo) public bankerInfo;

    event RatesUpdated(uint256 indexed block, uint256 gapRate, uint256 lcBackRate, uint256 bonusRate);
    event AmountsUpdated(uint256 indexed block, uint256 minBetAmount, uint256 feeAmount, uint256 maxBankerAmount);
    event RatiosUpdated(uint256 indexed block, uint256 maxBetRatio, uint256 maxExposureRatio);
    event StartRound(uint256 indexed epoch, uint256 blockNumber, bytes32 bankHash);
    event LockRound(uint256 indexed epoch, uint256 blockNumber);
    event SendSecretRound(uint256 indexed epoch, uint256 blockNumber, uint256 bankSecret, uint32 finalNumber);
    event BetNumber(address indexed sender, uint256 indexed currentEpoch, bool[6] numbers, uint256 amount);
    event Claim(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event ClaimBonusLC(address indexed sender, uint256 amount);
    event ClaimBonus(uint256 amount);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 lcbackamount,
        uint256 bonusamount,
        uint256 swaplcamount
    );
    event SwapRouterUpdated(address indexed router);
    event EndPlayerTime(uint256 epoch, uint256 blockNumber);
    event EndBankerTime(uint256 epoch, uint256 blockNumber);
    event UpdateNetValue(uint256 epoch, uint256 blockNumber, uint256 netValue);
    event Deposit(address indexed user, uint256 tokenAmount);    
    event Withdraw(address indexed user, uint256 diceTokenAmount);    

    constructor(
        address _tokenAddress,
        address _lcTokenAddress,
        address _diceTokenAddress,
        address _masterChefAddress,
        uint256 _masterChefBonusId,
        uint256 _intervalBlocks,
        uint256 _playerTimeBlocks,
        uint256 _bankerTimeBlocks,
        uint256 _minBetAmount,
        uint256 _feeAmount,
        uint256 _maxBankerAmount
    ) public {
        token = IBEP20(_tokenAddress);
        lcToken = IBEP20(_lcTokenAddress);
        diceToken = DiceToken(_diceTokenAddress);
        masterChefAddress = _masterChefAddress;
        masterChefBonusId = _masterChefBonusId;
        intervalBlocks = _intervalBlocks;
        playerTimeBlocks = _playerTimeBlocks;
        bankerTimeBlocks = _bankerTimeBlocks;
        minBetAmount = _minBetAmount;
        feeAmount = _feeAmount;
        maxBankerAmount = _maxBankerAmount;
        netValue = uint256(1e12);
        _pause();
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    // set blocks
    function setBlocks(uint256 _intervalBlocks, uint256 _playerTimeBlocks, uint256 _bankerTimeBlocks) external onlyAdmin {
        intervalBlocks = _intervalBlocks;
        playerTimeBlocks = _playerTimeBlocks;
        bankerTimeBlocks = _bankerTimeBlocks;
    }

    // set rates
    function setRates(uint256 _gapRate, uint256 _lcBackRate, uint256 _bonusRate) external onlyAdmin {
        require(_gapRate <= 1000, "gapRate <= 10%");
        require(_lcBackRate.add(_bonusRate) <= TOTAL_RATE, "_lcBackRate + _bonusRate <= TOTAL_RATE");
        gapRate = _gapRate;
        lcBackRate = _lcBackRate;
        bonusRate = _bonusRate;

        emit RatesUpdated(block.number, gapRate, lcBackRate, bonusRate);
    }

    // set amounts
    function setAmounts(uint256 _minBetAmount, uint256 _feeAmount, uint256 _maxBankerAmount) external onlyAdmin {
        minBetAmount = _minBetAmount;
        feeAmount = _feeAmount;
        maxBankerAmount = _maxBankerAmount;
        emit AmountsUpdated(block.number, minBetAmount, feeAmount, maxBankerAmount);
    }

    // set ratios
    function setRatios(uint256 _maxBetRatio, uint256 _maxExposureRatio) external onlyAdmin {
        maxBetRatio = _maxBetRatio;
        maxExposureRatio = _maxExposureRatio;
        emit RatiosUpdated(block.number, maxBetRatio, maxExposureRatio);
    }

    // set admin address
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;
    }

    // End banker time
    function endBankerTime(uint256 epoch, bytes32 bankHash) external onlyAdmin whenPaused {
        require(epoch == currentEpoch + 1, "epoch == currentEpoch + 1");
        require(bankerAmount > 0, "Round can start only when bankerAmount > 0");
        prevBankerAmount = bankerAmount;
        _unpause();
        emit EndBankerTime(currentEpoch, block.timestamp);
        
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch, bankHash);
        playerEndBlock = rounds[currentEpoch].startBlock.add(playerTimeBlocks);
        bankerEndBlock = rounds[currentEpoch].startBlock.add(bankerTimeBlocks);
    }

    // Start the next round n, lock for round n-1
    function executeRound(uint256 epoch, bytes32 bankHash) external onlyAdmin whenNotPaused{
        require(epoch == currentEpoch, "epoch == currentEpoch");

        // CurrentEpoch refers to previous round (n-1)
        lockRound(currentEpoch);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch, bankHash);
        require(rounds[currentEpoch].startBlock < playerEndBlock, "startBlock < playerEndBlock");
        require(rounds[currentEpoch].lockBlock <= playerEndBlock, "lockBlock < playerEndBlock");
    }

    // end player time, triggers banker time
    function endPlayerTime(uint256 epoch, uint256 bankSecret) external onlyAdmin whenNotPaused{
        require(epoch == currentEpoch, "epoch == currentEpoch");
        sendSecret(epoch, bankSecret);
        _pause();
        _updateNetValue(epoch);
		_claimBonus();
        emit EndPlayerTime(currentEpoch, block.timestamp);
    }

    // end player time without caring last round
    function endPlayerTimeImmediately(uint256 epoch) external onlyAdmin whenNotPaused{
        require(epoch == currentEpoch, "epoch == currentEpoch");
        _pause();
        _updateNetValue(epoch);
		_claimBonus();
        emit EndPlayerTime(currentEpoch, block.timestamp);
    }

    // update net value
    function _updateNetValue(uint256 epoch) internal whenPaused{    
        netValue = netValue.mul(bankerAmount).div(prevBankerAmount);
        emit UpdateNetValue(epoch, block.timestamp, netValue);
    }

    // send bankSecret
    function sendSecret(uint256 epoch, uint256 bankSecret) public onlyAdmin whenNotPaused{
		Round storage round = rounds[epoch];
        require(round.lockBlock != 0, "End round after round has locked");
        require(round.status == Status.Lock, "End round after round has locked");
        require(block.number >= round.lockBlock, "Send secret after lockBlock");
        require(block.number <= round.lockBlock.add(intervalBlocks), "Send secret within intervalBlocks");
        require(round.bankSecret == 0, "Already revealed");
        require(keccak256(abi.encodePacked(bankSecret)) == round.bankHash, "Bank reveal not matching commitment");

        _safeSendSecret(epoch, bankSecret);
        _calculateRewards(epoch);
    }

    function _safeSendSecret(uint256 epoch, uint256 bankSecret) internal whenNotPaused {
        Round storage round = rounds[epoch];
        round.secretSentBlock = block.number;
        round.bankSecret = bankSecret;
        uint256 random = round.bankSecret ^ round.betUsers ^ block.difficulty;
        round.finalNumber = uint32(random % 6);
        round.status = Status.Claimable;

        emit SendSecretRound(epoch, block.number, bankSecret, round.finalNumber);
    }

    // bet number
    function betNumber(bool[6] calldata numbers, uint256 amount) external payable whenNotPaused notContract nonReentrant {
        Round storage round = rounds[currentEpoch];
		require(msg.value >= feeAmount, "msg.value > feeAmount");
        require(round.status == Status.Open, "Round not Open");
        require(block.number > round.startBlock && block.number < round.lockBlock, "Round not bettable");
        require(ledger[currentEpoch][msg.sender].amount == 0, "Bet once per round");
        uint16 numberCount = 0;
        uint256 maxSingleBetAmount = 0;
        for (uint32 i = 0; i < 6; i ++) {
            if (numbers[i]) {
                numberCount = numberCount + 1;    
                if(round.betAmounts[i] > maxSingleBetAmount){
                    maxSingleBetAmount = round.betAmounts[i];
                }
            }
        }
        require(numberCount > 0, "numberCount > 0");
        require(amount >= minBetAmount.mul(uint256(numberCount)), "BetAmount >= minBetAmount * numberCount");
        require(amount <= round.maxBetAmount.mul(uint256(numberCount)), "BetAmount <= round.maxBetAmount * numberCount");
        if(numberCount == 1){
            require(maxSingleBetAmount.add(amount).sub(round.totalAmount.sub(maxSingleBetAmount)) < bankerAmount.mul(maxExposureRatio).div(TOTAL_RATE), 'MaxExposure Limit');
        }
        
		if (feeAmount > 0){
            _safeTransferBNB(adminAddress, feeAmount);
        }

        token.safeTransferFrom(address(msg.sender), address(this), amount);

        // Update round data
        round.totalAmount = round.totalAmount.add(amount);
        round.betUsers = round.betUsers.add(1);
        uint256 betAmount = amount.div(uint256(numberCount));
        for (uint32 i = 0; i < 6; i ++) {
            if (numbers[i]) {
                round.betAmounts[i] = round.betAmounts[i].add(betAmount);
            }
        }

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][msg.sender];
        betInfo.numbers = numbers;
        betInfo.amount = amount;
        betInfo.numberCount = numberCount;
        userRounds[msg.sender].push(currentEpoch);

        emit BetNumber(msg.sender, currentEpoch, numbers, amount);
    }


    // Claim reward
    function claim(uint256 epoch) external notContract nonReentrant {
        require(rounds[epoch].startBlock != 0, "Round has not started");
        require(block.number > rounds[epoch].lockBlock, "Round has not locked");
        require(!ledger[epoch][msg.sender].claimed, "Rewards claimed");

        uint256 reward;
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        // Round valid, claim rewards
        if (rounds[epoch].status == Status.Claimable) {
            require(claimable(epoch, msg.sender), "Not eligible for claim");
			uint256 singleAmount = betInfo.amount.div(uint256(betInfo.numberCount));
            reward = singleAmount.mul(5).mul(TOTAL_RATE.sub(gapRate)).div(TOTAL_RATE);
			reward = reward.add(singleAmount);
        }
        // Round invalid, refund bet amount
        else {
            require(refundable(epoch, msg.sender), "Not eligible for refund");
            reward = ledger[epoch][msg.sender].amount;
        }

        betInfo.claimed = true;
        token.safeTransfer(msg.sender, reward);

        emit Claim(msg.sender, epoch, reward);
    }

    // Claim lc back
    function claimLcBack(address user) external notContract nonReentrant {
        uint256 lcAmount = 0;    
        uint256 epoch;
        uint256 roundLcAmount = 0;
        for (uint256 i = userRounds[user].length - 1; i >= 0; i --){
            epoch = userRounds[user][i];
            BetInfo storage betInfo = ledger[epoch][msg.sender];
            if (betInfo.lcClaimed){
                break;
            }else{
				Round storage round = rounds[epoch];
                if (round.status == Status.Claimable){
                    if (betInfo.numbers[round.finalNumber]){
                        roundLcAmount = betInfo.amount.div(uint256(betInfo.numberCount)).mul(5).mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE);
                        if (betInfo.numberCount > 1){
                            roundLcAmount = roundLcAmount.add(betInfo.amount.div(uint256(betInfo.numberCount)).mul(uint256(betInfo.numberCount - 1)).mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE));
                        }
                    }else{
                        roundLcAmount = betInfo.amount.mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE);
                    }

					roundLcAmount = roundLcAmount.mul(round.swapLcAmount).div(round.lcBackAmount);
                    lcAmount = lcAmount.add(roundLcAmount);
                    betInfo.lcClaimed = true;
                }
            }
        }

		if (lcAmount > 0){
			lcToken.safeTransfer(user, lcAmount);
		}
        emit ClaimBonusLC(user, lcAmount);
    }

    // View pending lc back
    function pendingLcBack(address user) external view returns (uint256) {
		uint256 lcAmount = 0;
        uint256 epoch;
        uint256 roundLcAmount = 0;
        for (uint256 i = userRounds[user].length - 1; i >= 0; i --){
            epoch = userRounds[user][i];
            BetInfo storage betInfo = ledger[epoch][msg.sender];
            if (betInfo.lcClaimed){
                break;
            }else{
                Round storage round = rounds[epoch];
                if (round.status == Status.Claimable){
                    if (betInfo.numbers[round.finalNumber]){
                        roundLcAmount = betInfo.amount.div(uint256(betInfo.numberCount)).mul(5).mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE);
                        if (betInfo.numberCount > 1){
                            roundLcAmount = roundLcAmount.add(betInfo.amount.div(uint256(betInfo.numberCount)).mul(uint256(betInfo.numberCount - 1)).mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE));
                        }
                    }else{
                        roundLcAmount = betInfo.amount.mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE);
                    }

                    roundLcAmount = roundLcAmount.mul(round.swapLcAmount).div(round.lcBackAmount);
                    lcAmount = lcAmount.add(roundLcAmount);
                }
            }
        }

        return lcAmount;    
    }

    // Claim all bonus to masterChef
    function _claimBonus() internal {
		if( totalBonusAmount > 0){
			uint256 tmpBonusAmount = totalBonusAmount;
	        totalBonusAmount = 0;
			token.safeTransfer(masterChefAddress, tmpBonusAmount);
			IMasterChef(masterChefAddress).updateBonus(masterChefBonusId);
	        emit ClaimBonus(tmpBonusAmount);
		}
    }

    // Return round epochs that a user has participated
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor.add(i)];
        }

        return (values, cursor.add(length));
    }

    // Get the claimable stats of specific epoch and user account
    function claimable(uint256 epoch, address user) public view returns (bool) {
        return (rounds[epoch].status == Status.Claimable) && (ledger[epoch][user].numbers[rounds[epoch].finalNumber]);
    }

    // Get the refundable stats of specific epoch and user account
    function refundable(uint256 epoch, address user) public view returns (bool) {
        return (rounds[epoch].status != Status.Claimable) && block.number > rounds[epoch].lockBlock.add(intervalBlocks) && ledger[epoch][user].amount != 0;
    }

    // Manual Start round. Previous round n-1 must lock
    function manualStartRound(bytes32 bankHash) external onlyAdmin whenNotPaused {
        require(block.number >= rounds[currentEpoch].lockBlock, "Manual start new round after current round lock");
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch, bankHash);
    }

    function _startRound(uint256 epoch, bytes32 bankHash) internal {
        Round storage round = rounds[epoch];
        round.startBlock = block.number;
        round.lockBlock = block.number.add(intervalBlocks);
        round.bankHash = bankHash;
        round.totalAmount = 0;
		round.maxBetAmount = bankerAmount.mul(maxBetRatio).div(TOTAL_RATE);
        round.status = Status.Open;

        emit StartRound(epoch, block.number, bankHash);
    }

    // Lock round
    function lockRound(uint256 epoch) public whenNotPaused {
        Round storage round = rounds[epoch];
        require(round.startBlock != 0, "Lock round after round has started");
        require(block.number >= round.lockBlock, "Lock round after lockBlock");
        require(block.number <= round.lockBlock.add(intervalBlocks), "Lock round within intervalBlocks");
        round.status = Status.Lock;
        emit LockRound(epoch, block.number);
    }

    // Calculate rewards for round
    function _calculateRewards(uint256 epoch) internal {
        require(lcBackRate.add(bonusRate) <= TOTAL_RATE, "lcBackRate + bonusRate <= TOTAL_RATE");
        require(rounds[epoch].bonusAmount == 0, "Rewards calculated");
        Round storage round = rounds[epoch];

        uint256 lcBackAmount = 0;
        uint256 bonusAmount = 0;
        for (uint32 i = 0; i < 6; i ++){
            if (i == round.finalNumber){
                uint256 tmpLcBackAmount = round.betAmounts[i].mul(5).mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE);
                lcBackAmount = lcBackAmount.add(tmpLcBackAmount);
                uint256 tmpBonusAmount = round.betAmounts[i].mul(5).mul(gapRate).div(TOTAL_RATE).mul(bonusRate).div(TOTAL_RATE);
                bonusAmount = bonusAmount.add(tmpBonusAmount);
                uint256 playerWinAmount = round.betAmounts[i].mul(5).mul(TOTAL_RATE.sub(gapRate)).div(TOTAL_RATE);
                bankerAmount = bankerAmount.sub(playerWinAmount).sub(tmpLcBackAmount).sub(tmpBonusAmount);
            }else{
                uint256 tmpLcBackAmount = round.betAmounts[i].mul(gapRate).div(TOTAL_RATE).mul(lcBackRate).div(TOTAL_RATE);
                lcBackAmount = lcBackAmount.add(tmpLcBackAmount);
                uint256 tmpBonusAmount = round.betAmounts[i].mul(gapRate).div(TOTAL_RATE).mul(bonusRate).div(TOTAL_RATE);
                bonusAmount = bonusAmount.add(tmpBonusAmount);
                uint256 playerLostAmount = round.betAmounts[i];
                bankerAmount = bankerAmount.add(playerLostAmount).sub(tmpLcBackAmount).sub(tmpBonusAmount);
            }    
        }

        round.lcBackAmount = lcBackAmount;
        round.bonusAmount = bonusAmount;

		if(address(token) == address(lcToken)){
			round.swapLcAmount = lcBackAmount;
		}else if(address(swapRouter) != address(0)){
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = address(lcToken);
            uint256 lcAmout = swapRouter.swapExactTokensForTokens(round.lcBackAmount, 0, path, address(this), block.timestamp + (5 minutes))[1];
            round.swapLcAmount = lcAmout;
        }
        totalBonusAmount = totalBonusAmount.add(bonusAmount);

        emit RewardsCalculated(epoch, round.lcBackAmount, round.bonusAmount, round.swapLcAmount);
    }

    // Deposit token to Dice as a banker, get Syrup back.
    function deposit(uint256 _tokenAmount) public whenPaused nonReentrant notContract {
        require(_tokenAmount > 0, "Deposit amount > 0");
        require(bankerAmount.add(_tokenAmount) < maxBankerAmount, 'maxBankerAmount Limit');
        BankerInfo storage banker = bankerInfo[msg.sender];
        token.safeTransferFrom(address(msg.sender), address(this), _tokenAmount);
        uint256 diceTokenAmount = _tokenAmount.mul(1e12).div(netValue);
        diceToken.mint(address(msg.sender), diceTokenAmount);
        uint256 totalDiceTokenAmount = banker.diceTokenAmount.add(diceTokenAmount);
        banker.avgBuyValue = banker.avgBuyValue.mul(banker.diceTokenAmount).div(1e12).add(_tokenAmount).mul(1e12).div(totalDiceTokenAmount);
        banker.diceTokenAmount = totalDiceTokenAmount;
        bankerAmount = bankerAmount.add(_tokenAmount);
        emit Deposit(msg.sender, _tokenAmount);    
    }

    // Withdraw syrup from dice to get token back
    function withdraw(uint256 _diceTokenAmount) public whenPaused nonReentrant notContract {
        require(_diceTokenAmount > 0, "diceTokenAmount > 0");
        BankerInfo storage banker = bankerInfo[msg.sender];
        banker.diceTokenAmount = banker.diceTokenAmount.sub(_diceTokenAmount); 
        SafeBEP20.safeTransferFrom(diceToken, msg.sender, address(diceToken), _diceTokenAmount);
        diceToken.burn(address(diceToken), _diceTokenAmount);
        uint256 tokenAmount = _diceTokenAmount.mul(netValue).div(1e12);
        bankerAmount = bankerAmount.sub(tokenAmount);
        token.safeTransfer(address(msg.sender), tokenAmount);

        emit Withdraw(msg.sender, _diceTokenAmount);
    }

    // View function to see banker diceToken Value on frontend.
    function canWithdrawToken(address bankerAddress) external view returns (uint256){
        return bankerInfo[bankerAddress].diceTokenAmount.mul(netValue).div(1e12);    
    }

    // View function to see banker diceToken Value on frontend.
    function calProfitRate(address bankerAddress) external view returns (uint256){
        return netValue.mul(100).div(bankerInfo[bankerAddress].avgBuyValue);    
    }

    // Judge address is contract or not
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // Update the swap router.
    function updateSwapRouter(address _router) external onlyAdmin {
        require(_router != address(0), "DICE: Invalid router address.");
        swapRouter = ILuckyChipRouter02(_router);
        emit SwapRouterUpdated(address(swapRouter));
    }

	function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}