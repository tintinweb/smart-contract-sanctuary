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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.7.0;

import "./governance/SuperGovernance.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title AllianceBlock Governance contract
 * @dev Extends Initializable, SuperGovernance
 * @notice Responsible for governing AllianceBlock's ecosystem
 */
contract Governance is Initializable, SuperGovernance {
    using SafeMath for uint256;
    using DoubleLinkedList for DoubleLinkedList.LinkedList;

    /**
     * @notice Initialize the contract.
     * @param superDelegator_ The address of the admin in charge during the first epoch
     * @param applicationsForInvestmentDuration_ duration for applications for investment
     * @param lateApplicationsForInvestmentDuration_ duration forlate applications for investment
     */
    function initialize(
        address superDelegator_,
        uint256 applicationsForInvestmentDuration_,
        uint256 lateApplicationsForInvestmentDuration_
    ) external initializer {
        require(superDelegator_ != address(0), "Cannot initialize with 0 addresses");
        require(applicationsForInvestmentDuration_ != 0, "Cannot initialize applicationsForInvestmentDuration_ with 0");
        require(lateApplicationsForInvestmentDuration_ != 0, "Cannot initialize lateApplicationsForInvestmentDuration_ with 0");

        __SuperGovernance_init();

        superDelegator = superDelegator_;

        updatableVariables[
            keccak256(abi.encode("applicationsForInvestmentDuration"))
        ] = applicationsForInvestmentDuration_;
        updatableVariables[
            keccak256(abi.encode("lateApplicationsForInvestmentDuration"))
        ] = lateApplicationsForInvestmentDuration_;
    }

    /**
     * @notice Update Superdelegator
     * @dev This function is used to update the superDelegator address.
     * @param superDelegator_ The address of the upgraded super delegator.
     */
    function updateSuperDelegator(address superDelegator_) external onlyOwner() {
        require(superDelegator_ != address(0), "Cannot initialize with 0 addresses");
        superDelegator = superDelegator_;
    }

    /**
     * @notice Request a investment or investment approval
     * @dev Executes cronJob()
     * @param investmentId The id of the investment or investment to approve
     */
    function requestApproval(
        uint256 investmentId
    ) external onlyRegistry() checkCronjob() nonReentrant() {
        approvalRequests[totalApprovalRequests].investmentId = investmentId;

        emit ApprovalRequested(
            approvalRequests[totalApprovalRequests].investmentId,
            msg.sender
        );

        totalApprovalRequests = totalApprovalRequests.add(1);
    }

    /**
     * @notice Stores Investment Duration
     * @dev Adds cronJob
     * @param investmentId The id of the investment to store
     */
    function storeInvestmentTriggering(uint256 investmentId) external onlyRegistry() {
        uint256 nextCronjobTimestamp =
            block.timestamp.add(updatableVariables[keccak256(abi.encode("applicationsForInvestmentDuration"))]);
        addCronjob(CronjobType.INVESTMENT, nextCronjobTimestamp, investmentId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GovernanceTypesAndStorage.sol";
import "../interfaces/IRegistry.sol";

/**
 * @title AllianceBlock Governance contract
 * @dev Extends GovernanceTypesAndStorage
 * @notice Responsible for governing AllianceBlock's ecosystem
 */
contract DaoCronjob is GovernanceTypesAndStorage {
    using SafeMath for uint256;
    using ValuedDoubleLinkedList for ValuedDoubleLinkedList.LinkedList;
    using DoubleLinkedList for DoubleLinkedList.LinkedList;

    modifier checkCronjob() {
        checkCronjobs();
        _;
    }

    /**
     * @notice Checks if needs to execute a DAO cronJob
     * @dev Calls executeCronjob() at the most 1 cronJob per tx
     */
    function checkCronjobs() public returns (bool) {
        uint256 mostRecentCronjobTimestamp = cronjobList.getHeadValue();
        if (mostRecentCronjobTimestamp == 0 || block.timestamp < mostRecentCronjobTimestamp) return false;
        else {
            // only pop head for now for gas reasons, maybe later we can execute them all together.
            (uint256 head, uint256 timestamp) = cronjobList.popHeadAndValue();
            executeCronjob(head, timestamp);
        }

        return true;
    }

    /**
     * @notice Executes the next DAO cronJob
     * @param cronjobId The cronJob id to be executed.
     * @param timestamp The current block height
     */
    function executeCronjob(uint256 cronjobId, uint256 timestamp) internal {
        updateInvestment(cronjobs[cronjobId].externalId, timestamp);
    }

    /**
     * @notice Adds a cronJob to the queue
     * @dev Adds a node to the cronjobList (ValuedDoubleLinkedList)
     * @param cronjobType The type of cronJob
     * @param timestamp The current block height
     * @param externalId Id of the request in case of dao approval, change voting request or investment
     */
    function addCronjob(
        CronjobType cronjobType,
        uint256 timestamp,
        uint256 externalId
    ) internal {
        totalCronjobs = totalCronjobs.add(1);
        cronjobs[totalCronjobs] = Cronjob(cronjobType, externalId);
        cronjobList.addNodeIncrement(timestamp, totalCronjobs);
    }

    /**
     * @notice Updates an investment
     * @dev checks if lottery should start or adds cronJob for late application
     * @param investmentId The id of the investment to update
     * @param timestamp the current block height
     */
    function updateInvestment(uint256 investmentId, uint256 timestamp) internal {
        if (registry.getRequestingInterestStatus(investmentId)) {
            registry.startLotteryPhase(investmentId);
        } else {
            uint256 nextCronjobTimestamp =
                timestamp.add(updatableVariables[keccak256(abi.encode("lateApplicationsForInvestmentDuration"))]);
            addCronjob(CronjobType.INVESTMENT, nextCronjobTimestamp, investmentId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IRegistry.sol";
import "../libs/ValuedDoubleLinkedList.sol";
import "../libs/DoubleLinkedList.sol";

/**
 * @title AllianceBlock GovernanceStorage contract
 * @notice Responsible for governance storage
 */
contract GovernanceTypesAndStorage {
    using ValuedDoubleLinkedList for ValuedDoubleLinkedList.LinkedList;
    using DoubleLinkedList for DoubleLinkedList.LinkedList;

    struct ApprovalRequest {
        uint256 investmentId; // The investment id for which approcal is requested.
        uint256 approvalsProvided; // The number of approvals that this request has gathered.
        bool isApproved; // True if request is approved, false if not.
    }

    // EVENTS
    event VotedForRequest(uint256 indexed investmentId, uint256 indexed requestId, bool decision, address indexed user);
    event ApprovalRequested(
        uint256 indexed investmentId,
        address indexed user
    );
    event InitGovernance(address indexed registryAddress_, address indexed user);

    uint256 public totalApprovalRequests; // The total amount of approvals requested.

    address public superDelegator;

    mapping(uint256 => ApprovalRequest) public approvalRequests;

    IRegistry public registry;

    uint256 public totalIds;

    mapping(bytes32 => uint256) public updatableVariables;

    // CRONJOB types and variables
    enum CronjobType {
        INVESTMENT // Cronjob type for users to show interest for an investment.
    }

    struct Cronjob {
        CronjobType cronjobType; // This is the cronjob type.
        uint256 externalId; // This is the id of the request in case of dao approval, change voting request or investment.
    }

    // TODO - Make this simple linked list, not double (we don't need to remove anything else than head MAYBE).
    ValuedDoubleLinkedList.LinkedList public cronjobList;
    uint256 public totalCronjobs;

    mapping(uint256 => Cronjob) public cronjobs; // cronjobId to Cronjob.

    // MODIFIERS

    modifier onlyRegistry() {
        require(msg.sender == address(registry), "Only Registry contract");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./DaoCronjob.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title AllianceBlock Governance contract
 * @dev Extends OwnableUpgradeable, DaoCronjob
 * @notice Responsible for govern AllianceBlock's ecosystem
 */
contract SuperGovernance is Initializable, OwnableUpgradeable, DaoCronjob, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    function __SuperGovernance_init() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Sets Registry contract
     * @dev used to initialize SuperGovernance
     * @dev requires not already initialized
     * @param registryAddress_ the Registry address
     */
    function setRegistry(address registryAddress_) external onlyOwner() {
        require(registryAddress_ != address(0), "Cannot initialize with 0 addresses");
        require(address(registry) == address(0), "Cannot initialize second time");
        registry = IRegistry(registryAddress_);

        emit InitGovernance(registryAddress_, msg.sender);
    }

    /**
     * @notice Votes for Request
     * @dev Executes cronJob
     * @dev requires msg.sender to be Super Delegator
     * @dev requires current epoch to be 0 or 1
     * @param requestId the Request ID
     * @param decision the decision (Approve / Deny)
     */
    function superVoteForRequest(uint256 requestId, bool decision) external checkCronjob() nonReentrant() {
        require(msg.sender == superDelegator, "Only super delegator can call this function");
        require(approvalRequests[requestId].approvalsProvided == 0, "Cannot approve again same investment");

        registry.decideForInvestment(approvalRequests[requestId].investmentId, decision);

        if (decision) {
            approvalRequests[requestId].approvalsProvided = approvalRequests[requestId].approvalsProvided.add(1);
            approvalRequests[requestId].isApproved = true;
        }

        emit VotedForRequest(approvalRequests[requestId].investmentId, requestId, decision, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the Registry contract.
 */
interface IRegistry {
    function decideForInvestment(uint256 investmentId, bool decision) external;

    function getRequestingInterestStatus(uint256 investmentId) external view returns (bool);

    function startLotteryPhase(uint256 investmentId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the Staking contract.
 */
interface IStaking {
    function getBalance(address staker_) external view returns (uint256);

    function getAmountsToStake()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getEligibilityForActionProvision(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Double linked-list
 */
library DoubleLinkedList {
    struct Node {
        uint256 next;
        uint256 previous;
    }

    struct LinkedList {
        uint256 head;
        uint256 tail;
        uint256 size;
        mapping(uint256 => Node) nodes;
    }

    /**
     * @notice Get Head ID
     * @param self the LinkedList
     * @return the first item of the list
     */
    function getHeadId(LinkedList storage self) internal view returns (uint256) {
        return self.head;
    }

    /**
     * @notice Get list size
     * @param self the LinkedList
     * @return the size of the list
     */
    function getSize(LinkedList storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @notice Adds a new node to the list
     * @param self the LinkedList
     * @param id the node to add
     */
    function addNode(LinkedList storage self, uint256 id) internal {
        //If empty
        if (self.head == 0) {
            self.head = id;
            self.tail = id;
            self.nodes[id] = Node(0, 0);
        }
        //Else push in tail
        else {
            self.nodes[self.tail].next = id;
            self.nodes[id] = Node(0, self.tail);
            self.tail = id;
        }

        self.size += 1;
    }

    /**
     * @notice Removes node from the list
     * @param self the LinkedList
     * @param id the id of the node to remove
     */
    function removeNode(LinkedList storage self, uint256 id) internal {
        if (self.size == 1) {
            self.head = 0;
            self.tail = 0;
        } else if (id == self.head) {
            self.head = self.nodes[self.head].next;
            self.nodes[self.head].previous = 0;
        } else if (id == self.tail) {
            self.tail = self.nodes[self.tail].previous;
            self.nodes[self.tail].next = 0;
        } else {
            self.nodes[self.nodes[id].next].previous = self.nodes[id].previous;
            self.nodes[self.nodes[id].previous].next = self.nodes[id].next;
        }

        self.size -= 1;
    }

    /**
     * @notice Pops the head of the list
     * @param self the LinkedList
     * @return head the first item of the list
     */
    function popHead(LinkedList storage self) internal returns (uint256 head) {
        head = self.head;

        if (self.size == 1) {
            self.head = 0;
            self.tail = 0;
        } else {
            self.head = self.nodes[self.head].next;
            self.nodes[self.head].previous = 0;
        }

        self.size -= 1;
    }

    /**
     * @notice Get id by index
     * @param self the LinkedList
     * @param index the id of the index
     * @return id the item in index position
     */
    function getIndexedId(LinkedList storage self, uint256 index) internal view returns (uint256 id) {
        id = self.head;

        for (uint256 i = 1; i < index; i++) {
            id = self.nodes[id].next;
        }
    }

    /**
     * @notice Clone LinkedList
     * @param self the LinkedList
     * @param listToClone the LinkedList storage to clone the list from
     */
    function cloneList(LinkedList storage self, LinkedList storage listToClone) internal {
        self.head = listToClone.head;
        self.tail = listToClone.tail;
        self.size = listToClone.size;

        uint256 id = listToClone.head;

        for (uint256 i = 0; i < listToClone.size; i++) {
            self.nodes[id] = listToClone.nodes[id];
            id = listToClone.nodes[id].next;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title the Valued Double Linked List library
 */
library ValuedDoubleLinkedList {
    struct Node {
        uint256 next;
        uint256 previous;
        uint256 value;
    }

    struct LinkedList {
        uint256 head;
        uint256 tail;
        uint256 size;
        mapping(uint256 => Node) nodes;
    }

    /**
     * @notice Get Head ID
     * @param self the LinkedList
     * @return the first item of the list
     */
    function getHeadId(LinkedList storage self) internal view returns (uint256) {
        return self.head;
    }

    /**
     * @notice Get head value
     * @param self the LinkedList
     * @return the value of the first node
     */
    function getHeadValue(LinkedList storage self) internal view returns (uint256) {
        return self.nodes[self.head].value;
    }

    /**
     * @notice Get list size
     * @param self the LinkedList
     * @return the size of the list
     */
    function getSize(LinkedList storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @notice Adds node increment
     * @param self the LinkedList
     * @param value the value to add
     * @param id the id of the node
     */
    function addNodeIncrement(
        LinkedList storage self,
        uint256 value,
        uint256 id
    ) internal {
        Node memory node = self.nodes[self.head];

        //If empty
        if (self.head == 0) {
            self.head = id;
            self.tail = id;
            self.nodes[id] = Node(0, 0, value);
        }
        //If head
        else if (value < node.value) {
            self.nodes[self.head].previous = id;
            self.nodes[id] = Node(self.head, 0, value);
            self.head = id;
        } else {
            //If middle
            if (self.size > 1) {
                for (uint256 i = 1; i < self.size; i++) {
                    node = self.nodes[node.next];
                    if (value < node.value) {
                        uint256 currentId = self.nodes[node.next].previous;
                        self.nodes[node.next].previous = id;
                        self.nodes[id] = Node(currentId, self.nodes[currentId].next, value);
                        self.nodes[currentId].next = id;
                        break;
                    }
                }
            }
            //If tail
            if (self.nodes[id].value != value) {
                self.nodes[id] = Node(0, self.tail, value);
                self.nodes[self.tail].next = id;
                self.tail = id;
            }
        }

        self.size += 1;
    }

    /**
     * @notice Adds node decrement
     * @param self the LinkedList
     * @param value the value to decrement
     * @param id the id of the node
     */
    function addNodeDecrement(
        LinkedList storage self,
        uint256 value,
        uint256 id
    ) internal {
        Node memory node = self.nodes[self.head];

        //If empty
        if (self.head == 0) {
            self.head = id;
            self.tail = id;
            self.nodes[id] = Node(0, 0, value);
        }
        //If head
        else if (value > node.value) {
            self.nodes[self.head].previous = id;
            self.nodes[id] = Node(self.head, 0, value);
            self.head = id;
        } else {
            //If middle
            if (self.size > 1) {
                for (uint256 i = 1; i < self.size; i++) {
                    node = self.nodes[node.next];
                    if (value > node.value) {
                        uint256 currentId = self.nodes[node.next].previous;
                        self.nodes[node.next].previous = id;
                        self.nodes[id] = Node(currentId, self.nodes[currentId].next, value);
                        self.nodes[currentId].next = id;
                        break;
                    }
                }
            }
            //If tail
            if (self.nodes[id].value != value) {
                self.nodes[id] = Node(0, self.tail, value);
                self.nodes[self.tail].next = id;
                self.tail = id;
            }
        }

        self.size += 1;
    }

    /**
     * @notice Removes a node
     * @param self the LinkedList
     * @param id the id of the node to remove
     */
    function removeNode(LinkedList storage self, uint256 id) internal {
        if (self.size == 1) {
            self.head = 0;
            self.tail = 0;
        } else if (id == self.head) {
            self.head = self.nodes[self.head].next;
            self.nodes[self.head].previous = 0;
        } else if (id == self.tail) {
            self.tail = self.nodes[self.tail].previous;
            self.nodes[self.tail].next = 0;
        } else {
            self.nodes[self.nodes[id].next].previous = self.nodes[id].previous;
            self.nodes[self.nodes[id].previous].next = self.nodes[id].next;
        }

        self.size -= 1;
    }

    /**
     * @notice Pops the head of the list
     * @param self the LinkedList
     * @return head the first item of the list
     */
    function popHead(LinkedList storage self) internal returns (uint256 head) {
        head = self.head;

        if (self.size == 1) {
            self.head = 0;
            self.tail = 0;
        } else {
            self.head = self.nodes[self.head].next;
            self.nodes[self.head].previous = 0;
        }

        self.size -= 1;
    }

    /**
     * @notice Pops the head and value of the list
     * @param self the LinkedList
     * @return head
     * @return value
     */
    function popHeadAndValue(LinkedList storage self) internal returns (uint256 head, uint256 value) {
        head = self.head;
        value = self.nodes[self.head].value;

        if (self.size == 1) {
            self.head = 0;
            self.tail = 0;
        } else {
            self.head = self.nodes[self.head].next;
            self.nodes[self.head].previous = 0;
        }

        self.size -= 1;
    }

    /**
     * @notice Removes multiple nodes
     * @param self the LinkedList
     * @param amountOfNodes the number of nodes to remove starting from Head
     */
    function removeMultipleFromHead(LinkedList storage self, uint256 amountOfNodes) internal {
        for (uint256 i = 0; i < amountOfNodes; i++) {
            if (self.size == 1) {
                self.head = 0;
                self.tail = 0;
            } else {
                self.head = self.nodes[self.head].next;
                self.nodes[self.head].previous = 0;
            }

            self.size -= 1;
        }
    }

    /**
     * @notice Get position from ID
     * @param self the LinkedList
     * @param id the id to search
     * @return the index position for the id provided
     */
    function getPositionForId(LinkedList storage self, uint256 id) internal view returns (uint256) {
        uint256 positionCounter;

        if (self.nodes[id].value == 0) return 0; // If not in list.

        while (true) {
            positionCounter += 1;
            if (id == self.head) break;

            id = self.nodes[id].previous;
        }

        return positionCounter;
    }

    /**
     * @notice Clones ValuedDoubleLinkedList
     * @param self the LinkedList
     * @param listToClone the LinkedList storage to clone the list from
     */
    function cloneList(LinkedList storage self, LinkedList storage listToClone) internal {
        self.head = listToClone.head;
        self.tail = listToClone.tail;
        self.size = listToClone.size;

        uint256 id = listToClone.head;

        for (uint256 i = 0; i < listToClone.size; i++) {
            self.nodes[id] = listToClone.nodes[id];
            id = listToClone.nodes[id].next;
        }
    }
}

