// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Inheritance
import "./LegacyOwned.sol";

// Internal references
import "./interfaces/IOwnerRelayOnOptimism.sol";
import "@eth-optimism/contracts/iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

contract OwnerRelayOnEthereum is LegacyOwned {
    address public MESSENGER;
    address public CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM;
    uint32 public constant MAX_CROSS_DOMAIN_GAS_LIMIT = 8e6;

    // ========== CONSTRUCTOR ==========
    constructor(
        address _owner,
        address _messengerAddress,
        address _relayOnOptimism
    ) public LegacyOwned(_owner) {
        MESSENGER = _messengerAddress;
        CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM = _relayOnOptimism;
    }

    /* ========== INTERNALS ============ */

    function _messenger() private view returns (iAbs_BaseCrossDomainMessenger) {
        return iAbs_BaseCrossDomainMessenger(MESSENGER);
    }

    function _getCrossDomainGasLimit(uint32 crossDomainGasLimit)
        private
        view
        returns (uint32)
    {
        // Use specified crossDomainGasLimit if specified value is not zero.
        // otherwise use the default in SystemSettings.
        return
            crossDomainGasLimit != 0
                ? crossDomainGasLimit
                : MAX_CROSS_DOMAIN_GAS_LIMIT;
    }

    /* ========== RESTRICTED ========== */

    function initiateRelay(
        address target,
        bytes calldata payload,
        uint32 crossDomainGasLimit // If zero, uses default value in SystemSettings
    ) external onlyOwner {
        IOwnerRelayOnOptimism ownerRelayOnOptimism;
        bytes memory messageData = abi.encodeWithSelector(
            ownerRelayOnOptimism.finalizeRelay.selector,
            target,
            payload
        );

        _messenger().sendMessage(
            CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM,
            messageData,
            _getCrossDomainGasLimit(crossDomainGasLimit)
        );

        emit RelayInitiated(target, payload);
    }

    function initiateRelayBatch(
        address[] calldata targets,
        bytes[] calldata payloads,
        uint32 crossDomainGasLimit // If zero, uses default value in SystemSettings
    ) external onlyOwner {
        // First check that the length of the arguments match
        require(targets.length == payloads.length, "Argument length mismatch");

        IOwnerRelayOnOptimism ownerRelayOnOptimism;
        bytes memory messageData = abi.encodeWithSelector(
            ownerRelayOnOptimism.finalizeRelayBatch.selector,
            targets,
            payloads
        );

        _messenger().sendMessage(
            CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM,
            messageData,
            _getCrossDomainGasLimit(crossDomainGasLimit)
        );

        emit RelayBatchInitiated(targets, payloads);
    }

    /* ========== EVENTS ========== */

    event RelayInitiated(address target, bytes payload);
    event RelayBatchInitiated(address[] targets, bytes[] payloads);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract LegacyOwned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;
pragma experimental ABIEncoderV2;

interface IOwnerRelayOnOptimism {
    function finalizeRelay(address target, bytes calldata payload) external;

    function finalizeRelayBatch(
        address[] calldata target,
        bytes[] calldata payloads
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iAbs_BaseCrossDomainMessenger
 */
interface iAbs_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/

    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);
    event FailedRelayedMessage(bytes32 msgHash);


    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);


    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}