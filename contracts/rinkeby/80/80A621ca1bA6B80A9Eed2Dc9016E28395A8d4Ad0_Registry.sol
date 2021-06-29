// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./registry/Investment.sol";
import "./libs/TokenFormat.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title AllianceBlock Registry contract
 * @notice Responsible for investment transactions.
 * @dev Extends Initializable, Investment, OwnableUpgradeable
 */
contract Registry is Initializable, Investment, OwnableUpgradeable {
    using SafeMath for uint256;
    using TokenFormat for uint256;

    // Events
    event InvestmentStarted(uint256 indexed investmentId);
    event InvestmentApproved(uint256 indexed investmentId);
    event InvestmentRejected(uint256 indexed investmentId);

    /**
     * @notice Initialize
     * @dev Constructor of the contract.
     * @param escrowAddress address of the escrow contract
     * @param governanceAddress_ address of the DAO contract
     * @param lendingTokens_ addresses of the Lending Tokens
     * @param fundingNFT_ address of the Funding NFT
     * @param baseAmountForEachPartition_ The base amount for each partition
     */
    function initialize(
        address escrowAddress,
        address governanceAddress_,
        address[] memory lendingTokens_,
        address fundingNFT_,
        uint256 baseAmountForEachPartition_
    ) external initializer {
        require(escrowAddress != address(0), "Cannot initialize escrowAddress with 0 address");
        require(governanceAddress_ != address(0), "Cannot initialize governanceAddress_ with 0 address");
        require(fundingNFT_ != address(0), "Cannot initialize fundingNFT_ with 0 address");
        require(baseAmountForEachPartition_ != 0, "Cannot initialize baseAmountForEachPartition_ with 0");

        __Ownable_init();
        __Investment_init();

        escrow = IEscrow(escrowAddress);
        baseAmountForEachPartition = baseAmountForEachPartition_;
        governance = IGovernance(governanceAddress_);
        fundingNFT = IERC1155Mint(fundingNFT_);

        for (uint256 i = 0; i < lendingTokens_.length; i++) {
            require(lendingTokens_[i] != address(0), "Cannot initialize lendingToken_ with 0 address");
            isValidLendingToken[lendingTokens_[i]] = true;
        }
    }

    /**
     * @notice Initialize Investment
     * @dev This function is called by the owner to initialize the investment type.
     * @param reputationalAlbt The address of the rALBT contract.
     * @param totalTicketsPerRun_ The amount of tickets that will be provided from each run of the lottery.
     * @param rAlbtPerLotteryNumber_ The amount of rALBT needed to allocate one lucky number.
     * @param blocksLockedForReputation_ The amount of blocks needed for a ticket to be locked,
     *        so as investor to get 1 rALBT for locking it.
     */
    function initializeInvestment(
        address reputationalAlbt,
        uint256 totalTicketsPerRun_,
        uint256 rAlbtPerLotteryNumber_,
        uint256 blocksLockedForReputation_,
        uint256 lotteryNumbersForImmediateTicket_
    ) external onlyOwner() {
        require(reputationalAlbt != address(0), "Cannot initialize with 0 addresses");
        require(totalTicketsPerRun_ != 0 && rAlbtPerLotteryNumber_ != 0 && blocksLockedForReputation_ != 0 && lotteryNumbersForImmediateTicket_ != 0, "Cannot initialize with 0 values");
        require(address(rALBT) == address(0), "Cannot initialize second time");

        rALBT = IERC20(reputationalAlbt);
        totalTicketsPerRun = totalTicketsPerRun_;
        rAlbtPerLotteryNumber = rAlbtPerLotteryNumber_;
        blocksLockedForReputation = blocksLockedForReputation_;
        lotteryNumbersForImmediateTicket = lotteryNumbersForImmediateTicket_;
    }


    /**
     * @notice Update escrow address
     * @dev This function is called by the owner to update the escrow address
     * @param escrowAddress_ The address of escrow that will be updated.
     */
    function setEscrowAddress(
        address escrowAddress_
    ) external onlyOwner() {
        require(escrowAddress_ != address(0), "Cannot provide escrowAddress_ with 0 address");
        escrow = IEscrow(escrowAddress_);
    }

    /**
     * @notice Add lending token
     * @dev This function is called by the owner to add another lending token.
     * @param lendingToken_ The address of lending token that will be added.
     */
    function addLendingToken(
        address lendingToken_
    ) external onlyOwner() {
        require(lendingToken_ != address(0), "Cannot provide lendingToken_ with 0 address");
        require(!isValidLendingToken[lendingToken_], "Cannot add existing lending token");
        isValidLendingToken[lendingToken_] = true;
    }

    /**
     * @notice Decide For Investment
     * @dev This function is called by governance to approve or reject a investment request.
     * @param investmentId The id of the investment.
     * @param decision The decision of the governance. [true -> approved] [false -> rejected]
     */
    function decideForInvestment(uint256 investmentId, bool decision) external onlyGovernance() {
        if (decision) _approveInvestment(investmentId);
        else _rejectInvestment(investmentId);
    }

    /**
     * @notice Start Lottery Phase
     * @dev This function is called by governance to start the lottery phase for an investment.
     * @param investmentId The id of the investment.
     */
    function startLotteryPhase(uint256 investmentId) external onlyGovernance() {
        _startInvestment(investmentId);
    }

    /**
     * @notice Approve Investment
     * @param investmentId_ The id of the investment.
     */
    function _approveInvestment(uint256 investmentId_) internal {
        investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.APPROVED;
        investmentDetails[investmentId_].approvalDate = block.timestamp;
        ticketsRemaining[investmentId_] = investmentDetails[investmentId_].totalPartitionsToBePurchased;
        governance.storeInvestmentTriggering(investmentId_);
        emit InvestmentApproved(investmentId_);
    }

    /**
     * @notice Reject Investment
     * @param investmentId_ The id of the investment.
     */
    function _rejectInvestment(uint256 investmentId_) internal {
        investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.REJECTED;
        escrow.transferInvestmentToken(
            investmentDetails[investmentId_].investmentToken,
            investmentSeeker[investmentId_],
            investmentDetails[investmentId_].investmentTokensAmount
        );
        emit InvestmentRejected(investmentId_);
    }

    /**
     * @notice Start Investment
     * @param investmentId_ The id of the investment.
     */
    function _startInvestment(uint256 investmentId_) internal {
        investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.STARTED;
        investmentDetails[investmentId_].startingDate = block.timestamp;

        emit InvestmentStarted(investmentId_);
    }

    /**
     * @notice Get Investment Metadata
     * @dev This helper function provides a single point for querying the Investment metadata
     * @param investmentId The id of the investment.
     * @dev returns Investment Details, Investment Status, Investment Seeker Address and Repayment Batch Type
     */
    function getInvestmentMetadata(uint256 investmentId)
        public
        view
        returns (
            InvestmentLibrary.InvestmentDetails memory, // the investmentDetails
            InvestmentLibrary.InvestmentStatus, // the investmentStatus
            address // the investmentSeeker
        )
    {
        return (
            investmentDetails[investmentId],
            investmentStatus[investmentId],
            investmentSeeker[investmentId]
        );
    }

    /**
     * @notice IsValidReferralId
     * @param investmentId The id of the investment.
     * @dev returns true if investment id exists (so also seeker exists), otherwise returns false
     */
    function isValidReferralId(uint256 investmentId) external view returns (bool) {
        return investmentSeeker[investmentId] != address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the IERC1155 mint function.
 */
interface IERC1155Mint {
    function mintGen0(
        address to,
        uint256 amount,
        uint256 investmentId
    ) external;

    function mintOfGen(
        address to,
        uint256 amount,
        uint256 generation,
        uint256 investmentId
    ) external;

    function decreaseGenerations(
        uint256 tokenId,
        address user,
        uint256 amount,
        uint256 generationsToDecrease
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function pauseTokenTransfer(uint256 investmentId) external;

    function unpauseTokenTransfer(uint256 tokenId) external;

    function increaseGenerations(
        uint256 tokenId,
        address user,
        uint256 amount,
        uint256 generationsToAdd
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the Escrow.
 */
interface IEscrow {
    function receiveFunding(uint256 investmentId, uint256 amount) external;

    function transferFundingNFT(
        uint256 investmentId,
        uint256 partitionsPurchased,
        address receiver
    ) external;

    function transferLendingToken(
        address lendingToken,
        address seeker,
        uint256 amount
    ) external;

    function transferInvestmentToken(
        address investmentToken,
        address seeker,
        uint256 amount
    ) external;

    function mintReputationalToken(address recipient, uint256 amount) external;

    function burnReputationalToken(address from, uint256 amount) external;

    function multiMintReputationalToken(address[] memory recipients, uint256[] memory amounts) external;

    function burnFundingNFT(address account, uint256 investmentId, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the Governance contract.
 */
interface IGovernance {
    function requestApproval(
        uint256 investmentId
    ) external;

    function storeInvestmentTriggering(uint256 investmentId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

/**
 * @title Investment Library
 */
library InvestmentLibrary {
    enum InvestmentStatus {
        REQUESTED, // Status when investment has been requested, but not approved yet.
        APPROVED, // Status when investment has been approved from governors.
        STARTED, // Status when investment has been fully funded.
        SETTLED, // Status when investment has been fully repaid by the seeker.
        DEFAULT, // Status when seeker has not been able to repay the investment.
        REJECTED // Status when investment has been rejected by governors.
    }

    struct InvestmentDetails {
        uint256 investmentId; // The Id of the investment.
        uint256 approvalDate; // The timestamp in which investment was approved.
        uint256 startingDate; // The timestamp in which investment was funded.
        address investmentToken; // The address of the token that will be sold to investors.
        uint256 investmentTokensAmount; // The amount of investment tokens that are deposited for investors by the seeker.
        address lendingToken; // The address of the token that investors should pay with.
        uint256 totalAmountToBeRaised; // The amount of lending tokens that seeker of investment will raise after all tickets are purchased.
        uint256 totalPartitionsToBePurchased; // The total partitions or ERC1155 tokens, in which investment is splitted.
        string extraInfo; // The ipfs hash, where all extra info about the investment are stored.
        uint256 partitionsRequested; // The total partitions or ERC1155 tokens that are requested for purchase.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

/**
 * @title The Token Format library
 */
library TokenFormat {
    // Use a split bit implementation.
    // Store the generation in the upper 128 bits..
    // ..and the non-fungible investment id in the lower 128
    uint256 private constant _INVESTMENT_ID_MASK = uint128(~0);

    /**
     * @notice Format tokenId into generation and index
     * @param tokenId The Id of the token
     * @return generation
     * @return investmentId
     */
    function formatTokenId(uint256 tokenId) internal pure returns (uint256 generation, uint256 investmentId) {
        generation = tokenId >> 128;
        investmentId = tokenId & _INVESTMENT_ID_MASK;
    }

    /**
     * @notice get tokenId from generation and investmentId
     * @param gen the generation
     * @param investmentId the investmentID
     * @return tokenId the token id
     */
    function getTokenId(uint256 gen, uint256 investmentId) internal pure returns (uint256 tokenId) {
        return (gen << 128) | investmentId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./InvestmentDetails.sol";
import "../libs/SafeERC20.sol";
import "../libs/TokenFormat.sol";

/**
 * @title AllianceBlock Investment contract.
 * @notice Functionality for Investment.
 * @dev Extends InvestmentDetails.
 */
contract Investment is Initializable, InvestmentDetails, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using TokenFormat for uint256;
    using SafeERC20 for IERC20;

    // EVENTS
    event InvestmentRequested(uint256 indexed investmentId, address indexed user, uint256 amount);
    event InvestmentInterest(uint256 indexed investmentId, uint amount);
    event LotteryExecuted(uint256 indexed investmentId);
    event WithdrawInvestment(uint256 indexed investmentId, uint256 ticketsToLock, uint256 ticketsToWithdraw);
    event WithdrawAmountForNonTickets(uint256 indexedinvestmentId, uint256 amountToReturnForNonWonTickets);
    event WithdrawLockedInvestmentTickets(uint256 indexedinvestmentId, uint256 ticketsToWithdraw);
    event ConvertNFTToInvestmentTokens(uint256 indexedinvestmentId, uint256 amountOfNFTToConvert, uint256 amountOfInvestmentTokenToTransfer);
    event InvestmentSettled(uint256 investmentId);

    function __Investment_init() public initializer {
        __ReentrancyGuard_init();
    }

    /**
     * @notice Requests investment
     * @dev This function is used for seekers to request investment in exchange for investment tokens.
     * @dev require valid amount
     * @param investmentToken The token that will be purchased by investors.
     * @param amountOfInvestmentTokens The amount of investment tokens to be purchased.
     * @param investmentToken The token that investors will pay with.
     * @param totalAmountRequested_ The total amount requested so as all investment tokens to be sold.
     * @param extraInfo The ipfs hash where more specific details for investment request are stored.
     */
    function requestInvestment(
        address investmentToken,
        uint256 amountOfInvestmentTokens,
        address lendingToken,
        uint256 totalAmountRequested_,
        string memory extraInfo
    ) external nonReentrant() {
        require(isValidLendingToken[lendingToken], "Lending token not supported");

        uint256 investmentDecimals = IERC20(investmentToken).decimals();
        uint256 lendingDecimals = IERC20(lendingToken).decimals();
        uint256 power = investmentDecimals.mul(2).sub(lendingDecimals);

        require(
            totalAmountRequested_.mod(baseAmountForEachPartition) == 0 &&
                totalAmountRequested_.mul(10**power).mod(amountOfInvestmentTokens) == 0,
            "Token amount and price should result in integer amount of tickets"
        );

        _storeInvestmentDetails(
            lendingToken,
            totalAmountRequested_,
            investmentToken,
            amountOfInvestmentTokens,
            extraInfo
        );

        IERC20(investmentToken).safeTransferFrom(msg.sender, address(escrow), amountOfInvestmentTokens);

        fundingNFT.mintGen0(address(escrow), investmentDetails[totalInvestments].totalPartitionsToBePurchased, totalInvestments);

        investmentTokensPerTicket[totalInvestments] = amountOfInvestmentTokens.div(investmentDetails[totalInvestments].totalPartitionsToBePurchased);

        fundingNFT.pauseTokenTransfer(totalInvestments); //Pause trades for ERC1155s with the specific investment ID.

        governance.requestApproval(totalInvestments);

        // Add event for investment request
        emit InvestmentRequested(totalInvestments, msg.sender, totalAmountRequested_);

        totalInvestments = totalInvestments.add(1);
    }

    /**
     * @notice user show interest for investment
     * @dev This function is called by the investors who are interested to invest in a specific investment token.
     * @dev require Approval state and valid partition
     * @param investmentId The id of the investment.
     * @param amountOfPartitions The amount of partitions this specific investor wanna invest in.
     */
    function showInterestForInvestment(uint256 investmentId, uint256 amountOfPartitions) external  nonReentrant() {
        require(
            investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.APPROVED,
            "Can show interest only in Approved state"
        );
        require(amountOfPartitions > 0, "Cannot show interest for 0 partitions");

        IERC20(investmentDetails[investmentId].lendingToken).safeTransferFrom(
            msg.sender, address(escrow), amountOfPartitions.mul(baseAmountForEachPartition)
        );

        investmentDetails[investmentId].partitionsRequested = investmentDetails[investmentId].partitionsRequested.add(
            amountOfPartitions
        );

        // if it's not the first time calling the function lucky numbers are not provided again.
        if (remainingTicketsPerAddress[investmentId][msg.sender] > 0 || ticketsWonPerAddress[investmentId][msg.sender] > 0) {
            remainingTicketsPerAddress[investmentId][msg.sender] =
                remainingTicketsPerAddress[investmentId][msg.sender].add(amountOfPartitions);
        }
        else {
            _applyImmediateTicketsAndProvideLuckyNumbers(investmentId, amountOfPartitions);
        }

        // Add event for investment interest
        emit InvestmentInterest(investmentId, amountOfPartitions);

    }

    function _applyImmediateTicketsAndProvideLuckyNumbers(uint256 investmentId_, uint256 amountOfPartitions_) internal {
        uint256 reputationalBalance = _updateReputationalBalanceForPreviouslyLockedTokens();
        uint256 totalLotteryNumbers = reputationalBalance.div(rAlbtPerLotteryNumber);

        if (totalLotteryNumbers == 0) revert("Not eligible for lottery numbers");

        uint256 immediateTickets = 0;

        if (totalLotteryNumbers > lotteryNumbersForImmediateTicket) {
            uint256 rest = totalLotteryNumbers.mod(lotteryNumbersForImmediateTicket);
            immediateTickets = totalLotteryNumbers.sub(rest).div(lotteryNumbersForImmediateTicket);
            totalLotteryNumbers = rest;
        }

        if (immediateTickets > amountOfPartitions_) immediateTickets = amountOfPartitions_;

        if (immediateTickets > 0) {
            // Just in case we provided immediate tickets and tickets finished, so there is no lottery in this case.
            if (immediateTickets >= ticketsRemaining[investmentId_]) {
                immediateTickets = ticketsRemaining[investmentId_];
                investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.SETTLED;
            }

            ticketsWonPerAddress[investmentId_][msg.sender] = immediateTickets;
            ticketsRemaining[investmentId_] = ticketsRemaining[investmentId_].sub(immediateTickets);
        }

        remainingTicketsPerAddress[investmentId_][msg.sender] = amountOfPartitions_.sub(immediateTickets);

        uint256 maxLotteryNumber = totalLotteryNumbersPerInvestment[investmentId_].add(totalLotteryNumbers);

        for (uint256 i = totalLotteryNumbersPerInvestment[investmentId_].add(1); i <= maxLotteryNumber; i++) {
            addressOfLotteryNumber[investmentId_][i] = msg.sender;
        }

        totalLotteryNumbersPerInvestment[investmentId_] = maxLotteryNumber;
    }

    /**
     * @notice Executes lottery run
     * @dev This function is called by any investor interested in an Investment Token to run part of the lottery.
     * @dev requires Started state and available tickets
     * @param investmentId The id of the investment.
     */
    function executeLotteryRun(uint256 investmentId) external {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.STARTED, "Can run lottery only in Started state");
        require(
            remainingTicketsPerAddress[investmentId][msg.sender] > 0,
            "Can run lottery only if has remaining ticket"
        );

        ticketsWonPerAddress[investmentId][msg.sender] = ticketsWonPerAddress[investmentId][msg.sender].add(1);
        remainingTicketsPerAddress[investmentId][msg.sender] = remainingTicketsPerAddress[investmentId][msg.sender].sub(
            1
        );
        ticketsRemaining[investmentId] = ticketsRemaining[investmentId].sub(1);

        uint256 counter = totalTicketsPerRun;
        uint256 maxNumber = totalLotteryNumbersPerInvestment[investmentId];

        if (ticketsRemaining[investmentId] <= counter) {
            investmentStatus[investmentId] = InvestmentLibrary.InvestmentStatus.SETTLED;
            counter = ticketsRemaining[investmentId];
            ticketsRemaining[investmentId] = 0;
            fundingNFT.unpauseTokenTransfer(investmentId); // UnPause trades for ERC1155s with the specific investment ID.
            emit InvestmentSettled(investmentId);

        } else {
            ticketsRemaining[investmentId] = ticketsRemaining[investmentId].sub(counter);
        }

        while (counter > 0) {
            uint256 randomNumber = _getRandomNumber(maxNumber);
            lotteryNonce = lotteryNonce.add(1);

            address randomAddress = addressOfLotteryNumber[investmentId][randomNumber.add(1)];

            if (remainingTicketsPerAddress[investmentId][randomAddress] > 0) {
                remainingTicketsPerAddress[investmentId][randomAddress] = remainingTicketsPerAddress[investmentId][
                    randomAddress
                ]
                    .sub(1);

                ticketsWonPerAddress[investmentId][randomAddress] = ticketsWonPerAddress[investmentId][randomAddress]
                    .add(1);

                counter--;
            }
        }

        // Add event for lottery executed
        emit LotteryExecuted(investmentId);
    }

    /**
     * @notice Withdraw Investment Tickets
     * @dev This function is called by an investor to withdraw his tickets.
     * @dev require Settled state and enough tickets won
     * @param investmentId The id of the investment.
     * @param ticketsToLock The amount of won tickets to be locked, so as to get more rALBT.
     * @param ticketsToWithdraw The amount of won tickets to be withdrawn instantly.
     */
    function withdrawInvestmentTickets(
        uint256 investmentId,
        uint256 ticketsToLock,
        uint256 ticketsToWithdraw
    ) external  nonReentrant() {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(
            ticketsWonPerAddress[investmentId][msg.sender] > 0 &&
                ticketsWonPerAddress[investmentId][msg.sender] >= ticketsToLock.add(ticketsToWithdraw),
            "Not enough tickets won"
        );

        ticketsWonPerAddress[investmentId][msg.sender] = ticketsWonPerAddress[investmentId][msg.sender]
            .sub(ticketsToLock)
            .sub(ticketsToWithdraw);

        _updateReputationalBalanceForPreviouslyLockedTokens();

        if (ticketsToLock > 0) {
            lockedTicketsForSpecificInvestmentPerAddress[investmentId][
                msg.sender
            ] = lockedTicketsForSpecificInvestmentPerAddress[investmentId][msg.sender].add(ticketsToLock);

            lockedTicketsPerAddress[msg.sender] = lockedTicketsPerAddress[msg.sender].add(ticketsToLock);
        }

        if (ticketsToWithdraw > 0) {
            escrow.transferFundingNFT(investmentId, ticketsToWithdraw, msg.sender);
        }

        if (remainingTicketsPerAddress[investmentId][msg.sender] > 0) {
            _withdrawAmountProvidedForNonWonTickets(investmentId);
        }

        // Add event for withdraw investment
        emit WithdrawInvestment(investmentId, ticketsToLock, ticketsToWithdraw);
    }

    /**
     * @dev This function is called by an investor to withdraw lending tokens provided for non-won tickets.
     * @param investmentId The id of the investment.
     */
    function withdrawAmountProvidedForNonWonTickets(uint256 investmentId) external nonReentrant() {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(remainingTicketsPerAddress[investmentId][msg.sender] > 0, "No non-won tickets to withdraw");

        _withdrawAmountProvidedForNonWonTickets(investmentId);
    }

    /**
     * @notice Withdraw locked investment ticket.
     * @dev This function is called by an investor to withdraw his locked tickets.
     * @dev requires Settled state and available tickets.
     * @param investmentId The id of the investment.
     * @param ticketsToWithdraw The amount of locked tickets to be withdrawn.
     */
    function withdrawLockedInvestmentTickets(uint256 investmentId, uint256 ticketsToWithdraw) external nonReentrant() {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(
            ticketsToWithdraw > 0 &&
                lockedTicketsForSpecificInvestmentPerAddress[investmentId][msg.sender] >= ticketsToWithdraw,
            "Not enough tickets to withdraw"
        );

        _updateReputationalBalanceForPreviouslyLockedTokens();

        lockedTicketsForSpecificInvestmentPerAddress[investmentId][
            msg.sender
        ] = lockedTicketsForSpecificInvestmentPerAddress[investmentId][msg.sender].sub(ticketsToWithdraw);

        lockedTicketsPerAddress[msg.sender] = lockedTicketsPerAddress[msg.sender].sub(ticketsToWithdraw);

        escrow.transferFundingNFT(investmentId, ticketsToWithdraw, msg.sender);

        // Add event for withdraw locked investment tickets
        emit WithdrawLockedInvestmentTickets(investmentId, ticketsToWithdraw);
    }

    /**
     * @notice Gets Requesting status
     * @dev Returns true if investors have shown interest for equal or more than the total tickets.
     * @param investmentId The id of the investment type to be checked.
     */
    function getRequestingInterestStatus(uint256 investmentId) external view returns (bool) {
        return investmentDetails[investmentId].totalPartitionsToBePurchased <= investmentDetails[investmentId].partitionsRequested;
    }

    /**
     * @notice Generates Random Number
     * @dev This function generates a random number
     * @param maxNumber the max number possible
     * @return randomNumber the random number generated
     */
    function _getRandomNumber(uint256 maxNumber) internal view returns (uint256 randomNumber) {
        randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, lotteryNonce, blockhash(block.number), msg.sender)
            )
        )
            .mod(maxNumber);
    }

    /**
     * @notice Updates reputation balance
     * @dev updates balance of reputation for locked tokens
     * @return the reputation balance of msg.sender
     */
    function _updateReputationalBalanceForPreviouslyLockedTokens() internal returns (uint256) {
        if (lockedTicketsPerAddress[msg.sender] > 0) {
            // Decimals for rALBT => 18
            uint256 amountOfReputationalAlbtPerTicket =
                (block.number.sub(lastBlockCheckedForLockedTicketsPerAddress[msg.sender])).mul(10**18).div(
                    blocksLockedForReputation
                );

            uint256 amountOfReputationalAlbtToMint =
                amountOfReputationalAlbtPerTicket.mul(lockedTicketsPerAddress[msg.sender]);

            escrow.mintReputationalToken(msg.sender, amountOfReputationalAlbtToMint);

            lastBlockCheckedForLockedTicketsPerAddress[msg.sender] = block.number;
        }

        return rALBT.balanceOf(msg.sender);
    }

    function _withdrawAmountProvidedForNonWonTickets(uint256 investmentId_) internal {
        uint256 amountToReturnForNonWonTickets =
            remainingTicketsPerAddress[investmentId_][msg.sender].mul(baseAmountForEachPartition);
        remainingTicketsPerAddress[investmentId_][msg.sender] = 0;

        escrow.transferLendingToken(investmentDetails[investmentId_].lendingToken, msg.sender, amountToReturnForNonWonTickets);

        // Add event for withdraw amount provided for non tickets
        emit WithdrawAmountForNonTickets(investmentId_, amountToReturnForNonWonTickets);
    }

    /**
     * @notice Convert NFT to investment tokens
     * @param investmentId the investmentId
     * @param amountOfNFTToConvert the amount of nft to convert
     */
    function convertNFTToInvestmentTokens (uint256 investmentId, uint256 amountOfNFTToConvert) external {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(amountOfNFTToConvert != 0, "Amount of nft to convert cannot be 0");
        require(amountOfNFTToConvert <= fundingNFT.balanceOf(msg.sender, investmentId), "Not enough NFT to convert");

        uint256 amountOfInvestmentTokenToTransfer = investmentTokensPerTicket[investmentId].mul(amountOfNFTToConvert);

        escrow.burnFundingNFT(msg.sender, investmentId, amountOfNFTToConvert);
        escrow.transferInvestmentToken(investmentDetails[investmentId].investmentToken, msg.sender, amountOfInvestmentTokenToTransfer);

        // Add event for convert nft to investment tokens
        emit ConvertNFTToInvestmentTokens(investmentId, amountOfNFTToConvert, amountOfInvestmentTokenToTransfer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Storage.sol";
import "../libs/TokenFormat.sol";

/**
 * @title AllianceBlock InvestmentDetails contract
 * @notice Functionality for storing investment details and modifiers.
 * @dev Extends Storage
 */
contract InvestmentDetails is Storage {
    using SafeMath for uint256;
    using TokenFormat for uint256;

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "Only Governance");
        _;
    }

    /**
     * @notice Stores Investment Details
     * @dev require a valid interest percentage
     * @param amountRequestedToBeRaised_ the amount requested
     * @param investmentToken_ the investment token address
     * @param investmentTokensAmount_ the amount of investment tokens provided by the seeker
     * @param extraInfo_ the IPFS hard data provided
     */
    function _storeInvestmentDetails(
        address lendingToken_,
        uint256 amountRequestedToBeRaised_,
        address investmentToken_,
        uint256 investmentTokensAmount_,
        string memory extraInfo_
    ) internal {
        InvestmentLibrary.InvestmentDetails memory investment;
        investment.investmentId = totalInvestments;
        investment.investmentToken = investmentToken_;
        investment.investmentTokensAmount = investmentTokensAmount_;
        investment.totalAmountToBeRaised = amountRequestedToBeRaised_;
        investment.extraInfo = extraInfo_;
        investment.totalPartitionsToBePurchased = amountRequestedToBeRaised_.div(baseAmountForEachPartition);
        investment.lendingToken = lendingToken_;

        investmentDetails[totalInvestments] = investment;

        investmentStatus[totalInvestments] = InvestmentLibrary.InvestmentStatus.REQUESTED;
        investmentSeeker[totalInvestments] = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../libs/InvestmentLibrary.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155Mint.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IEscrow.sol";

/**
 * @title AllianceBlock Storage contract
 * @notice Responsible for investment storage
 */
contract Storage {
    uint256 public totalInvestments; // The total amount of investment requests.

    // Mapping from investment id -> details for each and every investment.
    mapping(uint256 => InvestmentLibrary.InvestmentDetails) public investmentDetails;
    // Mapping from investment id -> investment status.
    mapping(uint256 => InvestmentLibrary.InvestmentStatus) public investmentStatus;
    // Mapping from investment id -> investment seeker's address.
    mapping(uint256 => address) public investmentSeeker;
    // The amount of investment tokens each ticket contains.
    mapping(uint256 => uint256) public investmentTokensPerTicket;
    // The amount of tickets remaining to be allocated to investors.
    mapping(uint256 => uint256) public ticketsRemaining;
    // The number lottery numbers allocated from all investors for a specific investment.
    mapping(uint256 => uint256) public totalLotteryNumbersPerInvestment;
    // The address of the investor that has allocated a specific lottery number on a specific investment.
    mapping(uint256 => mapping(uint256 => address)) public addressOfLotteryNumber;
    // The amount of tickets that an investor requested that are still not allocated.
    mapping(uint256 => mapping(address => uint256)) public remainingTicketsPerAddress;
    // The amount of tickets that an investor requested that have been won already.
    mapping(uint256 => mapping(address => uint256)) public ticketsWonPerAddress;
    // The amount of tickets that an investor locked for a specific investment.
    mapping(uint256 => mapping(address => uint256)) public lockedTicketsForSpecificInvestmentPerAddress;
    // The amount of tickets that an investor locked from all investments.
    mapping(address => uint256) public lockedTicketsPerAddress;
    // The last block checked for rewards for the tickets locked per address.
    mapping(address => uint256) public lastBlockCheckedForLockedTicketsPerAddress;
    // All supported lending tokens are giving true, while unsupported are giving false.
    mapping(address => bool) public isValidLendingToken;

    IGovernance public governance; // Governance's contract address.
    IERC1155Mint public fundingNFT; // Funding nft's contract address.
    IEscrow public escrow; // Escrow's contract address.
    IERC20 public rALBT; // rALBT's contract address.

    // This variable represents the base amount in which every investment amount is divided to. (also the starting value for each ERC1155)
    uint256 public baseAmountForEachPartition;
    // The amount of tickets to be provided by each run of the lottery.
    uint256 public totalTicketsPerRun;
    // The amount of rALBT needed to allocate one lottery number.
    uint256 public rAlbtPerLotteryNumber;
    // The amount of blocks needed for a ticket to be locked, so as the investor to get 1 rALBT.
    uint256 public blocksLockedForReputation;
    // The amount of lottery numbers, that if investor has after number allocation he gets one ticket without lottery.
    uint256 public lotteryNumbersForImmediateTicket;
    // The nonce for the lottery numbers.
    uint256 internal lotteryNonce;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}