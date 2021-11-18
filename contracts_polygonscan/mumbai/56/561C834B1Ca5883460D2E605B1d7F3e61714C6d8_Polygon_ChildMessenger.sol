/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

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
    // Called on L2 by parent messenger.
    function processMessageFromParent(bytes memory data) external;
}

// File: cross-chain-oracle/interfaces/ChildMessengerInterface.sol


pragma solidity ^0.8.0;

interface ChildMessengerInterface {
    // Should send cross-chain message to Parent messenger contract or revert.
    function sendMessageToParent(bytes memory data) external;
}

// File: external/polygon/tunnel/FxBaseChildTunnel.sol


// Copied with no modifications from Polygon demo FxTunnel repo: https://github.com/jdkanani/fx-portal
// except bumping version from 0.7.3 --> 0.8
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel.
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // Set fxRootTunnel if not set already.
    function setFxRootTunnel(address _fxRootTunnel) public {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) public override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// File: cross-chain-oracle/chain-adapters/Polygon_ChildMessenger.sol


pragma solidity ^0.8.0;





/**
 * @notice Sends cross chain messages from Polygon to Ethereum network.
 * @dev This contract extends the `FxBaseChildTunnel` contract and therefore is 1-to-1 mapped with the 
 * `FxBaseRootTunnel` extended by the `Polygon_ParentMessenger` contract deployed on Polygon. This mapping ensures that
 * the internal `_processMessageFromRoot` function is only callable indirectly by the `Polygon_ParentMessenger`.

 */
contract Polygon_ChildMessenger is FxBaseChildTunnel, ChildMessengerInterface, Lockable {
    // The only child network contract that can send messages over the bridge via the messenger is the oracle spoke.
    address public oracleSpoke;
    // Store oracle hub address that oracle spoke can send messages to via `sendMessageToParent`.
    address public oracleHub;

    event SetOracleSpoke(address newOracleSpoke);
    event SetOracleHub(address newOracleHub);
    event MessageSentToParent(bytes data);
    event MessageReceivedFromParent(bytes data, address indexed parentAddress);

    /**
     * @notice Construct the Polygon_ChildMessenger contract.
     * @param _fxChild Polygon system contract deployed on Mainnet, required to construct new FxBaseRootTunnel
     * that can send messages via native Polygon data tunnel.
     */
    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function setOracleSpoke(address _oracleSpoke) public {
        require(oracleSpoke == address(0x0), "OracleSpoke already set");
        oracleSpoke = _oracleSpoke;
        emit SetOracleSpoke(oracleSpoke);
    }

    function setOracleHub(address _oracleHub) public {
        require(oracleHub == address(0x0), "OracleHub already set");
        oracleHub = _oracleHub;
        emit SetOracleHub(oracleHub);
    }

    /**
     * @notice Sends a message to the OracleSpoke via the parent messenger and the canonical message bridge.
     * @dev The caller must be the OracleSpoke on child network. No other contract is permissioned to call this
     * function.
     * @dev The L1 target, the parent messenger, must implement processMessageFromChild to consume the message.
     * @param data data message sent to the L1 messenger. Should be an encoded function call or packed data.
     */
    function sendMessageToParent(bytes memory data) public override {
        require(msg.sender == oracleSpoke, "Only callable by oracleSpoke");
        _sendMessageToRoot(abi.encode(data, oracleHub));
        emit MessageSentToParent(data);
    }

    /**
     * @notice Process a received message from the parent messenger via the canonical message bridge.
     * @dev The data will be received automatically from the state receiver when the state is synced between Ethereum
     * and Polygon. This will revert if the Root chain sender is not the `fxRootTunnel` contract.
     * @param sender The sender of `data` from the Root chain.
     * @param data ABI encoded params with which to call function on OracleHub or GovernorHub.
     */
    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        (bytes memory dataToSendToTarget, address target) = abi.decode(data, (bytes, address));
        ChildMessengerConsumerInterface(target).processMessageFromParent(dataToSendToTarget);
    }
}