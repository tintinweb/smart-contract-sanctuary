// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { FxBaseChildTunnel } from './base/FxBaseChildTunnel.sol';

/** 
 * @title VRFChildTunnel - Polygon (Matic)
 */
contract VRFChildTunnel is FxBaseChildTunnel {

  /// @dev Polygon state bridge variables.
  uint256 public latestStateId;
  address public latestRootMessageSender;

  uint public customValue;

  /// @dev Message types.
  bytes32 public constant REQUEST = keccak256("REQUEST");
  bytes32 public constant RESPONSE = keccak256("RESPONSE");

  /// @dev Mapping from randomness request Id => random number received from Chalink VRF on matic.
  mapping(uint => uint) public randomNumber;

  /// @dev Mapping from Chainlink VRF's bytes request ID => this contracts uint request ID
  mapping(bytes32 => uint) public requestIds;

  /// @dev Events.
  event RandomnessRequest(address indexed requestor, uint requestId, bytes32 chainlinkBytesId);
  event RandomnessFulfilled(uint indexed requestId, bytes32 chainlinkBytesId, uint randomNumber); 

  constructor(
    address _fxChild
  ) FxBaseChildTunnel(_fxChild) {
  }

  /// @dev Recives message from Root in Ethereum.
  function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data) internal override validateSender(sender) {

    // Polygon state bridge variables.
    latestStateId = stateId;
    latestRootMessageSender = sender;

    // Get randomness request from data.
    (bytes32 messageType, address requestor, uint requestId) = abi.decode(data, (bytes32, address, uint));

    customValue = requestId;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) public {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public override {
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
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

