/**
 *Submitted for verification at Etherscan.io on 2021-12-23
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: cross-chain-oracle/interfaces/ParentMessengerConsumerInterface.sol


pragma solidity ^0.8.0;

interface ParentMessengerConsumerInterface {
    // Function called on Oracle hub to pass in data send from L2, with chain ID.
    function processMessageFromChild(uint256 chainId, bytes memory data) external;
}

// File: cross-chain-oracle/interfaces/ParentMessengerInterface.sol


pragma solidity ^0.8.0;

interface ParentMessengerInterface {
    // Should send cross-chain message to Child messenger contract or revert.
    function sendMessageToChild(bytes memory data) external;

    // Informs Hub how much msg.value they need to include to call `sendMessageToChild`.
    function getL1CallValue() external view returns (uint256);
}

// File: cross-chain-oracle/chain-adapters/ParentMessengerBase.sol


pragma solidity ^0.8.0;



abstract contract ParentMessengerBase is Ownable, ParentMessengerInterface {
    uint256 public childChainId;

    address public childMessenger;

    address public oracleHub;
    address public governorHub;

    address public oracleSpoke;
    address public governorSpoke;

    event SetChildMessenger(address indexed childMessenger);
    event SetOracleHub(address indexed oracleHub);
    event SetGovernorHub(address indexed governorHub);
    event SetOracleSpoke(address indexed oracleSpoke);
    event SetGovernorSpoke(address indexed governorSpoke);

    modifier onlyHubContract() {
        require(msg.sender == oracleHub || msg.sender == governorHub, "Only privileged caller");
        _;
    }

    /**
     * @notice Construct the ParentMessengerBase contract.
     * @param _childChainId The chain id of the L2 network this messenger should connect to.
     **/
    constructor(uint256 _childChainId) {
        childChainId = _childChainId;
    }

    /*******************
     *  OWNER METHODS  *
     *******************/

    /**
     * @notice Changes the stored address of the child messenger, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newChildMessenger address of the new child messenger, deployed on L2.
     */
    function setChildMessenger(address newChildMessenger) public onlyOwner {
        childMessenger = newChildMessenger;
        emit SetChildMessenger(childMessenger);
    }

    /**
     * @notice Changes the stored address of the Oracle hub, deployed on L1.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newOracleHub address of the new oracle hub, deployed on L1 Ethereum.
     */
    function setOracleHub(address newOracleHub) public onlyOwner {
        oracleHub = newOracleHub;
        emit SetOracleHub(oracleHub);
    }

    /**
     * @notice Changes the stored address of the Governor hub, deployed on L1.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newGovernorHub address of the new governor hub, deployed on L1 Ethereum.
     */
    function setGovernorHub(address newGovernorHub) public onlyOwner {
        governorHub = newGovernorHub;
        emit SetGovernorHub(governorHub);
    }

    /**
     * @notice Changes the stored address of the oracle spoke, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newOracleSpoke address of the new oracle spoke, deployed on L2.
     */
    function setOracleSpoke(address newOracleSpoke) public onlyOwner {
        oracleSpoke = newOracleSpoke;
        emit SetOracleSpoke(oracleSpoke);
    }

    /**
     * @notice Changes the stored address of the governor spoke, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newGovernorSpoke address of the new governor spoke, deployed on L2.
     */
    function setGovernorSpoke(address newGovernorSpoke) public onlyOwner {
        governorSpoke = newGovernorSpoke;
        emit SetGovernorSpoke(governorSpoke);
    }

    /**
     * @notice Returns the amount of ETH required for a caller to pass as msg.value when calling `sendMessageToChild`.
     * @return The amount of ETH required for a caller to pass as msg.value when calling `sendMessageToChild`.
     */
    function getL1CallValue() external view virtual override returns (uint256) {
        return 0;
    }
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

// File: cross-chain-oracle/chain-adapters/Nomad_ParentMessenger.sol


pragma solidity ^0.8.0;








/**
 * @notice Sends cross chain messages from Ethereum L1 to any other network where Nomad bridging infrastructure is
 * deployed. Both L1 and the network where the child messenger is deployed need to have Nomad Home + Replica contracts
 * to send and receive cross-chain messages.
 * @dev This contract is ownable and should be owned by the DVM governor.
 */
contract Nomad_ParentMessenger is ParentMessengerInterface, ParentMessengerBase, Lockable {
    FinderInterface public finder;

    event MessageSentToChild(bytes data, address indexed targetSpoke, address indexed childMessenger);
    event MessageReceivedFromChild(bytes data, address indexed childMessenger, address indexed targetHub);

    modifier onlyChildMessenger(bytes32 addressToCheck) {
        require(
            bytes32(uint256(uint160(childMessenger))) == addressToCheck,
            "cross-domain sender must be child messenger"
        );
        _;
    }

    /**
     * @notice Only accept messages from an Nomad Replica contract
     */
    modifier onlyReplica(address addressToCheck) {
        // Determine whether addressToCheck is an enrolled Replica from the xAppConnectionManager
        require(getXAppConnectionManager().isReplica(addressToCheck), "msg.sender must be replica");
        _;
    }

    /**
     * @notice Construct the ParentMessenger contract.
     * @param _finder Used to locate XAppConnectionManager for this network.
     * @param _childChainDomain The Nomad "domain" where the connected child messenger is deployed. Note that the Nomad
     * domains do not always correspond to "chain ID's", but they are similarly unique identifiers for each network.
     **/
    constructor(address _finder, uint256 _childChainDomain) ParentMessengerBase(_childChainDomain) {
        finder = FinderInterface(_finder);
    }

    /**
     * @notice Sends a message to the child messenger via the Nomad Home contract.
     * @dev The caller must be the either the OracleHub or the GovernorHub. This is to send either a
     * price or initiate a governance action to the OracleSpoke or GovernorSpoke on the child network.
     * @dev The recipient of this message is the child messenger. The messenger must implement Nomad specific
     * function called "handle" which then forwards the data to the target either the OracleSpoke or the governorSpoke
     * depending on the caller.
     * @dev This function will only succeed if this contract has enough ETH to cover the approximate L1 call value.
     * @param data data message sent to the child messenger. Should be an encoded function call or packed data.
     */
    function sendMessageToChild(bytes memory data) public override onlyHubContract() nonReentrant() {
        address target = msg.sender == oracleHub ? oracleSpoke : governorSpoke;
        bytes memory dataToSendToChild = abi.encode(data, target);
        getXAppConnectionManager().home().dispatch(
            uint32(childChainId), // chain ID and the Nomad idea of a "domain" are used interchangeably.
            bytes32(uint256(uint160(childMessenger))),
            dataToSendToChild
        );
        emit MessageSentToChild(dataToSendToChild, target, childMessenger);
    }

    /**
     * @notice Process a received message from the child messenger via the Nomad Replica contract.
     * @dev The cross-chain caller must be the the child messenger and the msg.sender on this network
     * must be the Replica contract.
     * @dev Note that only the OracleHub can receive messages from the child messenger. Therefore we can always forward
     * these messages to this contract. The OracleHub must implement processMessageFromChild to handle this message.
     * @param _sender The address the message is coming from
     * @param _message The message in the form of raw bytes
     */
    function handle(
        uint32,
        bytes32 _sender,
        bytes memory _message
    ) external onlyReplica(msg.sender) onlyChildMessenger(_sender) {
        ParentMessengerConsumerInterface(oracleHub).processMessageFromChild(childChainId, _message);
        emit MessageReceivedFromChild(_message, childMessenger, oracleHub);
    }

    function getXAppConnectionManager() public view returns (XAppConnectionManagerInterface) {
        return XAppConnectionManagerInterface(finder.getImplementationAddress(OracleInterfaces.XAppConnectionManager));
    }
}