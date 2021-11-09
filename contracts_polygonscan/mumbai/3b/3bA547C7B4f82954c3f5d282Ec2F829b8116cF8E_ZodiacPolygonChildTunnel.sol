// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./lib/FxBaseChildTunnel.sol";
import "./TunnelEnd.sol";

contract ZodiacPolygonChildTunnel is FxBaseChildTunnel, TunnelEnd {
  constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

  /// @dev Requests message relay to Root network
  /// @param target executor address on Root network
  /// @param data calldata passed to the executor on Root network
  /// @param gas gas limit used on Root Network for executing - 0xfffffff for unbound
  function sendMessage(
    address target,
    bytes memory data,
    uint256 gas
  ) public {
    bytes memory message = encodeIntoTunnel(target, data, gas);
    _sendMessageToRoot(message);
  }

  function _processMessageFromRoot(
    uint256,
    address sender,
    bytes memory message
  ) internal override validateSender(sender) {
    (
      bytes32 sourceChainId,
      address sourceChainSender,
      address target,
      bytes memory data,
      uint256 gas
    ) = decodeFromTunnel(message);
    forwardToTarget(sourceChainId, sourceChainSender, target, data, gas);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

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

  // Sender must be fxRootTunnel in case of ERC20 tunnel
  modifier validateSender(address sender) {
    require(
      sender == fxRootTunnel,
      "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
    );
    _;
  }

  // set fxRootTunnel if not set already
  function setFxRootTunnel(address _fxRootTunnel) external {
    require(
      fxRootTunnel == address(0x0),
      "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
    );
    fxRootTunnel = _fxRootTunnel;
  }

  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external override {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @title TunnelEnd - A contract that contains base/common functionality for ZodiacPolygonTunnel pairs
/// @author Cristóvão Honorato - <[email protected]>
contract TunnelEnd {
  bytes32 private latestSourceChainId;
  address private latestSourceChainSender;

  /// @dev Provides the end executor contract with the id of the network where the call originated
  function messageSourceChainId() public view returns (bytes32) {
    return latestSourceChainId;
  }

  /// @dev Provides the end executor contract with the address that triggered the call
  function messageSender() public view returns (address) {
    return latestSourceChainSender;
  }

  /// @dev Encodes a message to be delivered to FxRoot/FxChild
  /// @param target executor address on the other side
  /// @param data calldata passed to the executor on the other side
  /// @param gas gas limit used on the other side for executing
  function encodeIntoTunnel(
    address target,
    bytes memory data,
    uint256 gas
  ) internal view returns (bytes memory) {
    return abi.encode(getChainId(), msg.sender, target, data, gas);
  }

  /// @dev Decodes a message delivered by FxRoot/FxChild
  /// @param message encoded payload describing executor and parameters. Includes also original sender and origin network id
  function decodeFromTunnel(bytes memory message)
    internal
    pure
    returns (
      bytes32,
      address,
      address,
      bytes memory,
      uint256
    )
  {
    (
      bytes32 sourceChainId,
      address sourceChainSender,
      address target,
      bytes memory data,
      uint256 gas
    ) = abi.decode(message, (bytes32, address, address, bytes, uint256));

    return (sourceChainId, sourceChainSender, target, data, gas);
  }

  /// @dev Triggers the process of sending a message to the opposite network
  /// @param sourceChainId id of the network where the call was initiated
  /// @param sourceChainSender address that initiated the call
  /// @param target executor address on the other side
  /// @param data calldata passed to the executor on the other side
  /// @param gas gas limit used on the other side for executing
  function forwardToTarget(
    bytes32 sourceChainId,
    address sourceChainSender,
    address target,
    bytes memory data,
    uint256 gas
  ) internal {
    require(gas == 0xffffffff || (gasleft() * 63) / 64 > gas);

    latestSourceChainId = sourceChainId;
    latestSourceChainSender = sourceChainSender;
    (bool success, ) = target.call{gas: gas}(data);
    latestSourceChainSender = address(0);
    latestSourceChainId = bytes32("0x");
    require(success, "ForwardToTarget failed");
  }

  function getChainId() private pure returns (bytes32) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return bytes32(id);
  }
}