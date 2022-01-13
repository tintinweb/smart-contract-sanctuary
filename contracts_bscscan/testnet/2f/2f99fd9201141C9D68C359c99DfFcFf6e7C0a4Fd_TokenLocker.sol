pragma solidity >=0.6.0 <0.8.0;

contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}
// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor() internal {
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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: bsc-library/contracts/IBEP20.sol

pragma solidity >=0.4.0;

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
    function allowance(address _owner, address spender)
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

pragma solidity >=0.6.2 <0.8.0;

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

// File: bsc-library/contracts/SafeBEP20.sol

pragma solidity ^0.6.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
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
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

interface IERCBurn {
    function burn(uint256 _amount) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IMigrator {
    function migrate(
        address lpToken,
        uint256 amount,
        uint256 unlockDate,
        address owner
    ) external returns (bool);
}

contract TokenLocker is Ownable, ReentrancyGuard, EternalStorage {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct Package {
        bytes32 name;
        uint32 day;
        uint64 apy;
    }

    struct TokenLock {
        uint256 stakeTimestamp; // the date the token was locked
        uint256 matureTimestamp; // the date the token can be withdrawn
        uint256 unstakeTimestamp; // the date the token can be withdrawn
        uint256 havertTimestamp; // the date the token can be withdrawn
        uint256 balance; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 rewardBalance; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 apy; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 amount; // the initial lock amount
        uint256 rewardAmount; // the initial reward amount
    }

    mapping(address => TokenLock[]) public tokenLocks; //map univ2 pair to all its locks

    Package[] private packages; 
    address payable devaddr;
    // The staked token
    address token0;
    // The reward token
    address token1;
    uint32 penaltyFees;

    IMigrator migrator;

    event onDeposit(
        address user,
        uint256 amount,
        uint256 lockDate,
        uint256 unlockDate
    );
    event onWithdraw(address user, uint256 amount);
    event onReward(address user, uint256 amount);

    constructor() public {
        devaddr = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint32 _penaltyFees) external onlyOwner {
        require(msg.sender == devaddr, 'FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        penaltyFees = _penaltyFees;
    }

    function setDev(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    /**
     * @notice set the migrator contract which allows locked lp tokens to be migrated to uniswap v3
     */
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    /**
     * @notice Creates a new lock
     * @param _amount amount of LP tokens to lock
     * @param _days the unix timestamp (in seconds) until unlock
     */
    function createStake(uint256 _amount, uint _days) external payable nonReentrant {
        require(_days > 0, "DAYS_INVALID"); // prevents errors when timestamp entered in milliseconds
        require(_amount > 0, "INSUFFICIENT");

        bool packageExists = false;
        Package memory package;
        for(uint256 i =0; i< packages.length; i++){
           if(packages[i].day == _days){
              //emit event
              packageExists = true;
              package = packages[i];
           }
        }
        require(packageExists, "INVALID_PACKAGE");

        TransferHelper.safeTransferFrom(
            token0,
            address(msg.sender),
            address(this),
            _amount
        );

        TokenLock memory token_lock;
        token_lock.stakeTimestamp = block.timestamp;
        token_lock.balance = _amount;
        token_lock.amount = _amount;
        token_lock.matureTimestamp = block.timestamp + _days * 1 days;
        token_lock.apy = package.apy;
        token_lock.rewardAmount = _amount.mul(package.apy).div(10000).mul(_days).div(365);
        token_lock.rewardBalance = token_lock.rewardAmount;
        
        tokenLocks[address(msg.sender)].push(token_lock);

        emit onDeposit(
            address(msg.sender),
            token_lock.balance,
            token_lock.stakeTimestamp,
            token_lock.matureTimestamp
        );
    }

    /**
     * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
     */
    function unStake(uint256 _timeStamp) external nonReentrant {
        require(tokenLocks[address(msg.sender)].length > 0, "STAKE_NOT_FOUND");
        require(IBEP20(token0).balanceOf(address(this)) > 0, "INSUFFICIENT_FUND");

        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
           if(tokenLocks[address(msg.sender)][i].stakeTimestamp == _timeStamp){
                TokenLock storage userLock = tokenLocks[address(msg.sender)][i];
                require(userLock.balance > 0 , "UNSTACKED");
                require(userLock.matureTimestamp < block.timestamp, "NO_MATURE");

                uint256 _balance = userLock.balance;
                userLock.balance = userLock.balance.sub(_balance);
                userLock.unstakeTimestamp = block.timestamp;

                IBEP20(token0).safeTransfer(address(msg.sender), _balance);

                emit onWithdraw(address(msg.sender), _balance);

                return;
           }
       }
        revert("STAKE_NOT_FOUND");
    }

    function terminateStake(uint256 _timeStamp) external nonReentrant {
        require(tokenLocks[address(msg.sender)].length > 0, "STAKE_NOT_FOUND");
        require(IBEP20(token0).balanceOf(address(this)) > 0, "INSUFFICIENT_FUND");

        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
           if(tokenLocks[address(msg.sender)][i].stakeTimestamp == _timeStamp){
                TokenLock storage userLock = tokenLocks[address(msg.sender)][i];
                require(userLock.balance > 0 , "UNSTACKED");
                require(userLock.matureTimestamp > block.timestamp, "MATURED");

                uint256 _balance = userLock.balance;
                uint256 _penalty = _balance.mul(penaltyFees).div(10000);
                userLock.balance = userLock.balance.sub(_balance);
                userLock.rewardBalance = 0;
                userLock.unstakeTimestamp = block.timestamp;

                IBEP20(token0).safeTransfer(address(msg.sender), _balance.sub(_penalty));
                IBEP20(token0).safeTransfer(devaddr, _penalty);

                emit onWithdraw(address(msg.sender), _balance);

                return;
           }
       }
        revert("STAKE_NO_FOUND");
    }

    function getStakesCount() public view returns (uint256 count) {
        return tokenLocks[address(msg.sender)].length;
    }

    function getStakesTime() public view returns (
        uint256[] memory stakeTimestamp, 
        uint256[] memory matureTimestamp,
        uint256[] memory unstakeTimestamp,
        uint256[] memory havertTimestamp
    ) {
        uint256[] memory _stakeTimestamp = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _matureTimestamp = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _unstakeTimestamp = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _havertTimestamp = new uint256[](tokenLocks[address(msg.sender)].length);

        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
            _stakeTimestamp[i] = tokenLocks[address(msg.sender)][i].stakeTimestamp;
            _matureTimestamp[i] = tokenLocks[address(msg.sender)][i].matureTimestamp;
            _unstakeTimestamp[i] = tokenLocks[address(msg.sender)][i].unstakeTimestamp;
            _havertTimestamp[i] = tokenLocks[address(msg.sender)][i].havertTimestamp;
        }

        return (_stakeTimestamp, _matureTimestamp, _unstakeTimestamp, _havertTimestamp);
    }

    function getStakesAmount() public view returns (
        uint256[] memory stakeTimestamp, 
        uint256[] memory balance, 
        uint256[] memory rewardBalance,
        uint256[] memory apy,
        uint256[] memory amount,
        uint256[] memory rewardAmount
    ) {
        uint256[] memory _stakeTimestamp = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _balance = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _rewardBalance = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _apy = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _amount = new uint256[](tokenLocks[address(msg.sender)].length);
        uint256[] memory _rewardAmount = new uint256[](tokenLocks[address(msg.sender)].length);

        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
            _stakeTimestamp[i] = tokenLocks[address(msg.sender)][i].stakeTimestamp;
            _balance[i] = tokenLocks[address(msg.sender)][i].balance;
            _rewardBalance[i] = tokenLocks[address(msg.sender)][i].rewardBalance;
            _apy[i] = tokenLocks[address(msg.sender)][i].apy;
            _amount[i] = tokenLocks[address(msg.sender)][i].amount;
            _rewardAmount[i] = tokenLocks[address(msg.sender)][i].rewardAmount;
        }

        return (_stakeTimestamp, _balance, _rewardBalance, _apy, _amount, _rewardAmount);
    }

    function getStakesTotal() public view returns (
        uint256 totalBalance, 
        uint256 totalRewardBalance,
        uint256 totalAmount,
        uint256 totalRewardAmount
    ) {
        uint256 _totalBalance = 0;
        uint256 _totalRewardBalance = 0;
        uint256 _totalAmount = 0;
        uint256 _totalRewardAmount = 0;
        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
            _totalBalance += tokenLocks[address(msg.sender)][i].balance;
            _totalRewardBalance += tokenLocks[address(msg.sender)][i].rewardBalance;
            _totalAmount += tokenLocks[address(msg.sender)][i].amount;
            _totalRewardAmount += tokenLocks[address(msg.sender)][i].rewardAmount;
        }

        return (_totalBalance, _totalRewardBalance, _totalAmount, _totalRewardAmount);
    }

    function getStake(uint256 _timeStamp) public view returns (
        uint256 stakeTimestamp, 
        uint256 matureTimestamp,
        uint256 unstakeTimestamp,
        uint256 havertTimestamp,
        uint256 balance, 
        uint256 rewardBalance,
        uint256 apy,
        uint256 amount,
        uint256 rewardAmount
    ) {
        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
           if(tokenLocks[address(msg.sender)][i].stakeTimestamp == _timeStamp){
              //emit event
              return (
                tokenLocks[address(msg.sender)][i].stakeTimestamp,
                tokenLocks[address(msg.sender)][i].matureTimestamp,
                tokenLocks[address(msg.sender)][i].unstakeTimestamp,
                tokenLocks[address(msg.sender)][i].havertTimestamp,
                tokenLocks[address(msg.sender)][i].balance,
                tokenLocks[address(msg.sender)][i].rewardBalance,
                tokenLocks[address(msg.sender)][i].apy,
                tokenLocks[address(msg.sender)][i].amount,
                tokenLocks[address(msg.sender)][i].rewardAmount
              );
           }
       }
       revert("PACKAGE_NOT_FOUND");
    }

    function harvestStake(uint256 _timeStamp) external nonReentrant {
        require(tokenLocks[address(msg.sender)].length > 0, "STAKE_NOT_FOUND");
        require(IBEP20(token1).balanceOf(address(this)) > 0, "INSUFFICIENT_FUND");

        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
           if(tokenLocks[address(msg.sender)][i].stakeTimestamp == _timeStamp){
                TokenLock storage userLock = tokenLocks[address(msg.sender)][i];
                require(userLock.rewardBalance > 0 , "HARVESTED");
                require(userLock.matureTimestamp < block.timestamp, "NO_MATURE");
                // harvest
                uint256 _rewards = userLock.rewardBalance;
                userLock.rewardBalance = userLock.rewardBalance.sub(_rewards);
                userLock.havertTimestamp = block.timestamp;

                IBEP20(token1).safeTransfer(address(msg.sender), _rewards);

                emit onReward(address(msg.sender), _rewards);

                return;
           }
       }
        revert("STAKE_NO_FOUND");
    }

    function harvestAndUnStake(uint256 _timeStamp) external nonReentrant {
        require(tokenLocks[address(msg.sender)].length > 0, "STAKE_NOT_FOUND");
        require(IBEP20(token0).balanceOf(address(this)) > 0, "INSUFFICIENT_FUND");
        require(IBEP20(token1).balanceOf(address(this)) > 0, "INSUFFICIENT_FUND");

        for(uint256 i =0; i< tokenLocks[address(msg.sender)].length; i++){
           if(tokenLocks[address(msg.sender)][i].stakeTimestamp == _timeStamp){
                TokenLock storage userLock = tokenLocks[address(msg.sender)][i];
                require(userLock.balance > 0 , "UNSTACKED");
                require(userLock.rewardBalance > 0 , "HARVESTED");
                require(userLock.matureTimestamp < block.timestamp, "NO_MATURE");
                // unstake
                uint256 _balance = userLock.balance;
                userLock.balance = userLock.balance.sub(_balance);
                userLock.unstakeTimestamp = block.timestamp;

                // harvest
                uint256 _rewards = userLock.rewardBalance;
                userLock.rewardBalance = userLock.rewardBalance.sub(_rewards);
                userLock.havertTimestamp = block.timestamp;

                IBEP20(token0).safeTransfer(address(msg.sender), _balance);
                IBEP20(token1).safeTransfer(address(msg.sender), _rewards);

                emit onWithdraw(address(msg.sender), _balance);
                emit onReward(address(msg.sender), _rewards);

                return;
           }
       }
        revert("STAKE_NOT_FOUND");
    }

    function getDevAdd() external view returns (address) {
        return devaddr;
    }

    function addPackage(bytes32 _name, uint32 _day, uint64 _apy) public onlyOwner {
        require(_day > 0, "DAYS_INVALID");
        require(_apy > 0, "APY_INVALID");

        for(uint256 i =0; i< packages.length; i++){
           if(packages[i].day == _day){
              //emit event
            revert("PACKAGE_EXISTS");
           }
       }

        Package memory package = Package(_name, _day, _apy);
        packages.push(package);
    }

    function removePackage(uint32 _day) public onlyOwner {
        require(packages.length > 0);
        for(uint256 i =0; i< packages.length; i++){
           if(packages[i].day == _day){
              packages[i] = packages[packages.length-1];
              delete packages[packages.length-1];
              packages.pop();
           }
       }
    }

    function getPackagesCount() public view returns (uint256 count) {
        return packages.length;
    }

    function getPackages() public view returns (bytes32[] memory name , uint32[] memory day , uint64[] memory apy) {
        bytes32[] memory _name = new bytes32[](packages.length);
        uint32[] memory _day = new uint32[](packages.length);
        uint64[] memory _apy = new uint64[](packages.length);

        for(uint256 i =0; i< packages.length; i++){
            _name[i] = packages[i].name;
            _day[i] = packages[i].day;
            _apy[i] = packages[i].apy;
        }

        return (_name, _day, _apy);
    }

    function getPackage(uint32 _day) public view returns (bytes32 name, uint32 day, uint64 apy) {
        for(uint256 i =0; i< packages.length; i++){
           if(packages[i].day == _day){
              //emit event
              return (packages[i].name , packages[i].day , packages[i].apy);
           }
       }
       revert('package not found');
    }

    function getPenaltyFees() public view returns (uint32 penalty) {
        return penaltyFees;
    }
}