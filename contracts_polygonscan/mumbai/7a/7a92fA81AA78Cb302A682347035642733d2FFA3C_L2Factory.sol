// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import {FactoryData} from "../type/Tunnel.sol";
import "../tunnel/FxBaseChildTunnel.sol";

contract L2Factory is FxBaseChildTunnel {
    mapping(bytes => address[]) private detfConstituentsL1;
    mapping(bytes => address[]) private detfConstituentsL2;

    // constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function init(address _fxChild) public virtual {
        FxBaseChildTunnel.initalize(_fxChild);
    }

    // Only used for testing. Comment before deployment
    function mockProcessMessageFromRoot(
        address[] memory _l1,
        address[] memory _l2,
        string memory _detfName
    ) external {
        FactoryData memory factoryData;
        factoryData.l1 = _l1;
        factoryData.l2 = _l2;
        factoryData.detfName = bytes(_detfName);
        bytes memory _data = abi.encode(factoryData);
        _processMessageFromRoot(1, address(this), _data);
    }

    function fetchDetfConstituents(string memory _detfName)
        public
        view
        virtual
        returns (address[] memory)
    {
        return (detfConstituentsL2[bytes(_detfName)]);
    }

    // State Tunnel Functions.
    function _processMessageFromRoot(
        uint256 _stateId,
        address _sender,
        bytes memory _data
    ) internal override validateSender(_sender) {
        // Logic to process message from root goes in here
        FactoryData memory data = abi.decode(_data, (FactoryData));
        detfConstituentsL1[data.detfName] = data.l1;
        detfConstituentsL2[data.detfName] = data.l2;
    }

    function sendMessageToRoot(bytes memory _message) internal {
        _sendMessageToRoot(_message);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * represents the tokens minted per batch.
 */
struct DepositData {
    uint256 id;
    bytes[] detfs;
    uint256[] amounts;
}

// Represents the tokens to be redeemed.
struct RedemptionData {
    uint256 id;
    address[] tokens;
    uint256[] amounts;
}

// Avoiding nested maps for using data in memory.
// Preventing use of storage in state-tunnels.
struct MintedData {
    uint256 id;
    bytes detfName;
    address[] tokens;
    uint256[] amounts;
}

// Redeemed Data
struct RedeemedData {
    uint256 id;
    address token;
    uint256 amount;
}

// Factory Data
struct FactoryData {
    bytes detfName;
    address[] l1;
    address[] l2;
}

struct DetfData {
    bytes detfName;
    address stablecoin;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

    function initalize(address _fxChild) public virtual {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}