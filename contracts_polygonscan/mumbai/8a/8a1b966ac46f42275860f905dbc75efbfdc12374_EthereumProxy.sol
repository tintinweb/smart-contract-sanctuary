// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IFxMessageProcessor} from '@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol';

/// @title Ethereum proxy contract
/// @dev This contract represents another contract on L1
contract EthereumProxy is IFxMessageProcessor {
    /// @notice The tunnel contract on the child network, i.e. Polygon
    address public immutable fxChild;

    /// @notice The address of the L1 owner contract, i.e. Ethereum L1 owner address
    address public immutable l1Owner;

    constructor(address _fxChild, address _l1Owner) {
        fxChild = _fxChild;
        l1Owner = _l1Owner;
    }

    /// @dev Emitted when this contract simply receives some currency
    event Received(uint256 value);

    /// @dev If necessary, this contract can accept funds so that it may send funds
    receive() external payable {
        emit Received(msg.value);
    }

    /// @dev This function is how messages are delivered from the polygon message passing contract to polygon contracts.
    function processMessageFromRoot(
        uint256, /*stateId*/
        address sender,
        bytes memory message
    ) external override {
        require(msg.sender == fxChild, 'Can only be called by the state sync child contract');
        require(sender == l1Owner, 'L1 sender must be the owner');

        (address[] memory targets, bytes[] memory datas, uint256[] memory values) = abi.decode(
            message,
            (address[], bytes[], uint256[])
        );

        require(targets.length == datas.length && targets.length == values.length, 'Inconsistent argument lengths');
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(datas[i]);
            require(success, 'Sub-call failed');
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
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