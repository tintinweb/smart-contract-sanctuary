/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity 0.6.6;

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

    constructor() public {
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    // function mint(address account, uint256 amount) external returns (bool);
    // function burn(address, uint256) external returns (bool);
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

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
    constructor() internal {
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

contract BscVault is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256; //using math opertions
    using SafeERC20 for IERC20; //erc20 functions

    uint256 public constant MIN_AMOUNT = 1e16; //minimum amount
    uint256 public swapCommission; //Commision swap
    address public rootToken; //rootToken
    address public  commissionReceiver; //Commision receiver
    address payable public commissionReceiverForNative;
    

    struct MinterEntity {
        address minter;
        address token;
        bool active;
        uint256 depositCount;
    }

    struct EventStr {
        uint256 depositCount;
        uint256 chainID;
        address from;
        address to;
        uint256 amount;
        bool isCompleted;
    }

    mapping(uint256 => MinterEntity) public registeredChains; // chainID => MinterEntity
    mapping(bytes32 => EventStr) public eventStore; //event store

    event SwapStart(
        bytes32 indexed eventHash,
        uint256 depositCount,
        uint256 indexed toChainID,
        address indexed fromAddr,
        address toAddr,
        uint256 amount
    );
    event SwapStartForNative(
        bytes32 indexed eventHash,
        uint256 depositCount,
        uint256 indexed toChainID,
        address indexed fromAddr,
        address toAddr,
        uint256 amount
    );
    event SwapEnd(
        bytes32 indexed eventHash,
        uint256 depositCount,
        uint256 indexed fromChainID,
        address indexed fromAddr,
        address toAddr,
        uint256 amount
    );

    //emit when started swap from current chain was ended in target chain
    event SwapCompleted(
        bytes32 indexed eventHash,
        uint256 depositCount,
        address fromAddr,
        address toAddr,
        uint256 amount
    );

    modifier onlyActivatedChains(uint256 chainID) {
        //BVG09 fixed
        require(
            chainID != _getChainID(),
            "Swap must be created to different chain ID"
        );
        require(
            registeredChains[chainID].active == true,
            "Only activated chains"
        );
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    constructor(address _rootToken) public {
        rootToken = _rootToken; //Token to exchange
        commissionReceiver = msg.sender; //Owner
    }

    function setCommission(uint256 _swapCommission, address _commissionReceiver)
        external
        onlyOwner
    {
        require(_swapCommission < 10000, "swapCommission must be lt 10000");
        require(_commissionReceiver != address(0));
        swapCommission = _swapCommission;
        commissionReceiver = _commissionReceiver;
    }

    function addNewChain(
        uint256 chainID,
        address minter,
        address token
    ) public onlyOwner returns (bool) {
        //BVG11 fixed
        require(chainID != _getChainID(), "Can`t add current chain ID"); //current chainid of the cotract execution network
        require(minter != address(0), "Minter address must not be 0x0"); //who is the minter
        require(
            registeredChains[chainID].minter == address(0),
            "ChainID has already been registered"
        ); //if it equals to address 0 then it is not registered
        MinterEntity memory minterEntity = MinterEntity({
            minter: minter, //minter
            token: token, //token to mint
            active: true, //yes
            depositCount: 0
        });
        registeredChains[chainID] = minterEntity; //now assighn the registered chains for the minter
        return true;
    }

    function changeActivationChain(uint256 chainID, bool activate)
        public
        onlyOwner
    {
        require(
            chainID != _getChainID(),
            "Can`t change activation to current Chain ID"
        );
        require(
            registeredChains[chainID].minter != address(0),
            "Chain is not registered"
        ); //should be registered
        registeredChains[chainID].active = activate; //activate
    }

    function swapStartForNative(uint256 toChainID, address to)
        public
        payable
        onlyActivatedChains(toChainID)
        whenNotPaused
        notContract
        nonReentrant
    {
        require(msg.value >= MIN_AMOUNT && to != address(0)); //it should be greater than the minimum amount
        // require(
        //     IERC20(rootToken).allowance(msg.sender, address(this)) >= amount,
        //     "not enough allowance"
        // ); //msg.sender needs to approve the contract to spend the amount
        // _depositToken(amount); //tranfer tokens from the msg.sender account to this
        uint256 amount = msg.value;
        uint256 commission;
        if (swapCommission > 0 && msg.sender != commissionReceiver) {
            commission = _commissionCalculate(amount); //take out the commision amount
            amount = amount.sub(commission);
            _withdrawCommissionForNative(commission); //transfer the commision amount to the commision receiver
        }
        //BVG02 fixed
        registeredChains[toChainID].depositCount = registeredChains[toChainID]
            .depositCount
            .add(1); //how many members are deposited on this chain
        uint256 _depositCount = registeredChains[toChainID].depositCount; //store the deposit count
        uint256 _chainID = _getChainID(); //get the chain id
        EventStr memory eventStr = EventStr({
            depositCount: _depositCount,
            chainID: _chainID,
            from: msg.sender,
            to: to,
            amount: amount,
            isCompleted: false
        }); //
        //BVG07 fixed
        bytes32 eventHash = keccak256(
            abi.encode(
                _depositCount,
                _chainID,
                toChainID,
                msg.sender,
                to,
                amount
            )
        ); //encode and convert it to the hash
        require(
            eventStore[eventHash].depositCount == 0,
            "It's available just 1 swap with same: chainID, depositCount, from, to, amount"
        ); //a single change can change the hash so the same chainids does not have the same deposit count
        eventStore[eventHash] = eventStr; //store in the event str
        emit SwapStartForNative(
            eventHash,
            _depositCount,
            toChainID,
            msg.sender,
            to,
            amount
        ); //emit the event
    }

    //BVG08 fixed
    function swapStart(
        uint256 toChainID,
        address to,
        uint256 amount
    )
        public
        onlyActivatedChains(toChainID)
        whenNotPaused
        notContract
        nonReentrant
    {
        require(amount >= MIN_AMOUNT && to != address(0)); //it should be greater than the minimum amount
        require(
            IERC20(rootToken).allowance(msg.sender, address(this)) >= amount,
            "not enough allowance"
        ); //msg.sender needs to approve the contract to spend the amount
        _depositToken(amount); //tranfer tokens from the msg.sender account to this
        uint256 commission;
        if (swapCommission > 0 && msg.sender != commissionReceiver) {
            commission = _commissionCalculate(amount); //take out the commision amount
            amount = amount.sub(commission);
            _withdrawCommission(commission); //transfer the commision amount to the commision receiver
        }
        //BVG02 fixed
        registeredChains[toChainID].depositCount = registeredChains[toChainID]
            .depositCount
            .add(1); //how many members are deposited on this chain
        uint256 _depositCount = registeredChains[toChainID].depositCount; //store the deposit count
        uint256 _chainID = _getChainID(); //get the chain id
        EventStr memory eventStr = EventStr({
            depositCount: _depositCount,
            chainID: _chainID,
            from: msg.sender,
            to: to,
            amount: amount,
            isCompleted: false
        }); //
        //BVG07 fixed
        bytes32 eventHash = keccak256(
            abi.encode(
                _depositCount,
                _chainID,
                toChainID,
                msg.sender,
                to,
                amount
            )
        ); //encode and convert it to the hash
        require(
            eventStore[eventHash].depositCount == 0,
            "It's available just 1 swap with same: chainID, depositCount, from, to, amount"
        ); //a single change can change the hash so the same chainids does not have the same deposit count
        eventStore[eventHash] = eventStr; //store in the event str
        emit SwapStart(
            eventHash,
            _depositCount,
            toChainID,
            msg.sender,
            to,
            amount
        ); //emit the event
    }

    //BVG10 fixed
    function swapEnd(
        bytes32 eventHash,
        uint256 depositCount,
        uint256 fromChainID,
        address from,
        address to,
        uint256 amount
    ) public onlyOwner onlyActivatedChains(fromChainID) whenNotPaused {
        require(amount > 0 && to != address(0));
        require(
            amount <= IERC20(rootToken).balanceOf(address(this)),
            "not enough balance"
        );
        require(
            fromChainID != _getChainID(),
            "Swap only work between different chains"
        );
        uint256 _chainID = _getChainID();
        //BVG07 fixed
        bytes32 receivedHash = keccak256(
            abi.encode(depositCount, fromChainID, _chainID, from, to, amount)
        );
        require(receivedHash == eventHash, "Wrong args received");
        require(
            eventStore[receivedHash].isCompleted == false,
            "Swap was ended before!"
        ); //it will be completed after the minting is completed
        EventStr memory eventStr = EventStr({
            depositCount: depositCount,
            chainID: fromChainID,
            from: from,
            to: to,
            amount: amount,
            isCompleted: true
        });
        eventStore[receivedHash] = eventStr;

        if (swapCommission > 0 && to != commissionReceiver) {
            uint256 commission = _commissionCalculate(amount); //take the commision amount
            amount = amount.sub(commission);
            _withdrawCommission(commission);
        }
        _transferToken(to, amount);
        emit SwapEnd(receivedHash, depositCount, fromChainID, from, to, amount);
    }

    function setSwapComplete(bytes32 eventHash) external onlyOwner {
        require(
            eventStore[eventHash].depositCount != 0,
            "Event hash not found"
        );
        require(
            eventStore[eventHash].chainID == _getChainID(),
            "swap from another chain can be completed from swapEnd()"
        );
        eventStore[eventHash].isCompleted = true;
        address fromAddr = eventStore[eventHash].from;
        address toAddr = eventStore[eventHash].to;
        uint256 amount = eventStore[eventHash].amount;
        uint256 depositCount = eventStore[eventHash].depositCount;
        emit SwapCompleted(eventHash, depositCount, fromAddr, toAddr, amount);
    }

    //BVG04 fixed
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function _transferToken(address to, uint256 amount) private {
        IERC20(rootToken).safeTransfer(to, amount);
    }

    function _depositToken(uint256 amount) private {
        IERC20(rootToken).safeTransferFrom(msg.sender, address(this), amount); //transfer the amount from the msg.sender to the this contract
    }

    function _commissionCalculate(uint256 amount)
        internal
        view
        returns (uint256 fee)
    {
        fee = commissionReceiver != address(0)
            ? amount.mul(swapCommission).div(10000)
            : 0;
    }

    function _withdrawCommission(uint256 commission) internal {
        if (commission > 0 && commissionReceiver != address(0)) {
            _transferToken(commissionReceiver, commission);
        }
    }

    function _withdrawCommissionForNative(uint256 commission) internal {
        if (commission > 0 && commissionReceiver != address(0)) {
            commissionReceiverForNative.transfer(commission);
        }
    }

    //BVG03 fixed
    function _getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid() //chainid of current executing network
        }
        return id;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    function setRootToken(address _tokenAddr)public onlyOwner returns(bool){
        require(_tokenAddr != address(0),"Token address should not be zero");
        rootToken = _tokenAddr;
    }
}