// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/ChildMessengerInterface.sol";
import "../interfaces/ChildMessengerConsumerInterface.sol";
import "../../common/implementation/Lockable.sol";
import "../../external/avm/AVM_CrossDomainEnabled.sol";

/**
 * @notice Sends and receives cross chain messages between Arbitrum L2 and Ethereum L1 network.
 * @dev This contract is ownable via the onlyCrossDomainAccount modifier, restricting ownership to the cross-domain
 * parent messenger contract that lives on L1.
 */
contract Arbitrum_ChildMessenger is AVM_CrossDomainEnabled, ChildMessengerInterface, Lockable {
    // The only child network contract that can send messages over the bridge via the messenger is the oracle spoke.
    address public oracleSpoke;

    // Messenger contract on the other side of the L1<->L2 bridge.
    address public parentMessenger;

    event SetOracleSpoke(address newOracleSpoke);
    event SetParentMessenger(address newParentMessenger);
    event MessageSentToParent(bytes data, address indexed parentAddress, address indexed oracleSpoke, uint256 id);
    event MessageReceivedFromParent(bytes data, address indexed targetSpoke, address indexed parentAddress);

    /**
     * @notice Construct the Arbitrum_ChildMessenger contract.
     * @param _parentMessenger The address of the L1 parent messenger. Acts as the "owner" of this contract.
     */
    constructor(address _parentMessenger) {
        parentMessenger = _parentMessenger;
    }

    /**
     * @notice Changes the stored address of the Oracle spoke, deployed on L2.
     * @dev The caller of this function must be the parent messenger, over the canonical bridge.
     * @param newOracleSpoke address of the new oracle spoke, deployed on L2.
     */
    function setOracleSpoke(address newOracleSpoke) public onlyFromCrossDomainAccount(parentMessenger) nonReentrant() {
        oracleSpoke = newOracleSpoke;
        emit SetOracleSpoke(newOracleSpoke);
    }

    /**
     * @notice Changes the stored address of the parent messenger, deployed on L1.
     * @dev The caller of this function must be the parent messenger, over the canonical bridge.
     * @param newParentMessenger address of the new parent messenger, deployed on L1.
     */
    function setParentMessenger(address newParentMessenger)
        public
        onlyFromCrossDomainAccount(parentMessenger)
        nonReentrant()
    {
        parentMessenger = newParentMessenger;
        emit SetParentMessenger(newParentMessenger);
    }

    /**
     * @notice Sends a message to the parent messenger via the canonical message bridge.
     * @dev The caller must be the OracleSpoke on L2. No other contract is permissioned to call this function.
     * @dev The L1 target, the parent messenger, must implement processMessageFromChild to consume the message.
     * @param data data message sent to the L1 messenger. Should be an encoded function call or packed data.
     */
    function sendMessageToParent(bytes memory data) public override nonReentrant() {
        require(msg.sender == oracleSpoke, "Only callable by oracleSpoke");
        bytes memory dataSentToParent = abi.encodeWithSignature("processMessageFromCrossChainChild(bytes)", data);
        uint256 id = sendCrossDomainMessage(msg.sender, parentMessenger, dataSentToParent);
        emit MessageSentToParent(dataSentToParent, parentMessenger, oracleSpoke, id);
    }

    /**
     * @notice Process a received message from the parent messenger via the canonical message bridge.
     * @dev The caller must be the the parent messenger, sent over the canonical message bridge.
     * @param data data message sent from the L1 messenger. Should be an encoded function call or packed data.
     * @param target desired recipient of `data`. Target must implement the `processMessageFromParent` function. Having
     * this as a param enables the L1 Messenger to send messages to arbitrary addresses on the L1. This is primarily
     * used to send messages to the OracleSpoke and GovernorSpoke on L2.
     */
    function processMessageFromCrossChainParent(bytes memory data, address target)
        public
        onlyFromCrossDomainAccount(parentMessenger)
        nonReentrant()
    {
        ChildMessengerConsumerInterface(target).processMessageFromParent(data);
        emit MessageReceivedFromParent(data, target, parentMessenger);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ChildMessengerConsumerInterface {
    // Called on L2 by child messenger.
    function processMessageFromParent(bytes memory data) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ChildMessengerInterface {
    // Should send cross-chain message to Parent messenger contract or revert.
    function sendMessageToParent(bytes memory data) external;
}

// Copied logic from https://github.com/makerdao/arbitrum-dai-bridge/blob/34acc39bc6f3a2da0a837ea3c5dbc634ec61c7de/contracts/l2/L2CrossDomainEnabled.sol
// with a change to the solidity version.

pragma solidity ^0.8.0;

import "./interfaces/ArbSys.sol";

abstract contract AVM_CrossDomainEnabled {
    event SentCrossDomainMessage(address indexed from, address indexed to, uint256 indexed id, bytes data);

    modifier onlyFromCrossDomainAccount(address l1Counterpart) {
        require(msg.sender == applyL1ToL2Alias(l1Counterpart), "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    // l1 addresses are transformed during l1->l2 calls. See https://developer.offchainlabs.com/docs/l1_l2_messages#address-aliasing for more information.
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    // Sends a message to L1 via the ArbSys contract. See https://developer.offchainlabs.com/docs/arbsys.
    // After the Arbitrum chain advances some set amount of time, ArbOS gathers all outgoing messages, Merklizes them,
    // and publishes the root as an OutboxEntry in the chain's outbox. Note that this happens "automatically";
    // i.e., it requires no additional action from the user. After the Outbox entry is published on the L1 chain,
    // the user (or anybody) can compute the Merkle proof of inclusion of their outgoing message. Anytime after the
    // dispute window passes (~7 days), any user can execute the L1 message by calling Outbox.executeTransaction;
    // if it reverts, it can be re-executed any number of times and with no upper time-bound.
    // To read more about the L2 --> L1 lifecycle, see: https://developer.offchainlabs.com/docs/l1_l2_messages#explanation.
    function sendCrossDomainMessage(
        address user,
        address to,
        bytes memory data
    ) internal returns (uint256) {
        // note: this method doesn't support sending ether to L1 together with a call
        uint256 id = ArbSys(address(100)).sendTxToL1(to, data);

        emit SentCrossDomainMessage(user, to, id, data);

        return id;
    }
}

// Copied logic from https://github.com/makerdao/arbitrum-dai-bridge/blob/54a2109a97c5b1504824c6317d358e2d2733b5a3/contracts/arbitrum/ArbSys.sol
// with changes only to the solidity version and comments.

pragma solidity ^0.8.0;

/**
 * @notice Precompiled contract that exists in every Arbitrum chain at address(100),
 * 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality. ArbSys provides
 * systems functionality useful to some Arbitrum contracts. Any contract running on an Arbitrum Chain can call the
 * chain's ArbSys.
 */
interface ArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint256 amount);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}