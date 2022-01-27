/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

pragma solidity ^0.8.0;

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

    constructor() {
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

// File: @pancakeswap\pancake-swap-lib\contracts\math\SafeMath.sol

pragma solidity >=0.4.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.8.0;

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
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

// File: contracts/interfaces/IRandomNumberGenerator.sol

pragma solidity ^0.8.4;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint256);
}

pragma solidity ^0.8.4;

interface IRafflePool {
    /**
     * View user info in the pool
     */
    function userInfo(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function pendingReward(address _user) external view returns (uint256);

    /**
     * Stake token into the pool
     */
    function deposit(uint256 amount) external;

    /**
     * Withdraw from the pool
     */
    function withdraw(uint256 amount) external;
}

// File: contracts/interfaces/ICliffRaffle.sol

pragma solidity ^0.8.4;

interface ICliffRaffle {
    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketCount: count of ticket to buy
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256 _ticketCount) external;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(uint256 _lotteryId, uint256[] calldata _ticketIds)
        external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external;

    /**
     * @notice Draw the final number, calculate reward in CLIFF per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId,
        bool _autoInjection
    ) external;

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in CLIFF token
     * @dev Callable by operator
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount) external;

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInCliff: price of a ticket in CLIFF
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per winner including treasury fee (must sum to 10,000)
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInCliff,
        uint256 _discountDivisor,
        uint256[4] calldata _rewardsBreakdown
    ) external;

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);
}

// File: contracts/CliffRaffle.sol

pragma solidity ^0.8.4;
pragma abicoder v2;

/** @title Cliff Raffle.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract CliffRaffle is ReentrancyGuard, ICliffRaffle, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public injectorAddress;
    address public operatorAddress;
    address public treasuryAddress;

    uint256 public currentLotteryId;
    uint256 public currentTicketId;

    uint256 public maxNumberTicketsPerBuyOrClaim = 100;

    uint256 public maxPriceTicketInCliff = 50 ether;
    uint256 public minPriceTicketInCliff = 0.005 ether;

    uint256 public pendingInjectionNextLottery;

    uint256 public constant MIN_DISCOUNT_DIVISOR = 300;
    uint256 public constant MIN_LENGTH_LOTTERY = 5 minutes; // 2 hours
    uint256 public constant MAX_LENGTH_LOTTERY = 4 days + 5 minutes; // 4 days
    uint256 public constant MAX_TREASURY_FEE = 5000; // 50%

    IERC20 public cliffToken;
    IRandomNumberGenerator public randomGenerator;
    IRafflePool public rafflePool;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInCliff;
        uint256 discountDivisor;
        uint256[4] rewardsBreakdown;
        uint256[3] winTicketIds;
        uint8 winnerCount;
        uint256 firstTicketId;
        uint256 firstTicketIdNextLottery;
        uint256 amountCollectedInCliff;
        uint256 finalNumber;
    }

    struct Ticket {
        uint256 ticketId;
        address owner;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;

    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[]))
        private _userTicketIdsPerLotteryId;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier onlyOwnerOrInjector() {
        require(
            (msg.sender == owner()) || (msg.sender == injectorAddress),
            "Not owner or injector"
        );
        _;
    }

    event AdminTokenRecovery(address token, uint256 amount);
    event LotteryClose(
        uint256 indexed lotteryId,
        uint256 firstTicketIdNextLottery
    );
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInCliff,
        uint256 firstTicketId,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(
        uint256 indexed lotteryId,
        uint256 finalNumber,
        uint8 winnerCount,
        uint256 winTicketId1,
        uint256 winTicketId2,
        uint256 winTicketId3
    );
    event NewOperatorAndTreasuryAndInjectorAddresses(
        address operator,
        address treasury,
        address injector
    );
    event NewRandomGenerator(address indexed randomGenerator);
    event NewRafflePool(address indexed rafflePool);
    event TicketsPurchase(
        address indexed buyer,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );
    event TicketsClaim(
        address indexed claimer,
        uint256 amount,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _cliffTokenAddress: address of the CLIFF token
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     * @param _rafflePoolAddress: address of the raffle pool contract used to stake paid tokens
     */
    constructor(
        address _cliffTokenAddress,
        address _randomGeneratorAddress,
        address _rafflePoolAddress
    ) {
        cliffToken = IERC20(_cliffTokenAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        rafflePool = IRafflePool(_rafflePoolAddress);
    }

    /**
     * @notice Stake tokens to the raffle pool
     * @param amount: amount of tokens
     * @return harvested rewards amount
     */
    function stakeToRafflePool(uint256 amount) internal returns (uint256) {
        if (address(rafflePool) != address(0)) {
            uint256 balanceBefore = cliffToken.balanceOf(address(this));
            rafflePool.deposit(amount);
            amount = cliffToken.balanceOf(address(this)).sub(balanceBefore);
        }
        return amount;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketCount: count of ticket to buy
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256 _ticketCount)
        external
        override
        notContract
        nonReentrant
    {
        require(_ticketCount != 0, "No ticket specified");
        require(
            _ticketCount <= maxNumberTicketsPerBuyOrClaim,
            "Too many tickets"
        );

        require(
            _lotteries[_lotteryId].status == Status.Open,
            "Lottery is not open"
        );
        require(
            block.timestamp < _lotteries[_lotteryId].endTime,
            "Lottery is over"
        );

        // Calculate number of CLIFF to this contract
        uint256 amountCliffToTransfer = _calculateTotalPriceForBulkTickets(
            _lotteries[_lotteryId].discountDivisor,
            _lotteries[_lotteryId].priceTicketInCliff,
            _ticketCount
        );

        // Transfer CLIFF tokens to this contract from user account
        uint256 balanceBefore = cliffToken.balanceOf(address(this));
        cliffToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amountCliffToTransfer
        );
        amountCliffToTransfer = cliffToken.balanceOf(address(this)).sub(
            balanceBefore
        );

        // Stake CLIFF tokens to raffle pool
        // There would be reward harvested from the raffle pool at this time, so
        // add it to the round
        amountCliffToTransfer = stakeToRafflePool(amountCliffToTransfer);

        // Increment the total amount collected for the lottery round
        _lotteries[_lotteryId].amountCollectedInCliff = _lotteries[_lotteryId]
            .amountCollectedInCliff
            .add(amountCliffToTransfer);

        for (uint256 i = 0; i < _ticketCount; i++) {
            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(
                currentTicketId
            );

            _tickets[currentTicketId] = Ticket({
                ticketId: currentTicketId,
                owner: msg.sender
            });

            // Increase lottery ticket number
            currentTicketId++;
        }

        emit TicketsPurchase(msg.sender, _lotteryId, _ticketCount);
    }

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(uint256 _lotteryId, uint256[] calldata _ticketIds)
        external
        override
        notContract
        nonReentrant
    {
        require(_ticketIds.length != 0, "Length must be >0");
        require(
            _ticketIds.length <= maxNumberTicketsPerBuyOrClaim,
            "Too many tickets"
        );
        require(
            _lotteries[_lotteryId].status == Status.Claimable,
            "Lottery not claimable"
        );

        // Initializes the rewardInCliffToTransfer
        uint256 rewardInCliffToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            uint256 thisTicketId = _ticketIds[i];

            require(
                _lotteries[_lotteryId].firstTicketIdNextLottery > thisTicketId,
                "TicketId too high"
            );
            require(
                _lotteries[_lotteryId].firstTicketId <= thisTicketId,
                "TicketId too low"
            );
            require(
                msg.sender == _tickets[thisTicketId].owner,
                "Not the owner"
            );

            // Update the lottery ticket owner to 0x address
            _tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId = _calculateRewardsForTicketId(
                _lotteryId,
                thisTicketId
            );

            // Increment the reward to transfer
            rewardInCliffToTransfer = rewardInCliffToTransfer.add(
                rewardForTicketId
            );
        }

        // Transfer money to msg.sender
        cliffToken.safeTransfer(msg.sender, rewardInCliffToTransfer);

        emit TicketsClaim(
            msg.sender,
            rewardInCliffToTransfer,
            _lotteryId,
            _ticketIds.length
        );
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId)
        external
        override
        onlyOperator
        nonReentrant
    {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "Lottery not open"
        );
        require(
            block.timestamp > _lotteries[_lotteryId].endTime,
            "Lottery not over"
        );
        _lotteries[_lotteryId].firstTicketIdNextLottery = currentTicketId;

        // Request a random number from the generator based on a seed
        randomGenerator.getRandomNumber(
            uint256(keccak256(abi.encodePacked(_lotteryId, currentTicketId)))
        );

        _lotteries[_lotteryId].status = Status.Close;

        emit LotteryClose(_lotteryId, currentTicketId);
    }

    /**
     * @notice Get win ticket ids and winner count
     * @dev This function should be called only when drawing final number
     * @param _lotteryId: lottery id
     * @param _randomNumber: Random number generated from chain link
     */
    function determineWinTicketIdsAndCount(
        uint256 _lotteryId,
        uint256 _randomNumber
    )
        internal
        view
        returns (
            uint8 winnerCount,
            uint256 winTicketId1,
            uint256 winTicketId2,
            uint256 winTicketId3
        )
    {
        // How many tickets are there in this lottery?
        uint256 ticketCount;
        if (_lotteryId == 0) {
            ticketCount = currentTicketId;
        } else {
            ticketCount = _lotteries[_lotteryId].firstTicketIdNextLottery.sub(
                _lotteries[_lotteryId.sub(1)].firstTicketIdNextLottery
            );
        }

        if (ticketCount >= 3) {
            uint256 step = _randomNumber % (ticketCount.sub(1));
            if (step == 0) {
                step = 1;
            }
            uint256 firstWinIndex = _randomNumber % ticketCount;
            uint256 secondWinIndex = (firstWinIndex.add(step)) % ticketCount;
            if (secondWinIndex == firstWinIndex) {
                secondWinIndex = firstWinIndex.add(1) % ticketCount;
            }
            uint256 thirdWinIndex = (secondWinIndex.add(step)) % ticketCount;
            if (thirdWinIndex == firstWinIndex) {
                thirdWinIndex = firstWinIndex.add(1) % ticketCount;
            }
            if (thirdWinIndex == secondWinIndex) {
                thirdWinIndex = secondWinIndex.add(1) % ticketCount;
            }
            if (thirdWinIndex == firstWinIndex) {
                thirdWinIndex = firstWinIndex.add(1) % ticketCount;
            }
            winnerCount = 3;
            winTicketId1 = _lotteries[_lotteryId].firstTicketId.add(
                firstWinIndex
            );
            winTicketId2 = _lotteries[_lotteryId].firstTicketId.add(
                secondWinIndex
            );
            winTicketId3 = _lotteries[_lotteryId].firstTicketId.add(
                thirdWinIndex
            );
        } else if (ticketCount == 2) {
            uint256 firstWinIndex = _randomNumber % 2;
            uint256 secondWinIndex = firstWinIndex == 0 ? 1 : 0;
            winnerCount = 2;
            winTicketId1 = _lotteries[_lotteryId].firstTicketId.add(
                firstWinIndex
            );
            winTicketId2 = _lotteries[_lotteryId].firstTicketId.add(
                secondWinIndex
            );
        } else if (ticketCount == 1) {
            uint256 firstWinIndex = 1;
            winnerCount = 1;
            winTicketId1 = _lotteries[_lotteryId].firstTicketId.add(
                firstWinIndex
            );
        }
    }

    /**
     * @notice Process treasury fee and the pending funds
     * @dev This function should be called only when drawing final number
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @param _winnerCount: winner count in the lottery
     */
    function processTreasuryFeeAndPendingFunds(
        uint256 _lotteryId,
        bool _autoInjection,
        uint8 _winnerCount
    ) internal {
        // Initializes the amount to withdraw to treasury and share to winners
        // Just duplicate functions to avoid remaining tokens in the contract
        uint256 amountToWithdrawToTreasury;

        if (_winnerCount == 2) {
            // Third rewards breakdown will be sent to treasury or auto-injected
            amountToWithdrawToTreasury = _lotteries[_lotteryId]
                .amountCollectedInCliff
                .mul(_lotteries[_lotteryId].rewardsBreakdown[2])
                .div(10000);
        } else if (_winnerCount == 1) {
            // Second & third rewards breakdown will be sent to treasury or auto-injected
            amountToWithdrawToTreasury = _lotteries[_lotteryId]
                .amountCollectedInCliff
                .mul(
                    _lotteries[_lotteryId].rewardsBreakdown[1].add(
                        _lotteries[_lotteryId].rewardsBreakdown[2]
                    )
                )
                .div(10000);
        }

        if (_autoInjection) {
            pendingInjectionNextLottery = amountToWithdrawToTreasury;
            amountToWithdrawToTreasury = 0;
        }

        amountToWithdrawToTreasury = amountToWithdrawToTreasury.add(
            _lotteries[_lotteryId]
                .amountCollectedInCliff
                .mul(_lotteries[_lotteryId].rewardsBreakdown[3])
                .div(10000)
        );

        // Transfer CLIFF to treasury address
        if (amountToWithdrawToTreasury > 0) {
            cliffToken.safeTransfer(
                treasuryAddress,
                amountToWithdrawToTreasury
            );
        }
    }

    /**
     * @notice Draw the final number, calculate reward in CLIFF per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId,
        bool _autoInjection
    ) external override onlyOperator nonReentrant {
        require(
            _lotteries[_lotteryId].status == Status.Close,
            "Lottery not close"
        );
        require(
            _lotteryId == randomGenerator.viewLatestLotteryId(),
            "Numbers not drawn"
        );

        // Withdraw from the raffle pool
        if (address(rafflePool) != address(0)) {
            uint256 balanceBefore = cliffToken.balanceOf(address(this));
            (uint256 amount, , ) = rafflePool.userInfo(address(this));
            rafflePool.withdraw(amount);
            uint256 withdrawnAmount = cliffToken.balanceOf(address(this)).sub(
                balanceBefore
            );
            _lotteries[_lotteryId].amountCollectedInCliff = _lotteries[
                _lotteryId
            ].amountCollectedInCliff.add(withdrawnAmount);
        }

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        uint256 finalNumber = randomGenerator.viewRandomResult();
        (
            uint8 winnerCount,
            uint256 winTicketId1,
            uint256 winTicketId2,
            uint256 winTicketId3
        ) = determineWinTicketIdsAndCount(_lotteryId, finalNumber);

        processTreasuryFeeAndPendingFunds(
            _lotteryId,
            _autoInjection,
            winnerCount
        );

        // Update internal statuses for lottery
        _lotteries[_lotteryId].winnerCount = winnerCount;
        _lotteries[_lotteryId].winTicketIds[0] = winTicketId1;
        _lotteries[_lotteryId].winTicketIds[1] = winTicketId2;
        _lotteries[_lotteryId].winTicketIds[2] = winTicketId3;
        _lotteries[_lotteryId].finalNumber = finalNumber;
        _lotteries[_lotteryId].status = Status.Claimable;

        emit LotteryNumberDrawn(
            currentLotteryId,
            finalNumber,
            winnerCount,
            winTicketId1,
            winTicketId2,
            winTicketId3
        );
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress)
        external
        onlyOwner
    {
        require(
            _lotteries[currentLotteryId].status == Status.Claimable,
            "Lottery not in claimable"
        );

        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber(
            uint256(
                keccak256(abi.encodePacked(currentLotteryId, currentTicketId))
            )
        );

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to change raffle pool
     * Callable only by the contract owner
     * @param _rafflePoolAddress: address of the raffle pool
     */
    function changeRafflePool(address _rafflePoolAddress) external onlyOwner {
        require(
            _lotteries[currentLotteryId].status == Status.Claimable,
            "Lottery not in claimable"
        );

        rafflePool = IRafflePool(_rafflePoolAddress);

        emit NewRafflePool(_rafflePoolAddress);
    }

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in CLIFF token
     * @dev Callable by owner or injector address
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount)
        external
        override
        onlyOwnerOrInjector
    {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "Lottery not open"
        );

        uint256 balanceBefore = cliffToken.balanceOf(address(this));
        cliffToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _amount = cliffToken.balanceOf(address(this)).sub(balanceBefore);

        emit LotteryInjection(_lotteryId, _amount);

        // Stake injected funds to the raffle pool, and
        // add harvested rewards to the round
        _amount = stakeToRafflePool(_amount);

        _lotteries[_lotteryId].amountCollectedInCliff = _lotteries[_lotteryId]
            .amountCollectedInCliff
            .add(_amount);
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInCliff: price of a ticket in CLIFF
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per bracket including treasury fee (must sum to 10,000)
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInCliff,
        uint256 _discountDivisor,
        uint256[4] calldata _rewardsBreakdown
    ) external override onlyOperator {
        require(
            (currentLotteryId == 0) ||
                (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );

        require(
            ((_endTime - block.timestamp) > MIN_LENGTH_LOTTERY) &&
                ((_endTime - block.timestamp) < MAX_LENGTH_LOTTERY),
            "Lottery length outside of range"
        );

        require(
            (_priceTicketInCliff >= minPriceTicketInCliff) &&
                (_priceTicketInCliff <= maxPriceTicketInCliff),
            "Outside of limits"
        );

        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "Discount divisor too low"
        );
        require(
            _rewardsBreakdown[3] <= MAX_TREASURY_FEE,
            "Treasury fee too high"
        );

        require(
            (_rewardsBreakdown[0] +
                _rewardsBreakdown[1] +
                _rewardsBreakdown[2] +
                _rewardsBreakdown[3]) == 10000,
            "Rewards must equal 10000"
        );

        currentLotteryId++;

        // Stake pending injection tokens to the raffle pool
        pendingInjectionNextLottery = stakeToRafflePool(
            pendingInjectionNextLottery
        );

        _lotteries[currentLotteryId] = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: _endTime,
            priceTicketInCliff: _priceTicketInCliff,
            discountDivisor: _discountDivisor,
            rewardsBreakdown: _rewardsBreakdown,
            winTicketIds: [uint256(0), uint256(0), uint256(0)],
            winnerCount: 0,
            firstTicketId: currentTicketId,
            firstTicketIdNextLottery: currentTicketId,
            amountCollectedInCliff: pendingInjectionNextLottery,
            finalNumber: 0
        });

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _endTime,
            _priceTicketInCliff,
            currentTicketId,
            pendingInjectionNextLottery
        );

        pendingInjectionNextLottery = 0;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAddress != address(cliffToken), "Cannot be CLIFF token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Set CLIFF price ticket upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicketInCliff: minimum price of a ticket in CLIFF
     * @param _maxPriceTicketInCliff: maximum price of a ticket in CLIFF
     */
    function setMinAndMaxTicketPriceInCliff(
        uint256 _minPriceTicketInCliff,
        uint256 _maxPriceTicketInCliff
    ) external onlyOwner {
        require(
            _minPriceTicketInCliff <= _maxPriceTicketInCliff,
            "minPrice must be < maxPrice"
        );

        minPriceTicketInCliff = _minPriceTicketInCliff;
        maxPriceTicketInCliff = _maxPriceTicketInCliff;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy)
        external
        onlyOwner
    {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Set operator, treasury, and injector addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _treasuryAddress: address of the treasury
     * @param _injectorAddress: address of the injector
     */
    function setOperatorAndTreasuryAndInjectorAddresses(
        address _operatorAddress,
        address _treasuryAddress,
        address _injectorAddress
    ) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        require(_treasuryAddress != address(0), "Cannot be zero address");
        require(_injectorAddress != address(0), "Cannot be zero address");

        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;
        injectorAddress = _injectorAddress;

        emit NewOperatorAndTreasuryAndInjectorAddresses(
            _operatorAddress,
            _treasuryAddress,
            _injectorAddress
        );
    }

    /**
     * @notice Calculate price of a set of tickets
     * @param _discountDivisor: divisor for the discount
     * @param _priceTicket price of a ticket (in CLIFF)
     * @param _numberTickets number of tickets to buy
     */
    function calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) external pure returns (uint256) {
        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "Must be >= MIN_DISCOUNT_DIVISOR"
        );
        require(_numberTickets != 0, "Number of tickets must be > 0");

        return
            _calculateTotalPriceForBulkTickets(
                _discountDivisor,
                _priceTicket,
                _numberTickets
            );
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view override returns (uint256) {
        return currentLotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     * @return Lottery info
     * @return staked amount in raffle pool
     * @return reward amount pending in raffle pool
     */
    function viewLottery(uint256 _lotteryId)
        external
        view
        returns (
            Lottery memory,
            uint256,
            uint256
        )
    {
        if (address(rafflePool) != address(0)) {
            return (_lotteries[_lotteryId], 0, 0);
        }

        (uint256 amount, , ) = rafflePool.userInfo(address(this));
        uint256 pendingReward = rafflePool.pendingReward(address(this));
        return (_lotteries[_lotteryId], amount, pendingReward);
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewStatusesForTicketIds(uint256[] calldata _ticketIds)
        external
        view
        returns (bool[] memory)
    {
        uint256 length = _ticketIds.length;
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return ticketStatuses;
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     */
    function viewRewardsForTicketId(uint256 _lotteryId, uint256 _ticketId)
        external
        view
        returns (uint256)
    {
        // Check lottery is in claimable status
        if (_lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId) &&
            (_lotteries[_lotteryId].firstTicketId >= _ticketId)
        ) {
            return 0;
        }

        return _calculateRewardsForTicketId(_lotteryId, _ticketId);
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory,
            bool[] memory,
            uint256
        )
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[
            _user
        ][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][
                i + _cursor
            ];

            // True = ticket claimed
            if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketStatuses, _cursor + length);
    }

    /**
     * @notice Calculate rewards for a given ticket
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     */
    function _calculateRewardsForTicketId(uint256 _lotteryId, uint256 _ticketId)
        internal
        view
        returns (uint256)
    {
        if (
            _lotteries[_lotteryId].winnerCount >= 3 &&
            _ticketId == _lotteries[_lotteryId].winTicketIds[2]
        ) {
            return
                _lotteries[_lotteryId]
                    .amountCollectedInCliff
                    .mul(_lotteries[_lotteryId].rewardsBreakdown[2])
                    .div(10000);
        } else if (
            _lotteries[_lotteryId].winnerCount >= 2 &&
            _ticketId == _lotteries[_lotteryId].winTicketIds[1]
        ) {
            return
                _lotteries[_lotteryId]
                    .amountCollectedInCliff
                    .mul(_lotteries[_lotteryId].rewardsBreakdown[1])
                    .div(10000);
        } else if (
            _lotteries[_lotteryId].winnerCount >= 1 &&
            _ticketId == _lotteries[_lotteryId].winTicketIds[0]
        ) {
            return
                _lotteries[_lotteryId]
                    .amountCollectedInCliff
                    .mul(_lotteries[_lotteryId].rewardsBreakdown[0])
                    .div(10000);
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate final price for bulk of tickets
     * @param _discountDivisor: divisor for the discount (the smaller it is, the greater the discount is)
     * @param _priceTicket: price of a ticket
     * @param _numberTickets: number of tickets purchased
     */
    function _calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) internal pure returns (uint256) {
        return
            (_priceTicket *
                _numberTickets *
                (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}