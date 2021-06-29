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
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./libs/SignatureVerifier.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IEscrow.sol";
import "./interfaces/IStakerMedalNFT.sol";
import "./interfaces/IReferralContract.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title AllianceBlock ActionVerifier contract
 * @dev Extends Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable
 * @notice Handles user's Actions and Rewards within the protocol
 */
contract ActionVerifier is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SignatureVerifier for SignatureVerifier.Action;

    // Events
    event EpochChanged(uint256 indexed epochId, uint256 endingTimestamp);
    event ActionImported(string indexed actionName);
    event ActionUpdated(string indexed actionName);
    event ActionsProvided(SignatureVerifier.Action[] actions, bytes[] signatures, address indexed provider);

    // The rewards for doing actions per staker level.
    mapping(bytes32 => mapping(uint256 => uint256)) public rewardPerActionPerLevel;
    // The rewards for doing actions not for first time per staker level (not all actions give rewards for this).
    mapping(bytes32 => mapping(uint256 => uint256)) public rewardPerActionPerLevelAfterFirstTime;
    // The minimum staker level that the account providing the action should be to be able to provide it.
    mapping(bytes32 => uint256) public minimumLevelForActionProvision;
    // The referral contract (if any) that verifys referralId of an action is valid.
    mapping(bytes32 => IReferralContract) public referralContract;
    // The reward that an action provider takes for each action provision depending on provider's staking level.
    mapping(uint256 => uint256) public rewardPerActionProvisionPerLevel;
    // The amount of action provisions a provider can do per day depending on provider's staking level.
    mapping(uint256 => uint256) public maxActionsPerDayPerLevel;
    // The amount of action provisions an action provider has done for a specific epoch.
    mapping(address => mapping(uint256 => uint256)) public actionsProvidedPerAccountPerEpoch;
    // The last epoch a specific account has done a specific action.
    mapping(address => mapping(bytes32 => uint256)) public lastEpochActionDonePerAccount;

    // The current epoch of ActionVerifier
    // (actions that provide rewards multiple times can only provide only in different epochs).
    uint256 currentEpoch;
    // The ending timestamp for the current epoch
    uint256 endingTimestampForCurrentEpoch;

    uint256 constant private ONE_DAY = 1 days;

    IEscrow public escrow;
    IStakerMedalNFT public stakerMedalNft;

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant EIP712DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /**
     * @dev Modifier that checks if time has come to change epoch.
     */
    modifier checkEpoch() {
        while (block.timestamp >= endingTimestampForCurrentEpoch){
            currentEpoch = currentEpoch.add(1);
            endingTimestampForCurrentEpoch = endingTimestampForCurrentEpoch.add(ONE_DAY);

            emit EpochChanged(currentEpoch, endingTimestampForCurrentEpoch);
        }
        _;
    }

    /**
     * @dev Initializer of the ActionVerifier contract.
     * @param rewardsPerActionProvisionPerLevel_ The reward that an action provider accumulates for each action provision per level.
     * @param maxActionsPerDayPerLevel_ The max actions that an account can take rewards for in one day.
     * @param escrow_ The address of the escrow.
     * @param stakerMedalNft_ The address of the stakerMedalNft.
     * @param chainId The chain id.
     */
    function initialize(
        uint256[4] memory rewardsPerActionProvisionPerLevel_,
        uint256[4] memory maxActionsPerDayPerLevel_,
        address escrow_,
        address stakerMedalNft_,
        uint256 chainId
    ) external initializer {
        require(rewardsPerActionProvisionPerLevel_[3] != 0, "Cannot initialize rewardPerActionProvisionPerLevel_ with 0");
        require(maxActionsPerDayPerLevel_[3] != 0, "Cannot initialize maxActionsPerDayPerLevel_ with 0");
        require(escrow_ != address(0), "Cannot initialize with escrow_ address");
        require(stakerMedalNft_ != address(0), "Cannot initialize with stakerMedalNft_ address");
        require(chainId != 0, "Cannot initialize chainId with 0");

        __Ownable_init();
        __ReentrancyGuard_init();

        escrow = IEscrow(escrow_);
        stakerMedalNft = IStakerMedalNFT(stakerMedalNft_);

        for (uint256 i = 0; i < 4; i++) {
            rewardPerActionProvisionPerLevel[i] = rewardsPerActionProvisionPerLevel_[i];
            maxActionsPerDayPerLevel[i] = maxActionsPerDayPerLevel_[i];
        }

        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "AllianceBlock Verifier",
                version: "1.0",
                chainId: chainId,
                verifyingContract: address(this)
            })
        );

        currentEpoch = 1;
        endingTimestampForCurrentEpoch = block.timestamp.add(ONE_DAY);
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    /**
     * @dev This function is used by the owner to update variables.
     * @param rewardsPerActionProvisionPerLevel_ The reward that an action provider accumulates for each action provision per level.
     * @param maxActionsPerDayPerLevel_ The max actions that an account can take rewards for in one day.
     */
    function updateVariables(
        uint256[4] memory rewardsPerActionProvisionPerLevel_,
        uint256[4] memory maxActionsPerDayPerLevel_
    ) external onlyOwner() checkEpoch() {
        for (uint256 i = 0; i < 4; i++) {
            rewardPerActionProvisionPerLevel[i] = rewardsPerActionProvisionPerLevel_[i];
            maxActionsPerDayPerLevel[i] = maxActionsPerDayPerLevel_[i];
        }
    }

    /**
     * @dev This function is used by the owner to add more actions.
     * @param action The name of the action.
     * @param reputationalAlbtRewardsPerLevel The reputational albt reward for this action per staker level.
     * @param reputationalAlbtRewardsPerLevelAfterFirstTime The reputational albt reward for this action per staker level after first time.
     * @param minimumLevelForProvision The minimum staker level to be able to provide rewards for this action.
     * @param referralContract_ The referral contract if any for this action.
     */
    function importAction(
        string memory action,
        uint256[4] memory reputationalAlbtRewardsPerLevel,
        uint256[4] memory reputationalAlbtRewardsPerLevelAfterFirstTime,
        uint256 minimumLevelForProvision,
        address referralContract_
    ) external onlyOwner() checkEpoch() {
        _storeAction(
            action,
            reputationalAlbtRewardsPerLevel,
            reputationalAlbtRewardsPerLevelAfterFirstTime,
            minimumLevelForProvision,
            referralContract_
        );

        emit ActionImported(action);
    }

    /**
     * @dev This function is used by the owner to update already existing actions.
     * @param action The name of the action.
     * @param reputationalAlbtRewardsPerLevel The reputational albt reward for this action per staker level.
     * @param reputationalAlbtRewardsPerLevelAfterFirstTime The reputational albt reward for this action per staker level after first time.
     * @param minimumLevelForProvision The minimum staker level to be able to provide rewards for this action.
     * @param referralContract_ The referral contract if any for this action.
     */
    function updateAction(
        string memory action,
        uint256[4] memory reputationalAlbtRewardsPerLevel,
        uint256[4] memory reputationalAlbtRewardsPerLevelAfterFirstTime,
        uint256 minimumLevelForProvision,
        address referralContract_
    ) external onlyOwner() checkEpoch() {
        // If action exists it will for sure provide rewards to level 3 stakers.
        require(rewardPerActionPerLevel[keccak256(abi.encodePacked(action))][3] > 0, "Action should already exist");

        _storeAction(
            action,
            reputationalAlbtRewardsPerLevel,
            reputationalAlbtRewardsPerLevelAfterFirstTime,
            minimumLevelForProvision,
            referralContract_
        );

        emit ActionUpdated(action);
    }

    /**
     * @dev This function is used by users to provide rewards to all users for their actions.
     * @param actions The actions provided.
     * @param signatures The signatures representing the actions.
     */
    function provideRewardsForActions(SignatureVerifier.Action[] memory actions, bytes[] memory signatures) external nonReentrant() checkEpoch() {
        uint256 stakingLevel = stakerMedalNft.getLevelOfStaker(msg.sender);
        require(rewardPerActionProvisionPerLevel[stakingLevel] > 0,
            "Staking level not enough to provide rewards for actions");
        require(actions.length == signatures.length, "Invalid length");

        uint256 actionsRemainingForCurrentEpoch = maxActionsPerDayPerLevel[stakingLevel].sub(
            actionsProvidedPerAccountPerEpoch[msg.sender][currentEpoch]);

        require(actions.length <= actionsRemainingForCurrentEpoch, "Too many actions");

        address[] memory accounts = new address[](actions.length.add(1));
        uint256[] memory rewards = new uint256[](actions.length.add(1));

        uint256 rewardForCaller = 0;

        for (uint256 i = 0; i < actions.length; i++) {
            (bool isValid, uint256 reward) = _checkValidActionProvision(actions[i], signatures[i], stakingLevel);
            if (isValid) {
                accounts[i] = actions[i].account;
                rewards[i] = reward;

                rewardForCaller = rewardForCaller.add(rewardPerActionProvisionPerLevel[stakingLevel]);
                actionsProvidedPerAccountPerEpoch[msg.sender][currentEpoch] = 
                    actionsProvidedPerAccountPerEpoch[msg.sender][currentEpoch].add(1);
            } else {
                actions[i] = SignatureVerifier.Action("", "", address(0), 0);
                signatures[i] = "";
                accounts[i] = address(0);
                rewards[i] = 0;
            }
        }

        accounts[actions.length] = msg.sender;
        rewards[actions.length] = rewardForCaller;

        escrow.multiMintReputationalToken(accounts, rewards);

        emit ActionsProvided(actions, signatures, msg.sender);
    }

    /**
     * @notice Check Action
     * @dev checks if given action has a reward for specific level
     * @return exist boolean represents checks if action has a reward associated
     */
    function checkAction(string memory action, uint256 stakingLevel) public view returns (bool exist) {        
        return rewardPerActionPerLevel[keccak256(abi.encodePacked(action))][stakingLevel] > 0;
    }

    /**
     * @dev Checks if an action provision is valid
     * @param action The action to check.
     * @param signature The signature provided for this specific action.
     * @param stakingLevelOfProvider The staking level action provider has.
     * @dev returns true if action is ok and also the reward for the account done the action.
     */
    function _checkValidActionProvision(
        SignatureVerifier.Action memory action,
        bytes memory signature,
        uint256 stakingLevelOfProvider
    ) internal returns (bool, uint256) {
        uint256 stakingLevelOfActionAccount = stakerMedalNft.getLevelOfStaker(action.account);
        bytes32 actionHash = keccak256(abi.encodePacked(action.actionName));

        bool isValidReferralId = true;
        bytes32 specificActionHash = actionHash;

        uint256 rewardForAction = rewardPerActionPerLevel[actionHash][stakingLevelOfActionAccount];

        if (address(referralContract[actionHash]) != address(0)) {
            isValidReferralId = referralContract[actionHash].isValidReferralId(action.referralId);
            specificActionHash = keccak256(abi.encodePacked(action.actionName, action.referralId));
        }       

        if (lastEpochActionDonePerAccount[action.account][specificActionHash] != 0) {
            if (rewardPerActionPerLevelAfterFirstTime[actionHash][stakingLevelOfActionAccount] == 0 ||
                currentEpoch == lastEpochActionDonePerAccount[action.account][specificActionHash])
            {
                return (false, 0);
            } else {
                rewardForAction = rewardPerActionPerLevelAfterFirstTime[actionHash][stakingLevelOfActionAccount];
            }
        }

        if (action.isValidSignature(signature, DOMAIN_SEPARATOR) &&
            minimumLevelForActionProvision[actionHash] <= stakingLevelOfProvider &&
            rewardForAction != 0 && isValidReferralId)
        {
            lastEpochActionDonePerAccount[action.account][specificActionHash] = currentEpoch;
            return (true, rewardForAction);
        }

        return (false, 0);
    }

    /**
     * @notice Store action
     * @dev This function is storing all specs for an action.
     */
    function _storeAction(
        string memory action,
        uint256[4] memory reputationalAlbtRewardsPerLevel,
        uint256[4] memory reputationalAlbtRewardsPerLevelAfterFirstTime,
        uint256 minimumLevelForProvision,
        address referralContract_
    ) internal {        
        bytes32 actionHash = keccak256(abi.encodePacked(action));
        for (uint256 i = 0; i < 4; i++) {
            rewardPerActionPerLevel[actionHash][i] = reputationalAlbtRewardsPerLevel[i];
            rewardPerActionPerLevelAfterFirstTime[actionHash][i] = reputationalAlbtRewardsPerLevelAfterFirstTime[i];
        }

        minimumLevelForActionProvision[actionHash] = minimumLevelForProvision;
        referralContract[actionHash] = IReferralContract(referralContract_);
    }
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
 * @title Interface of every referral contract.
 */
interface IReferralContract {
    function isValidReferralId(uint256 referralId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the StakerMedalNFT contract.
 */
interface IStakerMedalNFT {
    function getLevelOfStaker(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Bytes Reader Library
 */
library BytesReader {
    /**
     * @notice Reads a bytes32 value from a position in a byte array.
     * @param b Byte array containing a bytes32 value.
     * @param index Index in byte array of bytes32 value.
     * @return result bytes32 value from byte array.
     */
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        if (b.length < index + 32) {
            return bytes32(0);
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BytesReader.sol";

/**
 * @title Signature Verifier Library
 */
library SignatureVerifier {
    using BytesReader for bytes;

    struct Action {
        string actionName;
        string answer;
        address account;
        uint256 referralId;
    }
    bytes32 constant ACTION_TYPEHASH = 0x1f76bf6993440811cef7b51dc00dee9d4e8fa911023c7f2d088ce4e46ac2346f;

    /**
     * @notice Gets Actions struct hash
     * @param action the Action to retrieve
     * @return the keccak hash Action struct
     */
    function getActionStructHash(Action memory action) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ACTION_TYPEHASH,
                    keccak256(bytes(action.actionName)),
                    keccak256(bytes(action.answer)),
                    action.account,
                    action.referralId
                )
            );
    }

    /**
     * @notice Gets Actions typed data hash
     * @param action the Action to retrieve
     * @return actionHash actionHash the keccak Action hash
     */
    function getActionTypedDataHash(Action memory action, bytes32 DOMAIN_SEPARATOR)
        internal
        pure
        returns (bytes32 actionHash)
    {
        actionHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getActionStructHash(action)));
    }

    /**
     * @notice Verifies that an action has been signed by the action.account.
     * @param action The action to verify the signature for.
     * @param signature Proof that the hash has been signed by action.account.
     * @return True if the address recovered from the provided signature matches the action.account.
     */
    function isValidSignature(
        Action memory action,
        bytes memory signature,
        bytes32 DOMAIN_SEPARATOR
    ) internal pure returns (bool) {
        if (signature.length != 65) return false;

        bytes32 hash = getActionTypedDataHash(action, DOMAIN_SEPARATOR);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        address recovered = ecrecover(hash, v, r, s);

        return action.account == recovered;
    }
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