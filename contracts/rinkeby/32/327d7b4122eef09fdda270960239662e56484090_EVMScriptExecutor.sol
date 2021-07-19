/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT AND GPL-3.0
// File: OpenZeppelin/[email protected]/contracts/utils/StorageSlot.sol


pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// File: contracts/EvmScriptExecutor.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;


interface ICallsScript {
    function execScript(
        bytes memory _script,
        bytes memory,
        address[] memory _blacklist
    ) external returns (bytes memory);
}

/// @author psirex
/// @notice Contains method to execute EVMScripts
/// @dev EVMScripts use format of Aragon's https://github.com/aragon/aragonOS/blob/v4.0.0/contracts/evmscript/executors/CallsScript.sol executor
contract EVMScriptExecutor {
    // -------------
    // EVENTS
    // -------------
    event ScriptExecuted(address indexed _caller, bytes _evmScript);

    // ------------
    // CONSTANTS
    // ------------

    // This variable required to use deployed CallsScript.sol contract because
    // CalssScript.sol makes check that caller contract is not petrified (https://hack.aragon.org/docs/common_Petrifiable)
    // Contains value: keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION =
        0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    // ------------
    // VARIABLES
    // ------------

    /// @notice Address of deployed CallsScript.sol contract
    address public immutable callsScript;

    /// @notice Address of depoyed easyTrack.sol contract
    address public immutable easyTrack;

    /// @notice Address of Aragon's Voting contract
    address public immutable voting;

    // -------------
    // CONSTRUCTOR
    // -------------

    constructor(
        address _callsScript,
        address _easyTrack,
        address _voting
    ) {
        voting = _voting;
        easyTrack = _easyTrack;
        callsScript = _callsScript;
        StorageSlot.getUint256Slot(INITIALIZATION_BLOCK_POSITION).value = block.number;
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Executes EVMScript
    /// @dev Uses deployed Aragon's CallsScript.sol contract to execute EVMScript.
    /// @return Empty bytes
    function executeEVMScript(bytes memory _evmScript) external returns (bytes memory) {
        require(msg.sender == voting || msg.sender == easyTrack, "CALLER_IS_FORBIDDEN");

        bytes memory execScriptCallData =
            abi.encodeWithSelector(
                ICallsScript.execScript.selector,
                _evmScript,
                new bytes(0),
                new address[](0)
            );
        (bool success, bytes memory output) = callsScript.delegatecall(execScriptCallData);
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
        emit ScriptExecuted(msg.sender, _evmScript);
        return abi.decode(output, (bytes));
    }
}