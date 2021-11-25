pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/factory/IL2Factory.sol";
import "../tunnel/FxBaseChildTunnel.sol";
import {FactoryData} from "../type/Tunnel.sol";

contract L2Factory is Initializable, IL2Factory, FxBaseChildTunnel {
    mapping(bytes32 => FactoryData) private protocol;

    function initialize(address _fxChild) public virtual initializer {
        FxBaseChildTunnel.setInitialParams(_fxChild);
    }

    function fetchProtocolInfo(bytes32 protocolName)
        public
        view
        virtual
        returns (FactoryData memory)
    {
        return protocol[protocolName];
    }

    function fetchProtocolAddressL2(bytes32 protocolName)
        public
        view
        virtual
        returns (address)
    {
        return protocol[protocolName].protocolAddressL2;
    }

    function fetchTokenAddressL2(bytes32 protocolName)
        public
        view
        virtual
        override
        returns (address)
    {
        return protocol[protocolName].tokenAddressL2;
    }

    function _processMessageFromRoot(
        uint256 _stateId,
        address _sender,
        bytes memory _data
    ) internal override validateSender(_sender) {
        FactoryData memory data = abi.decode(_data, (FactoryData));
        protocol[data.protocolName] = data;
        emit ProtocolUpdated(
            data.protocolName,
            data.protocolAddressL1,
            data.protocolAddressL2,
            data.tokenAddressL1,
            data.tokenAddressL2,
            data.stablecoinL1,
            data.stablecoinL2
        );
    }

    function mockProcessMessageFromRoot(
        address protocolL1,
        address protocolL2,
        address stablecoinL1,
        address stablecoinL2,
        address tokenL1,
        address tokenL2,
        bytes32 name
    ) external {
        FactoryData memory data = FactoryData(
            name,
            tokenL1,
            tokenL2,
            protocolL1,
            protocolL2,
            stablecoinL1,
            stablecoinL2
        );
        _processMessageFromRoot(1, msg.sender, abi.encode(data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

pragma solidity ^0.8.8;

import {FactoryData} from "../../type/Tunnel.sol";

interface IL2Factory {
    event ProtocolUpdated(
        bytes32 protocolName,
        address protocolAddressL1,
        address protocolAddressL2,
        address tokenAddressL1,
        address tokenAddressL2,
        address stablecoinL1,
        address stablecoinL2
    );

    function fetchProtocolInfo(bytes32 protocolName)
        external
        view
        returns (FactoryData memory);

    function fetchProtocolAddressL2(bytes32 protocolName)
        external
        view
        returns (address);

    function fetchTokenAddressL2(bytes32 protocolName)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract FxBaseChildTunnel is IFxMessageProcessor, Initializable {
    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

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

    function setInitialParams(address _fxChild) public virtual initializer {
        fxChild = _fxChild;
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

pragma solidity ^0.8.8;

struct DepositData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

struct RedemptionData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

struct MintedData {
    uint256 batchId;
    uint256[] tokens;
}

struct RedeemedData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

struct FactoryData {
    bytes32 protocolName;
    address tokenAddressL1;
    address tokenAddressL2;
    address protocolAddressL1;
    address protocolAddressL2;
    address stablecoinL1;
    address stablecoinL2;
}