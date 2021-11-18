/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/poly-portal-poc/contracts/contracts/examples/OrcsPortal/OrcsPoly.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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


/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/poly-portal-poc/contracts/contracts/examples/OrcsPortal/OrcsPoly.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import { FxBaseChildTunnel } from '../../tunnel/FxBaseChildTunnel.sol';

/** 
 * @title FxStateChildTunnel
 */
contract OrcsPoly is FxBaseChildTunnel {
    
    mapping(uint256 => address) public orcs;
    mapping(uint256 => bool) public onPoly;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {

    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {

        (uint256 id, address owner ) = abi.decode(data, (uint256, address));
        orcs[id] = owner;
        onPoly[id] = true;
    }

    function travelBack(uint256 id) public {
        require(msg.sender == orcs[id] && onPoly[id], "orc in the wrong state");
        onPoly[id] = false;
        _sendMessageToRoot(abi.encode(id, msg.sender));
    }
}