//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
/* solhint-disable no-inline-assembly */

import "./MinLibBytes.sol";
import "../interfaces/IRelayHub.sol";
import "../interfaces/IRelayRegistrar.sol";

/**
 * on-chain relayer registrar.
 * - keep a list of registered relayers (using registerRelayer).
 * - provide view functions to read the list of registered relayers (and filter out invalid ones)
 * - protect the list from spamming entries: only staked relayers are added.
 */
contract RelayRegistrar is IRelayRegistrar {
    using MinLibBytes for bytes;

    struct RelayStorageInfo {
        uint32 lastBlockNumber;
        uint32 stakeBlockNumber;
        uint96 baseRelayFee;
        uint96 pctRelayFee;
        bytes32[3] urlParts;
    }

    mapping(address => RelayStorageInfo) public values;
    address[] public indexedValues;

    bool public immutable override isUsingStorageRegistry;

    IRelayHub public immutable relayHub;

    constructor(IRelayHub _relayHub, bool _isUsingStorageRegistry) {
        relayHub = _relayHub;
        isUsingStorageRegistry = _isUsingStorageRegistry;
    }

    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external override {
        address relayManager = msg.sender;
        if (address(relayHub) != address(0)) {
            relayHub.verifyCanRegister(relayManager);
        }
        emit RelayServerRegistered(relayManager, baseRelayFee, pctRelayFee, url);
        if (isUsingStorageRegistry) {
            storeRelayServerRegistration(relayManager, baseRelayFee, pctRelayFee, url);
        }
    }

    function addItem(address relayManager) internal returns (RelayStorageInfo storage) {
        RelayStorageInfo storage storageInfo = values[relayManager];
        if (storageInfo.lastBlockNumber == 0) {
            indexedValues.push(relayManager);
        }
        return storageInfo;
    }

    function storeRelayServerRegistration(address relayManager, uint baseRelayFee, uint pctRelayFee, string calldata url) internal {
        RelayStorageInfo storage storageInfo = addItem(relayManager);
        if (storageInfo.stakeBlockNumber==0) {
            storageInfo.stakeBlockNumber = uint32(block.number);
        }
        storageInfo.lastBlockNumber = uint32(block.number);
        storageInfo.baseRelayFee = uint96(baseRelayFee);
        storageInfo.pctRelayFee = uint96(pctRelayFee);
        bytes32[3] memory parts = splitString(url);
        storageInfo.urlParts = parts;
    }

    function getRelayInfo(address relayManager) public view override returns (RelayInfo memory info) {
        RelayStorageInfo storage storageInfo = values[relayManager];
        require(storageInfo.lastBlockNumber != 0, "relayManager not found");
        info.lastBlockNumber = storageInfo.lastBlockNumber;
        info.stakeBlockNumber = storageInfo.stakeBlockNumber;
        info.baseRelayFee = storageInfo.baseRelayFee;
        info.pctRelayFee = storageInfo.pctRelayFee;
        info.relayManager = relayManager;
        info.url = packString(storageInfo.urlParts);
    }

    /**
     * read relay info of registered relays
     * @param maxCount - return at most that many relays
     * @param oldestBlock - return only relays registered from this block on.
     * @return info - list of RelayInfo for registered relays
     * @return filled - # of entries filled in info (last entries in returned array might be empty)
     */
    function readRelayInfos(uint oldestBlock, uint maxCount) public view override returns (RelayInfo[] memory info, uint filled) {
        address[] storage items = indexedValues;
        filled = 0;
        info = new RelayInfo[](items.length < maxCount ? items.length : maxCount);
        for (uint i = 0; i < items.length; i++) {
            address relayManager = items[i];
            RelayInfo memory relayInfo = getRelayInfo(relayManager);
            if (relayInfo.lastBlockNumber < oldestBlock) {
                continue;
            }
            if (address(relayHub) == address(0) || IRelayHub(relayHub).isRelayManagerStaked(relayManager)) {
                info[filled++] = relayInfo;
                if (filled >= maxCount)
                    break;
            }
        }
    }

    function splitString(string calldata str) public pure returns (bytes32[3] memory parts) {
        bytes calldata url = bytes(str);
        require(url.length <= 96, "url too long");
        parts[0] = bytes32(url[0 :]);
        if (url.length > 32) {
            parts[1] = bytes32(url[32 :]);
            if (url.length > 64) {
                parts[2] = bytes32(url[64 :]);
            } else {
                parts[2] = 0;
            }
        } else {
            parts[1] = 0;
            parts[2] = 0;
        }
    }

    function packString(bytes32[3] memory parts) public pure returns (string memory str) {
        bytes memory ret = bytes.concat(parts[0], parts[1], parts[2]);
        //trim trailing zeros
        uint len = ret.length - 1;
        while (len > 0 && ret[len] == 0) len--;
        assembly {
            mstore(ret, add(len, 1))
        }
        str = string(ret);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// minimal bytes manipulation required by GSN
// a minimal subset from 0x/LibBytes
/* solhint-disable no-inline-assembly */
pragma solidity ^0.8.0;

library MinLibBytes {

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data, uint256 maxlen) internal pure {
        if (data.length > maxlen) {
            assembly { mstore(data, maxlen) }
        }
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require (b.length >= index + 20, "readAddress: data too short");

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index + 32, "readBytes32: data too short" );

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
        }
        return result;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "readBytes4: data too short");

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice maxFeePerGas, maxPriorityFeePerGas, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        uint256 transactionCalldataGasUsed;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IStakeManager {

    /// Emitted when a stake or unstakeDelay are initialized or increased
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawBlock
    );

    /// Emitted when owner withdraws relayManager funds
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        uint256 amount
    );

    /// Emitted when an authorized Relay Hub penalizes a relayManager
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        uint256 reward
    );

    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalBlock
    );

    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @param stake - amount of ether staked for this relay
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    /// @param withdrawBlock - first block number 'withdraw' will be callable, or zero if the unlock has not been called
    /// @param owner - address that receives revenue and manages relayManager's stake
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawBlock;
        address payable owner;
    }

    struct RelayHubInfo {
        uint256 removalBlock;
    }

    /// Set the owner of a Relay Manager. Called only by the RelayManager itself.
    /// Note that owners cannot transfer ownership - if the entry already exists, reverts.
    /// @param owner - owner of the relay (as configured off-chain)
    function setRelayManagerOwner(address payable owner) external;

    /// Only the owner can call this function. If the entry does not exist, reverts.
    /// @param relayManager - address that represents a stake entry and controls relay registrations on relay hubs
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    function stakeForRelayManager(address relayManager, uint256 unstakeDelay) external payable;

    function unlockStake(address relayManager) external;

    function withdrawStake(address relayManager) external;

    function authorizeHubByOwner(address relayManager, address relayHub) external;

    function authorizeHubByManager(address relayHub) external;

    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    function unauthorizeHubByManager(address relayHub) external;

    function isRelayManagerStaked(address relayManager, address relayHub, uint256 minAmount, uint256 minUnstakeDelay)
    external
    view
    returns (bool);

    /// Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns half of stake on the way.
    /// @param relayManager - entry to penalize
    /// @param beneficiary - address that receives half of the penalty amount
    /// @param amount - amount to withdraw from stake
    function penalizeRelayManager(address relayManager, address payable beneficiary, uint256 amount) external;

    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo);

    function maxUnstakeDelay() external view returns (uint256);

    function versionSM() external view returns (string memory);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

/**
 * on-chain registrar for all registered relayManagers.
 * client can use it instead of events to find relay registration info.
 * NOTE: client should IGNORE the order of these requests.
 */
interface IRelayRegistrar {

    struct RelayInfo {
        //last registration block number
        uint lastBlockNumber;
        //stake (first registration) block number
        uint stakeBlockNumber;
        address relayManager;
        uint baseRelayFee;
        uint pctRelayFee;
        string url;
    }

    /// Emitted when a relay server registers or updates its details
    /// Looking at these events lets a client discover relay servers
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        string relayUrl
    );

    /**
     * called by relay server to register (or re-register) itself.
     * The relayer must be staked in the RelayHub
     */
    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external;

    /**
     * does this registrar save state into storage?
     * @return false only events are used for registration
     *  true keep registry in storage, in addition to events
     */
    function isUsingStorageRegistry() external returns (bool);

    function getRelayInfo(address relayManager) external view returns (RelayInfo memory info);

    function readRelayInfos(uint oldestBlock, uint maxCount) external view returns (RelayInfo[] memory info, uint filled);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

interface IRelayHub {
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Maximum funds that can be deposited at once. Prevents user error by disallowing large deposits.
        uint256 maximumRecipientDeposit;
        // Minimum unstake delay blocks of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Minimum stake a relay can have. An attack on the network will never cost less than half this value.
        uint256 minimumStake;
    }

    event RelayHubConfigured(RelayHubConfig config);

    /// Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// Emitted when an account withdraws funds from RelayHub.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// Emitted when depositFor is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// Emitted when an attempt to relay a call fails and Paymaster does not accept the transaction.
    /// The actual relayed call was not executed, and the recipient not charged.
    /// @param reason contains a revert reason returned from preRelayedCall or forwarder.
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        address indexed from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /// Emitted when a transaction is relayed. Note that the actual encoded function might be reverted: this will be
    /// indicated in the status field.
    /// Useful when monitoring a relay's operation and relayed calls to a contract.
    /// Charge is the ether value deducted from the recipient's balance, paid to the relay's manager.
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        address indexed from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    event HubDeprecated(uint256 fromBlock);

    /// Reason error codes for the TransactionRelayed event
    /// @param OK - the transaction was successfully relayed and execution successful - never included in the event
    /// @param RelayedCallFailed - the transaction was relayed, but the relayed call failed
    /// @param RejectedByPreRelayed - the transaction was not relayed due to preRelatedCall reverting
    /// @param RejectedByForwarder - the transaction was not relayed due to forwarder check (signature,nonce)
    /// @param PostRelayedFailed - the transaction was relayed and reverted due to postRelatedCall reverting
    /// @param PaymasterBalanceChanged - the transaction was relayed and reverted due to the paymaster balance change
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /// Add new worker addresses controlled by sender who must be a staked Relay Manager address.
    /// Emits a RelayWorkersAdded event.
    /// This function can be called multiple times, emitting new events
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function verifyCanRegister(address relayManager) external;

    // Balance management

    /// Deposits ether for a contract, so that it can receive (and pay for) relayed transactions. Unused balance can only
    /// be withdrawn by the contract itself, by calling withdraw.
    /// Emits a Deposited event.
    function depositFor(address target) external payable;

    /// Withdraws from an account's balance, sending it back to it. Relay managers call this to retrieve their revenue, and
    /// contracts can also use it to reduce their funding.
    /// Emits a Withdrawn event.
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying


    /// Relays a transaction. For this to succeed, multiple conditions must be met:
    ///  - Paymaster's "preRelayCall" method must succeed and not revert
    ///  - the sender must be a registered Relay Worker that the user signed
    ///  - the transaction's gas price must be equal or larger than the one that was signed by the sender
    ///  - the transaction must have enough gas to run all internal transactions if they use all gas available to them
    ///  - the Paymaster must have enough balance to pay the Relay Worker for the scenario when all gas is spent
    ///
    /// If all conditions are met, the call will be relayed and the recipient charged.
    ///
    /// Arguments:
    /// @param maxAcceptanceBudget - max valid value for paymaster.getGasLimits().acceptanceBudget
    /// @param relayRequest - all details of the requested relayed call
    /// @param signature - client's EIP-712 signature over the relayRequest struct
    /// @param approvalData: dapp-specific data forwarded to preRelayedCall.
    ///        This value is *not* verified by the Hub. For example, it can be used to pass a signature to the Paymaster
    ///
    /// Emits a TransactionRelayed event.
    function relayCall(
        uint maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    function penalize(address relayWorker, address payable beneficiary) external;

    function setConfiguration(RelayHubConfig memory _config) external;

    // Deprecate hub (reverting relayCall()) from block number 'fromBlock'
    // Can only be called by owner
    function deprecateHub(uint256 fromBlock) external;

    /// The fee is expressed as a base fee in wei plus percentage on actual charge.
    /// E.g. a value of 40 stands for a 40% fee, so the recipient will be
    /// charged for 1.4 times the spent amount.
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /* getters */

    /// Returns the whole hub configuration
    function getConfiguration() external view returns (RelayHubConfig memory config);

    function workerToManager(address worker) external view returns(address);

    function workerCount(address manager) external view returns(uint256);

    /// Returns an account's deposits. It can be either a deposit of a paymaster, or a revenue of a relay manager.
    function balanceOf(address target) external view returns (uint256);

    function stakeManager() external view returns (IStakeManager);

    function penalizer() external view returns (address);

    function relayRegistrar() external view returns (address);

    /// Uses StakeManager info to decide if the Relay Manager can be considered staked
    /// @return true if stake size and delay satisfy all requirements
    function isRelayManagerStaked(address relayManager) external view returns(bool);

    // Checks hubs' deprecation status
    function isDeprecated() external view returns (bool);

    // Returns the block number from which the hub no longer allows relaying calls.
    function deprecationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the hub contract
    function versionHub() external view returns (string memory);

    /// @return a total measurable amount of gas left to current execution; same as 'gasleft()' for pure EVMs
    function aggregateGasleft() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * verify the transaction would execute.
     * validate the signature and the nonce of the request.
     * revert if either signature or nonce are incorrect.
     * also revert if domainSeparator or requestTypeHash are not registered.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * execute a transaction
     * @param forwardRequest - all transaction parameters
     * @param domainSeparator - domain used when signing this request
     * @param requestTypeHash - request type used when signing this request.
     * @param suffixData - the extension data used when signing this request.
     * @param signature - signature to validate.
     *
     * the transaction is verified, and then executed.
     * the success and ret of "call" are returned.
     * This method would revert only verification errors. target errors
     * are reported using the returned "success" and ret string
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * Register a new Request typehash.
     * @param typeName - the name of the request type.
     * @param typeSuffix - any extra data after the generic params.
     *  (must add at least one param. The generic ForwardRequest type is always registered by the constructor)
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * Register a new domain separator.
     * The domain separator must have the following fields: name,version,chainId, verifyingContract.
     * the chainId is the current network's chainId, and the verifyingContract is this forwarder.
     * This method is given the domain name and version to create and register the domain separator value.
     * @param name the domain's display name
     * @param version the domain/protocol version
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}