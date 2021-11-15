// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";
import "./interfaces/IDrawPrize.sol";
import "./interfaces/IDrawCalculator.sol";
import "./libraries/DrawLib.sol";

/**
  * @title  PoolTogether V4 DrawPrize
  * @author PoolTogether Inc Team
  * @notice The DrawPrize distributes claimable draw prizes to users via a pull model.
            Managing the regularly captured PrizePool interest, a DrawPrize is the
            entrypoint for users to submit Draw.drawId(s) and winning pick indices.
            Communicating with a DrawCalculator, the DrawPrize will determine the maximum
            prize payout and transfer those tokens directly to a user address. 
*/
contract DrawPrize is IDrawPrize, Ownable {
  using SafeERC20 for IERC20;

  /* ============ Global Variables ============ */

  /// @notice The Draw Calculator to use
  IDrawCalculator internal drawCalculator;
  
  /// @notice Token address
  IERC20          internal immutable token;

  /// @notice Maps users => drawId => paid out balance
  mapping(address => mapping(uint256 => uint256)) internal userDrawPayouts;

  /* ============ Initialize ============ */

  /**
    * @notice Initialize DrawPrize smart contract.
    * @param _owner           Address of the DrawPrize owner
    * @param _token           Token address
    * @param _drawCalculator DrawCalculator address
  */
  constructor(
    address _owner,
    IERC20 _token,
    IDrawCalculator _drawCalculator
  ) Ownable(_owner) {
    _setDrawCalculator(_drawCalculator);
    require(address(_token) != address(0), "DrawPrize/token-not-zero-address" );
    token = _token;
    emit TokenSet(_token);
  }

  /* ============ External Functions ============ */

  /// @inheritdoc IDrawPrize
  function claim(address _user, uint32[] calldata _drawIds, bytes calldata _data) external override returns (uint256) {
    uint256 totalPayout;
    uint256[] memory drawPayouts = drawCalculator.calculate(_user, _drawIds, _data);  // CALL
    for (uint256 payoutIndex = 0; payoutIndex < drawPayouts.length; payoutIndex++) {
      uint32 drawId = _drawIds[payoutIndex];
      uint256 payout = drawPayouts[payoutIndex];
      uint256 oldPayout = _getDrawPayoutBalanceOf(_user, drawId);
      uint256 payoutDiff = 0;
      if (payout > oldPayout) {
        payoutDiff = payout - oldPayout;
        _setDrawPayoutBalanceOf(_user, drawId, payout);
      }
      // helpfully short-circuit, in case the user screwed something up.
      require(payoutDiff > 0, "DrawPrize/zero-payout");
      totalPayout += payoutDiff;
      emit ClaimedDraw(_user, drawId, payoutDiff);
    }

    _awardPayout(_user, totalPayout);

    return totalPayout;
  }

  /// @inheritdoc IDrawPrize
  function getDrawCalculator() external override view returns (IDrawCalculator) {
    return drawCalculator;
  }

  /// @inheritdoc IDrawPrize
  function getDrawPayoutBalanceOf(address user, uint32 drawId) external override view returns (uint256) {
    return _getDrawPayoutBalanceOf(user, drawId);
  }

  /// @inheritdoc IDrawPrize
  function getToken() external override view returns (IERC20) {
    return token;
  }

  /// @inheritdoc IDrawPrize
  function setDrawCalculator(IDrawCalculator _newCalculator) external override onlyOwner returns (IDrawCalculator) {
    _setDrawCalculator(_newCalculator);
    return _newCalculator;
  }

  
  /* ============ Internal Functions ============ */

  function _getDrawPayoutBalanceOf(address _user, uint32 _drawId) internal view returns (uint256) {
    return userDrawPayouts[_user][_drawId];
  }

  function _setDrawPayoutBalanceOf(address _user, uint32 _drawId, uint256 _payout) internal {
    userDrawPayouts[_user][_drawId] = _payout;
  }

  /**
    * @notice Sets DrawCalculator reference for individual draw id.
    * @param _newCalculator  DrawCalculator address
  */
  function _setDrawCalculator(IDrawCalculator _newCalculator) internal {
    require(address(_newCalculator) != address(0), "DrawPrize/calc-not-zero");
    drawCalculator = _newCalculator;
    emit DrawCalculatorSet(_newCalculator);
  }

  /**
    * @notice Transfer claimed draw(s) total payout to user.
    * @param _to      User address
    * @param _amount  Transfer amount
  */
  function _awardPayout(address _to, uint256 _amount) internal {
    token.safeTransfer(_to, _amount);
  }

  /**
    * @notice Transfer ERC20 tokens out of this contract.
    * @dev    This function is only callable by the owner.
    * @param _erc20Token ERC20 token to transfer.
    * @param _to Recipient of the tokens.
    * @param _amount Amount of tokens to transfer.
    * @return true if operation is successful.
  */
  function withdrawERC20(IERC20 _erc20Token, address _to, uint256 _amount) external override onlyOwner returns (bool) {
    require(_to != address(0), "DrawPrize/recipient-not-zero-address");
    require(address(_erc20Token) != address(0), "DrawPrize/ERC20-not-zero-address");
    _erc20Token.safeTransfer(_to, _amount);
    emit ERC20Withdrawn(_erc20Token, _to, _amount);
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./libraries/DrawLib.sol";
import "./libraries/DrawRingBufferLib.sol";
import "./interfaces/IPrizeDistributionHistory.sol";

/**
  * @title  PoolTogether V4 PrizeDistributionHistory
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributionHistory stores individual PrizeDistributions for each Draw.drawId.
            PrizeDistributions parameters like cardinality, bitRange, distributions, number of picks
            and prize. The settings determine the specific distribution model for each individual
            draw. Storage of the PrizeDistribution(s) is handled by ring buffer with a max cardinality
            of 256 or roughly 5 years of history with a weekly draw cadence.
*/
contract PrizeDistributionHistory is IPrizeDistributionHistory, Manageable {
  using DrawRingBufferLib for DrawRingBufferLib.Buffer;

  uint256 internal constant MAX_CARDINALITY = 256;

  uint256 internal constant DISTRIBUTION_CEILING = 1e9;
  event Deployed(uint8 cardinality);

  /// @notice PrizeDistributions ring buffer history.
  DrawLib.PrizeDistribution[MAX_CARDINALITY] internal _prizeDistributionsRingBuffer;

  /// @notice Ring buffer data (nextIndex, lastDrawId, cardinality)
  DrawRingBufferLib.Buffer internal prizeDistributionsRingBufferData;

  /* ============ Constructor ============ */

  /**
    * @notice Constructor for PrizeDistributionHistory
    * @param _owner Address of the PrizeDistributionHistory owner
    * @param _cardinality Cardinality of the `prizeDistributionsRingBufferData`
   */
  constructor(
    address _owner,
    uint8 _cardinality
  ) Ownable(_owner) {
    prizeDistributionsRingBufferData.cardinality = _cardinality;
    emit Deployed(_cardinality);
  }

  /* ============ External Functions ============ */

  /// @inheritdoc IPrizeDistributionHistory
  function getPrizeDistribution(uint32 _drawId) external override view returns(DrawLib.PrizeDistribution memory) {
    return _getPrizeDistributions(prizeDistributionsRingBufferData, _drawId);
  }

  /// @inheritdoc IPrizeDistributionHistory
  function getPrizeDistributions(uint32[] calldata _drawIds) external override view returns(DrawLib.PrizeDistribution[] memory) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    DrawLib.PrizeDistribution[] memory _prizeDistributions = new DrawLib.PrizeDistribution[](_drawIds.length);
    for (uint256 i = 0; i < _drawIds.length; i++) {
      _prizeDistributions[i] = _getPrizeDistributions(buffer, _drawIds[i]);
    }
    return _prizeDistributions;
  }

  /// @inheritdoc IPrizeDistributionHistory
  function getNewestPrizeDistribution() external override view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    return (_prizeDistributionsRingBuffer[buffer.getIndex(buffer.lastDrawId)], buffer.lastDrawId);
  }

  /// @inheritdoc IPrizeDistributionHistory
  function getOldestPrizeDistribution() external override view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    prizeDistribution = _prizeDistributionsRingBuffer[buffer.nextIndex];

    // IF the next PrizeDistributions.bitRangeSize == 0 the ring buffer HAS NOT looped around.
    // The PrizeDistributions at index 0 IS by defaut the oldest prizeDistribution.
    if (buffer.lastDrawId == 0) {
      drawId = 0; // return 0 to indicate no prizeDistribution ring buffer history
    } else if (prizeDistribution.bitRangeSize == 0) {
      prizeDistribution = _prizeDistributionsRingBuffer[0];
      drawId = (buffer.lastDrawId + 1) - buffer.nextIndex; // 2 + 1 - 2 = 1 | [1,2,0]
    } else {
      // Calculates the Draw.drawID using the ring buffer length and SEQUENTIAL id(s)
      // Sequential "guaranteedness" is handled in DrawRingBufferLib.push()
      drawId = (buffer.lastDrawId + 1) - buffer.cardinality; // 4 + 1 - 3 = 2 | [4,2,3]
    }
  }

  /// @inheritdoc IPrizeDistributionHistory
  function pushPrizeDistribution(uint32 _drawId, DrawLib.PrizeDistribution calldata _prizeDistribution) external override onlyManagerOrOwner returns (bool) {
    return _pushPrizeDistribution(_drawId, _prizeDistribution);
  }

  /// @inheritdoc IPrizeDistributionHistory
  function setPrizeDistribution(uint32 _drawId, DrawLib.PrizeDistribution calldata _prizeDistribution) external override onlyOwner returns (uint32) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    uint32 index = buffer.getIndex(_drawId);
    _prizeDistributionsRingBuffer[index] = _prizeDistribution;
    emit PrizeDistributionsSet(_drawId, _prizeDistribution);
    return _drawId;
  }


  /* ============ Internal Functions ============ */

  /**
    * @notice Gets the PrizeDistributionHistory for a Draw.drawID
    * @param _prizeDistributionsRingBufferData DrawRingBufferLib.Buffer
    * @param drawId Draw.drawId
   */
  function _getPrizeDistributions(
    DrawRingBufferLib.Buffer memory _prizeDistributionsRingBufferData,
    uint32 drawId
  ) internal view returns (DrawLib.PrizeDistribution memory) {
    return _prizeDistributionsRingBuffer[_prizeDistributionsRingBufferData.getIndex(drawId)];
  }

  /**
    * @notice Set newest PrizeDistributionHistory in ring buffer storage.
    * @param _drawId       Draw.drawId
    * @param _prizeDistribution PrizeDistributionHistory struct
   */
  function _pushPrizeDistribution(uint32 _drawId, DrawLib.PrizeDistribution calldata _prizeDistribution) internal returns (bool) {
    require(_drawId > 0, "DrawCalc/draw-id-gt-0");
    require(_prizeDistribution.bitRangeSize <= 256 / _prizeDistribution.matchCardinality, "DrawCalc/bitRangeSize-too-large");
    require(_prizeDistribution.bitRangeSize > 0, "DrawCalc/bitRangeSize-gt-0");
    require(_prizeDistribution.maxPicksPerUser > 0, "DrawCalc/maxPicksPerUser-gt-0");

    // ensure that the distributions are not gt 100%
    uint256 sumTotalDistributions = 0;
    uint256 nonZeroDistributions = 0;
    uint256 distributionsLength = _prizeDistribution.distributions.length;

    for(uint256 index = 0; index < distributionsLength; index++){
      sumTotalDistributions += _prizeDistribution.distributions[index];
      if(_prizeDistribution.distributions[index] > 0){
        nonZeroDistributions++;
      }
    }

    // Each distribution amount stored as uint32 - summed can't exceed 1e9
    require(sumTotalDistributions <= DISTRIBUTION_CEILING, "DrawCalc/distributions-gt-100%");

    require(_prizeDistribution.matchCardinality >= nonZeroDistributions, "DrawCalc/matchCardinality-gte-distributions");

    DrawRingBufferLib.Buffer memory _prizeDistributionsRingBufferData = prizeDistributionsRingBufferData;
    _prizeDistributionsRingBuffer[_prizeDistributionsRingBufferData.nextIndex] = _prizeDistribution;
    prizeDistributionsRingBufferData = prizeDistributionsRingBufferData.push(_drawId);

    emit PrizeDistributionsSet(_drawId, _prizeDistribution);

    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "./ITicket.sol";
import "./IDrawHistory.sol";
import "../PrizeDistributionHistory.sol";
import "../DrawPrize.sol";
import "../libraries/DrawLib.sol";

/**
  * @title  PoolTogether V4 DrawCalculator
  * @author PoolTogether Inc Team
  * @notice The DrawCalculator interface.
*/
interface IDrawCalculator {

  struct PickPrize {
    bool won;
    uint8 distributionIndex;
  }

  ///@notice Emitted when the contract is initialized
  event Deployed(ITicket indexed ticket);

  ///@notice Emitted when the drawPrize is set/updated
  event DrawPrizeSet(DrawPrize indexed drawPrize);

  /**
    * @notice Calulates the prize amount for a user for Multiple Draws. Typically called by a DrawPrize.
    * @param user User for which to calcualte prize amount
    * @param drawIds draw array for which to calculate prize amounts for
    * @param data The encoded pick indices for all Draws. Expected to be just indices of winning claims. Populated values must be less than totalUserPicks.
    * @return List of awardable prizes ordered by linked drawId
   */
  function calculate(address user, uint32[] calldata drawIds, bytes calldata data) external view returns (uint256[] memory);

  /**
    * @notice Read global DrawHistory variable.
    * @return IDrawHistory
  */
  function getDrawHistory() external view returns (IDrawHistory);

  /**
    * @notice Read global DrawHistory variable.
    * @return IDrawHistory
  */
  function getPrizeDistributionHistory() external view returns (PrizeDistributionHistory);
  /**
    * @notice Set global DrawHistory reference.
    * @param _drawHistory DrawHistory address
    * @return New DrawHistory address
  */
  function setDrawHistory(IDrawHistory _drawHistory) external returns (IDrawHistory);
  
  /**
    * @notice Returns a users balances expressed as a fraction of the total supply over time.
    * @param _user The users address
    * @param _drawIds The drawsId to consider
    * @return Array of balances
  */
  function getNormalizedBalancesForDrawIds(address _user, uint32[] calldata _drawIds) external view returns (uint256[] memory);

  /**
    * @notice Returns a users balances expressed as a fraction of the total supply over time.
    * @param _user The user for which to calculate the distribution indices
    * @param _pickIndices The users pick indices for a draw
    * @param _drawId The draw for which to calculate the distribution indices
    * @return List of distributions for Draw.drawId
  */
  function checkPrizeDistributionIndicesForDrawId(address _user, uint64[] calldata _pickIndices, uint32 _drawId) external view returns(PickPrize[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "../libraries/DrawLib.sol";

interface IDrawHistory {

  /**
    * @notice Emit when a new draw has been created.
    * @param drawId Draw id
    * @param draw The Draw struct
  */
  event DrawSet (
    uint32 indexed drawId,
    DrawLib.Draw draw
  );

  /**
    * @notice Read a Draw from the draws ring buffer.
    * @dev    Read a Draw using the Draw.drawId to calculate position in the draws ring buffer.
    * @param drawId Draw.drawId
    * @return DrawLib.Draw
  */
  function getDraw(uint32 drawId) external view returns (DrawLib.Draw memory);

  /**
    * @notice Read multiple Draws from the draws ring buffer.
    * @dev    Read multiple Draws using each Draw.drawId to calculate position in the draws ring buffer.
    * @param drawIds Array of Draw.drawIds
    * @return DrawLib.Draw[]
  */
  function getDraws(uint32[] calldata drawIds) external view returns (DrawLib.Draw[] memory);
  /**
    * @notice Read newest Draw from the draws ring buffer.
    * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
    * @return DrawLib.Draw
  */
  function getNewestDraw() external view returns (DrawLib.Draw memory);
  /**
    * @notice Read oldest Draw from the draws ring buffer.
    * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with the cardinality.
    * @return DrawLib.Draw
  */
  function getOldestDraw() external view returns (DrawLib.Draw memory);

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Push new draw onto draws history via authorized manager or owner.
    * @param draw DrawLib.Draw
    * @return Draw.drawId
  */
  function pushDraw(DrawLib.Draw calldata draw) external returns(uint32);

  /**
    * @notice Set existing Draw in draws ring buffer with new parameters.
    * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
    * @param newDraw DrawLib.Draw
    * @return Draw.drawId
  */
  function setDraw(DrawLib.Draw calldata newDraw) external returns(uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDrawHistory.sol";
import "./IDrawCalculator.sol";
import "../libraries/DrawLib.sol";

interface IDrawPrize {

  /**
    * @notice Emitted when a user has claimed N draw payouts.
    * @param user        User address receiving draw claim payouts
    * @param drawId      Draw id that was paid out
    * @param payout Payout for draw
  */
  event ClaimedDraw (
    address indexed user,
    uint32 indexed drawId,
    uint256 payout
  );

  /**
    * @notice Emitted when a DrawCalculator is set
    * @param calculator DrawCalculator address
  */
  event DrawCalculatorSet (
    IDrawCalculator indexed calculator
  );

  /**
    * @notice Emitted when a global Ticket variable is set.
    * @param token Token address
  */
  event TokenSet (
    IERC20 indexed token
  );

  /**
    * @notice Emitted when ERC20 tokens are withdrawn
    * @param token ERC20 token transferred.
    * @param to Address that received funds.
    * @param amount Amount of tokens transferred.
  */
  event ERC20Withdrawn(
    IERC20 indexed token,
    address indexed to,
    uint256 amount
  );

  /**
    * @notice Claim a user token payouts via a collection of draw ids and pick indices.
    * @param user    Address of user to claim awards for. Does NOT need to be msg.sender
    * @param drawIds Draw IDs from global DrawHistory reference
    * @param data    The data to pass to the draw calculator
    * @return Actual claim payout.  If the user has previously claimed a draw, this may be less.
  */
  function claim(address user, uint32[] calldata drawIds, bytes calldata data) external returns (uint256);
  
  /**
    * @notice Read DrawCalculator
    * @return IDrawCalculator
  */
  function getDrawCalculator() external view returns (IDrawCalculator);
  
  /**
    * @notice Get the amount that a user has already been paid out for a draw
    * @param user   User address
    * @param drawId Draw ID
  */
  function getDrawPayoutBalanceOf(address user, uint32 drawId) external view returns (uint256);

  /**
    * @notice Read global Ticket variable.
    * @return IERC20
  */
  function getToken() external view returns (IERC20);
  /**
    * @notice Sets DrawCalculator reference for individual draw id.
    * @param _newCalculator  DrawCalculator address
    * @return New DrawCalculator address
  */
  function setDrawCalculator(IDrawCalculator _newCalculator) external returns(IDrawCalculator);
  function withdrawERC20(IERC20 _erc20Token, address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../libraries/DrawLib.sol";

interface IPrizeDistributionHistory {

  /**
    * @notice Emit when a new draw has been created.
    * @param drawId       Draw id
    * @param timestamp    Epoch timestamp when the draw is created.
    * @param winningRandomNumber Randomly generated number used to calculate draw winning numbers
  */
  event DrawSet (
    uint32 drawId,
    uint32 timestamp,
    uint256 winningRandomNumber
  );

  /**
    * @notice Emitted when the DrawParams are set/updated
    * @param drawId       Draw id
    * @param prizeDistributions DrawLib.PrizeDistribution
  */
  event PrizeDistributionsSet(uint32 indexed drawId, DrawLib.PrizeDistribution prizeDistributions);


  /**
    * @notice Read newest PrizeDistributions from the prize distributions ring buffer.
    * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
    * @return prizeDistribution DrawLib.PrizeDistribution
    * @return drawId Draw.drawId
  */
  function getNewestPrizeDistribution() external view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId);

  /**
    * @notice Read oldest PrizeDistributions from the prize distributions ring buffer.
    * @dev    Finds the oldest Draw by buffer.nextIndex and buffer.lastDrawId
    * @return prizeDistribution DrawLib.PrizeDistribution
    * @return drawId Draw.drawId
  */
  function getOldestPrizeDistribution() external view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId);

  /**
    * @notice Gets array of PrizeDistributionHistory for Draw.drawID(s)
    * @param drawIds Draw.drawId
   */
  function getPrizeDistributions(uint32[] calldata drawIds) external view returns (DrawLib.PrizeDistribution[] memory);

  /**
    * @notice Gets the PrizeDistributionHistory for a Draw.drawID
    * @param drawId Draw.drawId
   */
  function getPrizeDistribution(uint32 drawId) external view returns (DrawLib.PrizeDistribution memory);

  /**
    * @notice Sets PrizeDistributionHistory for a Draw.drawID.
    * @dev    Only callable by the owner or manager
    * @param drawId Draw.drawId
    * @param draw   PrizeDistributionHistory struct
   */
  function pushPrizeDistribution(uint32 drawId, DrawLib.PrizeDistribution calldata draw) external returns(bool);

  /**
    * @notice Set existing Draw in prize distributions ring buffer with new parameters.
    * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
    * @return Draw.drawId
  */
  function setPrizeDistribution(uint32 drawId, DrawLib.PrizeDistribution calldata draw) external returns(uint32); // maybe return drawIndex

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../libraries/TwabLib.sol";
interface ITicket {

  /**  
    * @notice A struct containing details for an Account
    * @param balance The current balance for an Account
    * @param nextTwabIndex The next available index to store a new twab
    * @param cardinality The number of recorded twabs (plus one!)
  */
  struct AccountDetails {
    uint224 balance;
    uint16 nextTwabIndex;
    uint16 cardinality;
  }

  /**  
    * @notice Combines account details with their twab history
    * @param details The account details
    * @param twabs The history of twabs for this account
  */
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[65535] twabs;
  }

  event Delegated(
    address indexed user,
    address indexed delegate
  );

  /** 
    * @notice Emitted when ticket is initialized.
    * @param name Ticket name (eg: PoolTogether Dai Ticket (Compound)).
    * @param symbol Ticket symbol (eg: PcDAI).
    * @param decimals Ticket decimals.
    * @param controller Token controller address.
  */
  event TicketInitialized(
    string name,
    string symbol,
    uint8 decimals,
    address controller
  );

  /** 
    * @notice Emitted when a new TWAB has been recorded.
    * @param ticketHolder The Ticket holder address.
    * @param user The recipient of the ticket power (may be the same as the ticketHolder)
    * @param newTwab Updated TWAB of a ticket holder after a successful TWAB recording.
  */
  event NewUserTwab(
    address indexed ticketHolder,
    address indexed user,
    ObservationLib.Observation newTwab
  );

  /** 
    * @notice Emitted when a new total supply TWAB has been recorded.
    * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a successful total supply TWAB recording.
  */
  event NewTotalSupplyTwab(
    ObservationLib.Observation newTotalSupplyTwab
  );

   /** 
    * @notice ADD DOCS
    * @param user Address
  */
  function delegateOf(address user) external view returns (address);

  /**
    * @notice Delegate time-weighted average balances to an alternative address.
    * @dev    Transfers (including mints) trigger the storage of a TWAB in delegatee(s) account, instead of the
              targetted sender and/or recipient address(s).
    * @dev    "to" reset the delegatee use zero address (0x000.000) 
    * @param  to Receipient of delegated TWAB
   */
  function delegate(address to) external;
  
  /** 
    * @notice Gets a users twab context.  This is a struct with their balance, next twab index, and cardinality.
    * @param user The user for whom to fetch the TWAB context
    * @return The TWAB context, which includes { balance, nextTwabIndex, cardinality }
  */
  function getAccountDetails(address user) external view returns (TwabLib.AccountDetails memory);
  
  /** 
    * @notice Gets the TWAB at a specific index for a user.
    * @param user The user for whom to fetch the TWAB
    * @param index The index of the TWAB to fetch
    * @return The TWAB, which includes the twab amount and the timestamp.
  */
  function getTwab(address user, uint16 index) external view returns (ObservationLib.Observation memory);

  /** 
    * @notice Retrieves `_user` TWAB balance.
    * @param user Address of the user whose TWAB is being fetched.
    * @param timestamp Timestamp at which the reserved TWAB should be for.
  */
  function getBalanceAt(address user, uint256 timestamp) external view returns(uint256);

  /** 
    * @notice Retrieves `_user` TWAB balances.
    * @param user Address of the user whose TWABs are being fetched.
    * @param timestamps Timestamps at which the reserved TWABs should be for.
    * @return uint256[] `_user` TWAB balances.
  */
  function getBalancesAt(address user, uint32[] calldata timestamps) external view returns(uint256[] memory);

  /** 
    * @notice Calculates the average balance held by a user for a given time frame.
    * @param user The user whose balance is checked
    * @param startTime The start time of the time frame.
    * @param endTime The end time of the time frame.
    * @return The average balance that the user held during the time frame.
  */
  function getAverageBalanceBetween(address user, uint256 startTime, uint256 endTime) external view returns (uint256);

  /** 
    * @notice Calculates the average balance held by a user for a given time frame.
    * @param user The user whose balance is checked
    * @param startTimes The start time of the time frame.
    * @param endTimes The end time of the time frame.
    * @return The average balance that the user held during the time frame.
  */
  function getAverageBalancesBetween(address user, uint32[] calldata startTimes, uint32[] calldata endTimes) external view returns (uint256[] memory);

  /** 
    * @notice Calculates the average total supply balance for a set of a given time frame.
    * @param timestamp Timestamp
    * @return The
  */
  function getTotalSupplyAt(uint32 timestamp) external view returns(uint256);

   /** 
    * @notice Calculates the average total supply balance for a set of a given time frame.
    * @param timestamps Timestamp
    * @return The
  */
  function getTotalSuppliesAt(uint32[] calldata timestamps) external view returns(uint256[] memory);

  /** 
    * @notice Calculates the average total supply balance for a set of given time frames.
    * @param startTimes Array of start times
    * @param endTimes Array of end times
    * @return The average total supplies held during the time frame.
  */
  function getAverageTotalSuppliesBetween(uint32[] calldata startTimes, uint32[] calldata endTimes) external view returns(uint256[] memory);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library DrawLib {

    struct Draw {
        uint256 winningRandomNumber;
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
    }

    uint8 public constant DISTRIBUTIONS_LENGTH = 16;

    ///@notice Draw settings for the tsunami draw calculator
    ///@param bitRangeSize Decimal representation of bitRangeSize
    ///@param matchCardinality The bitRangeSize's to consider in the 256 random numbers. Must be > 1 and < 256/bitRangeSize
    ///@param startTimestampOffset The starting time offset in seconds from which Ticket balances are calculated.
    ///@param endTimestampOffset The end time offset in seconds from which Ticket balances are calculated.
    ///@param maxPicksPerUser Maximum number of picks a user can make in this Draw
    ///@param numberOfPicks Number of picks this Draw has (may vary network to network)
    ///@param distributions Array of prize distributions percentages, expressed in fraction form with base 1e18. Max sum of these <= 1 Ether. ordering: index0: grandPrize, index1: runnerUp, etc.
    ///@param prize Total prize amount available in this draw calculator for this Draw (may vary from network to network)
    struct PrizeDistribution {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint32 maxPicksPerUser;
        uint136 numberOfPicks;
        uint32[DISTRIBUTIONS_LENGTH] distributions;
        uint256 prize;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./RingBuffer.sol";

/// @title Library for creating and managing a draw ring buffer.
library DrawRingBufferLib {

  /// @notice Draw buffer struct.
  struct Buffer {
    uint32 lastDrawId;
    uint32 nextIndex;
    uint32 cardinality;
  }

  /// @notice Helper function to know if the draw ring buffer has been initialized.
  /// @dev since draws start at 1 and are monotonically increased, we know we are uninitialized if nextIndex = 0 and lastDrawId = 0.
  /// @param _buffer The buffer to check.
  function isInitialized(Buffer memory _buffer) internal pure returns (bool) {
    return !(_buffer.nextIndex == 0 && _buffer.lastDrawId == 0);
  }

  /// @notice Push a draw to the buffer.
  /// @param _buffer The buffer to push to.
  /// @param _drawId The draw id to push.
  /// @return The new buffer.
  function push(Buffer memory _buffer, uint32 _drawId) internal pure returns (Buffer memory) {
    require(!isInitialized(_buffer) || _drawId == _buffer.lastDrawId + 1, "DRB/must-be-contig");
    return Buffer({
      lastDrawId: _drawId,
      nextIndex: uint32(RingBuffer.nextIndex(_buffer.nextIndex, _buffer.cardinality)),
      cardinality: _buffer.cardinality
    });
  }

  /// @notice Get draw ring buffer index pointer.
  /// @param _buffer The buffer to get the `nextIndex` from.
  /// @param _drawId The draw id to get the index for.
  /// @return The draw ring buffer index pointer.
  function getIndex(Buffer memory _buffer, uint32 _drawId) internal pure returns (uint32) {
    require(isInitialized(_buffer) && _drawId <= _buffer.lastDrawId, "DRB/future-draw");

    uint32 indexOffset = _buffer.lastDrawId - _drawId;
    require(indexOffset < _buffer.cardinality, "DRB/expired-draw");

    uint256 mostRecent = RingBuffer.mostRecentIndex(_buffer.nextIndex, _buffer.cardinality);

    return uint32(RingBuffer.offset(uint32(mostRecent), indexOffset, _buffer.cardinality));
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library ExtendedSafeCast {
    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./OverflowSafeComparator.sol";
import "./RingBuffer.sol";

/// @title Observation Library
/// @notice This library allows one to store an array of timestamped values and efficiently binary search them.
/// @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library ObservationLib {
  using OverflowSafeComparator for uint32;
  using SafeCast for uint256;

  /// @notice The maximum number of observations
  uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

  /// @notice Observation, which includes an amount and timestamp
  /// @param amount `amount` at `timestamp`.
  /// @param timestamp Recorded `timestamp`.
  struct Observation {
    uint224 amount;
    uint32 timestamp;
  }

  /// @notice Fetches Observations `beforeOrAt` and `atOrAfter` a `_target`, eg: where [`beforeOrAt`, `atOrAfter`] is satisfied.
  /// The result may be the same Observation, or adjacent Observations.
  /// @dev The answer must be contained in the array, used when the target is located within the stored Observation.
  /// boundaries: older than the most recent Observation and younger, or the same age as, the oldest Observation.
  /// @param _observations List of Observations to search through.
  /// @param _observationIndex Index of the Observation to start searching from.
  /// @param _target Timestamp at which the reserved Observation should be for.
  /// @return beforeOrAt Observation recorded before, or at, the target.
  /// @return atOrAfter Observation recorded at, or after, the target.
  function binarySearch(
    Observation[MAX_CARDINALITY] storage _observations,
    uint24 _observationIndex,
    uint24 _oldestObservationIndex,
    uint32 _target,
    uint24 _cardinality,
    uint32 _time
  ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    uint256 leftSide = _oldestObservationIndex; // Oldest Observation
    uint256 rightSide = _observationIndex < leftSide ? leftSide + _cardinality - 1 : _observationIndex;
    uint256 currentIndex;

    while (true) {
      currentIndex = (leftSide + rightSide) / 2;
      beforeOrAt = _observations[uint24(RingBuffer.wrap(currentIndex, _cardinality))];
      uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

      // We've landed on an uninitialized timestamp, keep searching higher (more recently)
      if (beforeOrAtTimestamp == 0) {
        leftSide = currentIndex + 1;
        continue;
      }

      atOrAfter = _observations[uint24(RingBuffer.nextIndex(currentIndex, _cardinality))];

      bool targetAtOrAfter = beforeOrAtTimestamp.lte(_target, _time);

      // Check if we've found the corresponding Observation
      if (targetAtOrAfter && _target.lte(atOrAfter.timestamp, _time)) {
        break;
      }

      // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower
      if (!targetAtOrAfter) rightSide = currentIndex - 1;

      // Otherwise, we keep searching higher
      else leftSide = currentIndex + 1;
    }
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/// @title OverflowSafeComparator library to share comparator functions between contracts
/// @dev Code taken from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/3e88af408132fc957e3e406f65a0ce2b1ca06c3d/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library OverflowSafeComparator {
    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically < `_b`.
    function lt(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a < _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted < bAdjusted;
    }

    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically <= `_b`.
    function lte(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a <= _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice 32-bit timestamp subtractor
    /// @dev safe for 0 or 1 overflows, where `_a` and `_b` must be chronologically before or equal to time
    /// @param _a The subtraction left operand
    /// @param _b The subtraction right operand
    /// @param _timestamp The current time.  Expected to be chronologically after both.
    /// @return The difference between a and b, adjusted for overflow
    function checkedSub(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (uint32) {
        // No need to adjust if there hasn't been an overflow

        if (_a <= _timestamp && _b <= _timestamp) return _a - _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return uint32(aAdjusted - bAdjusted);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

library RingBuffer {

  /// @notice Returns TWAB index.
  /// @dev `twabs` is a circular buffer of `MAX_CARDINALITY` size equal to 32. So the array goes from 0 to 31.
  /// @dev In order to navigate the circular buffer, we need to use the modulo operator.
  /// @dev For example, if `_index` is equal to 32, `_index % MAX_CARDINALITY` will return 0 and will point to the first element of the array.
  /// @param _index Index used to navigate through `twabs` circular buffer.
  function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
    return _index % _cardinality;
  }

  function offset(uint256 _index, uint256 _amount, uint256 _cardinality) internal pure returns (uint256) {
    return (_index + _cardinality - _amount) % _cardinality;
  }

  /// @notice Returns the index of the last recorded TWAB
  /// @param _nextAvailableIndex The next available twab index.  This will be recorded to next.
  /// @param _cardinality The cardinality of the TWAB history.
  /// @return The index of the last recorded TWAB
  function mostRecentIndex(uint256 _nextAvailableIndex, uint256 _cardinality) internal pure returns (uint256) {
    if (_cardinality == 0) {
      return 0;
    }
    return (_nextAvailableIndex + uint256(_cardinality) - 1) % _cardinality;
  }

  function nextIndex(uint256 _currentIndex, uint256 _cardinality) internal pure returns (uint256) {
    return (_currentIndex + 1) % _cardinality;
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./ExtendedSafeCast.sol";
import "./OverflowSafeComparator.sol";
import "./RingBuffer.sol";
import "./ObservationLib.sol";

/// @title Time-Weighted Average Balance Library
/// @notice This library allows you to efficiently track a user's historic balance.  You can get a
/// @author PoolTogether Inc.
library TwabLib {
  using OverflowSafeComparator for uint32;
  using ExtendedSafeCast for uint256;

  /// @notice The maximum number of twab entries
  uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

  /// @notice A struct containing details for an Account
  /// @param balance The current balance for an Account
  /// @param nextTwabIndex The next available index to store a new twab
  /// @param cardinality The upper limit on the number of twabs.
  struct AccountDetails {
    uint208 balance;
    uint24 nextTwabIndex;
    uint24 cardinality;
  }

  /// @notice Combines account details with their twab history
  /// @param details The account details
  /// @param twabs The history of twabs for this account
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[MAX_CARDINALITY] twabs;
  }

  /// @notice Increases an account's balance and records a new twab.
  /// @param _account The account whose balance will be increased
  /// @param _amount The amount to increase the balance by
  /// @param _currentTime The current time
  /// @return accountDetails The new AccountDetails
  /// @return twab The user's latest TWAB
  /// @return isNew Whether the TWAB is new
  function increaseBalance(
    Account storage _account,
    uint256 _amount,
    uint32 _currentTime
  ) internal returns (AccountDetails memory accountDetails, ObservationLib.Observation memory twab, bool isNew) {
    AccountDetails memory _accountDetails = _account.details;
    (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
    accountDetails.balance = (_accountDetails.balance + _amount).toUint208();
  }

  /// @notice Decreases an account's balance and records a new twab.
  /// @param _account The account whose balance will be decreased
  /// @param _amount The amount to decrease the balance by
  /// @param _revertMessage The revert message in the event of insufficient balance
  /// @return accountDetails The new AccountDetails
  /// @return twab The user's latest TWAB
  /// @return isNew Whether the TWAB is new
  function decreaseBalance(
    Account storage _account,
    uint256 _amount,
    string memory _revertMessage,
    uint32 _currentTime
  ) internal returns (AccountDetails memory accountDetails, ObservationLib.Observation memory twab, bool isNew) {
    AccountDetails memory _accountDetails = _account.details;
    require(_accountDetails.balance >= _amount, _revertMessage);
    (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
    accountDetails.balance = (_accountDetails.balance - _amount).toUint208();
  }

  /// @notice Calculates the average balance held by a user for a given time frame.
  /// @param _startTime The start time of the time frame.
  /// @param _endTime The end time of the time frame.
  /// @return The average balance that the user held during the time frame.
  function getAverageBalanceBetween(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _startTime,
    uint32 _endTime,
    uint32 _currentTime
  ) internal view returns (uint256) {
    uint32 endTime = _endTime > _currentTime ? _currentTime : _endTime;
    return _getAverageBalanceBetween(_twabs, _accountDetails, _startTime, endTime, _currentTime);
  }

  /// @notice Retrieves the oldest TWAB
  /// @param _twabs The storage array of twabs
  /// @param _accountDetails The TWAB account details
  /// @return index The index of the oldest TWAB in the twabs array
  /// @return twab The oldest TWAB
  function oldestTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails
  ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
    index = _accountDetails.nextTwabIndex;
    twab = _twabs[_accountDetails.nextTwabIndex];
    // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
    if (twab.timestamp == 0) {
      index = 0;
      twab = _twabs[0];
    }
  }

  /// @notice Retrieves the newest TWAB
  /// @param _twabs The storage array of twabs
  /// @param _accountDetails The TWAB account details
  /// @return index The index of the newest TWAB in the twabs array
  /// @return twab The newest TWAB
  function newestTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails
  ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
    index = uint24(RingBuffer.mostRecentIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
    twab = _twabs[index];
  }

  /// @notice Retrieves amount at `_target` timestamp
  /// @param _twabs List of TWABs to search through.
  /// @param _accountDetails Accounts details
  /// @param _target Timestamp at which the reserved TWAB should be for.
  /// @return uint256 TWAB amount at `_target`.
  function getBalanceAt(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _target,
    uint32 _currentTime
  ) internal view returns (uint256) {
    uint32 target = _target > _currentTime ? _currentTime : _target;
    return _getBalanceAt(_twabs, _accountDetails, target, _currentTime);
  }

  /// @notice Calculates the average balance held by a user for a given time frame.
  /// @param _startTime The start time of the time frame.
  /// @param _endTime The end time of the time frame.
  /// @return The average balance that the user held during the time frame.
  function _getAverageBalanceBetween(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _startTime,
    uint32 _endTime,
    uint32 _currentTime
  ) private view returns (uint256) {
    (uint24 oldestTwabIndex, ObservationLib.Observation memory oldTwab) = oldestTwab(_twabs, _accountDetails);
    (uint24 newestTwabIndex, ObservationLib.Observation memory newTwab) = newestTwab(_twabs, _accountDetails);

    ObservationLib.Observation memory startTwab = _calculateTwab(
      _twabs, _accountDetails, newTwab, oldTwab, newestTwabIndex, oldestTwabIndex, _startTime, _currentTime
    );

    ObservationLib.Observation memory endTwab = _calculateTwab(
      _twabs, _accountDetails, newTwab, oldTwab, newestTwabIndex, oldestTwabIndex, _endTime, _currentTime
    );

    // Difference in amount / time
    return (endTwab.amount - startTwab.amount) / (endTwab.timestamp - startTwab.timestamp);
  }

  /// @notice Retrieves amount at `_target` timestamp
  /// @param _twabs List of TWABs to search through.
  /// @param _accountDetails Accounts details
  /// @param _target Timestamp at which the reserved TWAB should be for.
  /// @return uint256 TWAB amount at `_target`.
  function _getBalanceAt(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _target,
    uint32 _currentTime
  ) private view returns (uint256) {
    uint24 newestTwabIndex;
    ObservationLib.Observation memory afterOrAt;
    ObservationLib.Observation memory beforeOrAt;
    (newestTwabIndex, beforeOrAt) = newestTwab(_twabs, _accountDetails);

    // If `_target` is chronologically after the newest TWAB, we can simply return the current balance
    if (beforeOrAt.timestamp.lte(_target, _currentTime)) {
      return _accountDetails.balance;
    }

    uint24 oldestTwabIndex;
    // Now, set before to the oldest TWAB
    (oldestTwabIndex, beforeOrAt) = oldestTwab(_twabs, _accountDetails);

    // If `_target` is chronologically before the oldest TWAB, we can early return
    if (_target.lt(beforeOrAt.timestamp, _currentTime)) {
      return 0;
    }

    // Otherwise, we perform the `binarySearch`
    (beforeOrAt, afterOrAt) = ObservationLib.binarySearch(
      _twabs,
      newestTwabIndex,
      oldestTwabIndex,
      _target,
      _accountDetails.cardinality,
      _currentTime
    );

    // Difference in amount / time
    uint224 differenceInAmount = afterOrAt.amount - beforeOrAt.amount;
    uint32 differenceInTime = afterOrAt.timestamp - beforeOrAt.timestamp;

    return differenceInAmount / differenceInTime;
  }

  /// @notice Calculates the TWAB for a given timestamp.  It interpolates as necessary.
  /// @param _twabs The TWAB history
  function _calculateTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    ObservationLib.Observation memory _newestTwab,
    ObservationLib.Observation memory _oldestTwab,
    uint24 _newestTwabIndex,
    uint24 _oldestTwabIndex,
    uint32 targetTimestamp,
    uint32 _time
  ) private view returns (ObservationLib.Observation memory) {
    // If `targetTimestamp` is chronologically after the newest TWAB, we extrapolate a new one
    if (_newestTwab.timestamp.lt(targetTimestamp, _time)) {
      return ObservationLib.Observation({
        amount: _newestTwab.amount + _accountDetails.balance*(targetTimestamp - _newestTwab.timestamp),
        timestamp: targetTimestamp
      });
    }

    if (_newestTwab.timestamp == targetTimestamp) {
      return _newestTwab;
    }

    if (_oldestTwab.timestamp == targetTimestamp) {
      return _oldestTwab;
    }

    // If `targetTimestamp` is chronologically before the oldest TWAB, we create a zero twab
    if (targetTimestamp.lt(_oldestTwab.timestamp, _time)) {
      return ObservationLib.Observation({
        amount: 0,
        timestamp: targetTimestamp
      });
    }

    // Otherwise, both timestamps must be surrounded by twabs.
    (
      ObservationLib.Observation memory beforeOrAtStart,
      ObservationLib.Observation memory afterOrAtStart
    ) = ObservationLib.binarySearch(_twabs, _newestTwabIndex, _oldestTwabIndex, targetTimestamp, _accountDetails.cardinality, _time);

    uint224 heldBalance = (afterOrAtStart.amount - beforeOrAtStart.amount) / (afterOrAtStart.timestamp - beforeOrAtStart.timestamp);
    uint224 amount = beforeOrAtStart.amount + heldBalance * (targetTimestamp - beforeOrAtStart.timestamp);

    return ObservationLib.Observation({
      amount: amount,
      timestamp: targetTimestamp
    });
  }

  /// @notice Records a new TWAB.
  /// @param _currentBalance Current `amount`.
  /// @return New TWAB that was recorded.
  function _computeNextTwab(
    ObservationLib.Observation memory _currentTwab,
    uint256 _currentBalance,
    uint32 _time
  ) private pure returns (ObservationLib.Observation memory) {
    // New twab amount = last twab amount (or zero) + (current amount * elapsed seconds)
    return ObservationLib.Observation({
      amount: (uint256(_currentTwab.amount) + (_currentBalance * (_time.checkedSub(_currentTwab.timestamp, _time)))).toUint208(),
      timestamp: _time
    });
  }

  /// @notice Sets a new TWAB Observation at the next available index and returns the new account details.
  /// @param _twabs The twabs array to insert into
  /// @param _accountDetails The current account details
  /// @param _time The current time
  /// @return accountDetails The new account details
  /// @return twab The newest twab (may or may not be brand-new)
  /// @return isNew Whether the newest twab was created by this call
  function _nextTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _time
  ) private returns (AccountDetails memory accountDetails, ObservationLib.Observation memory twab, bool isNew) {
    (, ObservationLib.Observation memory _newestTwab) = newestTwab(_twabs, _accountDetails);
    require(_time >= _newestTwab.timestamp, "TwabLib/twab-time-monotonic");

    // if we're in the same block, return
    if (_newestTwab.timestamp == _time) {
      return (_accountDetails, _newestTwab, false);
    }

    ObservationLib.Observation memory newTwab = _computeNextTwab(
      _newestTwab,
      _accountDetails.balance,
      _time
    );

    _twabs[_accountDetails.nextTwabIndex] = newTwab;

    _accountDetails.nextTwabIndex = uint24(RingBuffer.nextIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
    _accountDetails.cardinality += 1;

    return (_accountDetails, newTwab, true);
  }
}

