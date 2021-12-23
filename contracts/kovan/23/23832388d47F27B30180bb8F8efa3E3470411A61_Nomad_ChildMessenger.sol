/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// File: oracle/implementation/Constants.sol


pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant XAppConnectionManager = "XAppConnectionManager";
    bytes32 public constant OracleSpoke = "OracleSpoke";
    bytes32 public constant ParentMessenger = "ParentMessenger";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// File: oracle/interfaces/FinderInterface.sol


pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// File: common/implementation/Lockable.sol


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

// File: cross-chain-oracle/interfaces/ChildMessengerConsumerInterface.sol


pragma solidity ^0.8.0;

interface ChildMessengerConsumerInterface {
    // Called on L2 by child messenger.
    function processMessageFromParent(bytes memory data) external;
}

// File: cross-chain-oracle/interfaces/ChildMessengerInterface.sol


pragma solidity ^0.8.0;

interface ChildMessengerInterface {
    // Should send cross-chain message to Parent messenger contract or revert.
    function sendMessageToParent(bytes memory data) external;
}

// File: external/nomad/interfaces/HomeInterface.sol


pragma solidity ^0.8.0;

/**
 * @title Home
 * @author Celo Labs Inc.
 * @notice Accepts messages to be dispatched to remote chains,
 * constructs a Merkle tree of the messages,
 * and accepts signatures from a bonded Updater
 * which notarize the Merkle tree roots.
 * Accepts submissions of fraudulent signatures
 * by the Updater and slashes the Updater in this case.
 */
interface HomeInterface {
    /**
     * @notice Dispatch the message it to the destination domain & recipient
     * @dev Format the message, insert its hash into Merkle tree,
     * enqueue the new Merkle root, and emit `Dispatch` event with message information.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes content of message
     */
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes memory _messageBody
    ) external;
}

// File: external/nomad/interfaces/XAppConnectionManagerInterface.sol


pragma solidity ^0.8.0;


/**
 * @title XAppConnectionManager
 * @author Celo Labs Inc.
 * @notice Manages a registry of local Replica contracts
 * for remote Home domains. Accepts Watcher signatures
 * to un-enroll Replicas attached to fraudulent remote Homes
 */
interface XAppConnectionManagerInterface {
    // ============ Public Storage ============

    // Home contract for this chain.
    function home() external view returns (HomeInterface);

    /**
     * @notice Check whether _replica is enrolled
     * @param _replica the replica to check for enrollment
     * @return TRUE iff _replica is enrolled
     */
    function isReplica(address _replica) external view returns (bool);
}

// File: cross-chain-oracle/chain-adapters/Nomad_ChildMessenger.sol


pragma solidity ^0.8.0;







/**
 * @notice Sends cross chain messages from any network where Nomad bridging infrastructure is deployed to L1. Both L1
 * and the network where this contract is deployed need to have Nomad Home + Replica contracts to send and receive
 * cross-chain messages.
 */
contract Nomad_ChildMessenger is ChildMessengerInterface, Lockable {
    FinderInterface public finder;

    uint32 public parentChainDomain;

    event MessageSentToParent(bytes data, address indexed targetHub, address indexed oracleSpoke);
    event MessageReceivedFromParent(address indexed targetSpoke, bytes dataToSendToTarget);

    /**
     * @notice Only accept messages from an Nomad Replica contract
     */
    modifier onlyReplica(address addressToCheck) {
        // Determine whether addressToCheck is an enrolled Replica from the xAppConnectionManager
        require(getXAppConnectionManagerInterface().isReplica(addressToCheck), "msg.sender must be replica");
        _;
    }

    modifier onlyParentMessenger(bytes32 addressToCheck) {
        // Note: idea for converting address to bytes32 from this post: https://ethereum.stackexchange.com/a/55963
        require(
            bytes32(abi.encodePacked(getParentMessenger())) == addressToCheck,
            "cross-domain sender must be child messenger"
        );
        _;
    }

    /**
     * @notice Construct the ChildMessenger contract.
     * @param _finder Used to locate XAppConnectionManager for this network.
     * @param _parentChainDomain The Nomad "domain" where the connected parent messenger is deployed. Note that the Nomad
     * domains do not always correspond to "chain ID's", but they are similarly unique identifiers for each network.
     **/
    constructor(address _finder, uint32 _parentChainDomain) {
        finder = FinderInterface(_finder);
        parentChainDomain = _parentChainDomain; // TODO: Figure out how to upgrade this value.
    }

    /**
     * @notice Sends a message to the parent messenger via the Home contract.
     * @dev The caller must be the OracleSpoke on L2. No other contract is permissioned to call this function.
     * @dev The L1 target, the parent messenger, must implement processMessageFromChild to consume the message.
     * @param data data message sent to the L1 messenger. Should be an encoded function call or packed data.
     */
    function sendMessageToParent(bytes memory data) public override nonReentrant() {
        require(msg.sender == getOracleSpoke(), "Only callable by oracleSpoke");
        getXAppConnectionManagerInterface().home().dispatch(
            parentChainDomain,
            // Note: idea for converting address to bytes32 from this post: https://ethereum.stackexchange.com/a/55963
            bytes32(abi.encodePacked(getParentMessenger())),
            data
        );
        emit MessageSentToParent(data, getParentMessenger(), getOracleSpoke());
    }

    /**
     * @notice Process a received message from the parent messenger via the Nomad Replica contract.
     * @dev The cross-chain caller must be the the parent messenger and the msg.sender on this network
     * must be the Replica contract.
     * @param _sender The address the message is coming from
     * @param _message The message in the form of raw bytes
     */
    function handle(
        uint32,
        bytes32 _sender,
        bytes memory _message
    ) external onlyReplica(msg.sender) onlyParentMessenger(_sender) {
        (bytes memory dataToSendToTarget, address target) = abi.decode(_message, (bytes, address));
        ChildMessengerConsumerInterface(target).processMessageFromParent(dataToSendToTarget);
        emit MessageReceivedFromParent(target, dataToSendToTarget);
    }

    function getXAppConnectionManagerInterface() public view returns (XAppConnectionManagerInterface) {
        return XAppConnectionManagerInterface(finder.getImplementationAddress(OracleInterfaces.XAppConnectionManager));
    }

    function getOracleSpoke() public view returns (address) {
        return finder.getImplementationAddress(OracleInterfaces.OracleSpoke);
    }

    function getParentMessenger() public view returns (address) {
        return finder.getImplementationAddress(OracleInterfaces.ParentMessenger);
    }
}