// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./lib/FxBaseChildTunnel.sol";
import "./TunnelTip.sol";

contract ZodiacPolygonChildTunnel is FxBaseChildTunnel {
  bytes public latestData;

  constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

  function sendMessage(
    address target,
    bytes memory data,
    uint256 gas
  ) public {
    bytes memory message = abi.encode(msg.sender, target, data, gas);
    _sendMessageToRoot(message);
  }

  function _processMessageFromRoot(
    uint256 stateId,
    address sender,
    bytes memory data
  ) internal override validateSender(sender) {
    (stateId);
    (sender);
    latestData = data;
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

contract TunnelTip {
  address private foreignMessageSender;

  function processMessage(bytes memory message) internal {
    (address sender, address target, bytes memory data, uint256 gas) = abi
      .decode(message, (address, address, bytes, uint256));

    require(gas == 0xffffffff || (gasleft() * 63) / 64 > gas);

    foreignMessageSender = sender;
    (bool success, bytes memory returnData) = target.call{gas: gas}(data);
    validateExecutionStatus(success, returnData);
    foreignMessageSender = address(0);
  }

  function messageSender() public view returns (address) {
    return foreignMessageSender;
  }

  function messageSourceChainId() public pure returns (bytes32) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return bytes32(id);
  }

  function validateExecutionStatus(bool success, bytes memory returnData)
    private
    pure
  {
    (returnData);
    require(success);
  }
}