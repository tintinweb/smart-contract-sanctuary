// hevm: flattened sources of contracts/Proxy.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.7 <0.9.0;

////// contracts/SlotManipulatable.sol
/* pragma solidity ^0.8.7; */

abstract contract SlotManipulatable {

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

////// contracts/interfaces/IDefaultImplementationBeacon.sol
/* pragma solidity ^0.8.7; */

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /// @dev The address of an implementation for proxies.
    function defaultImplementation() external view returns (address defaultImplementation_);

}

////// contracts/Proxy.sol
/* pragma solidity ^0.8.7; */

/* import { IDefaultImplementationBeacon } from "./interfaces/IDefaultImplementationBeacon.sol"; */

/* import { SlotManipulatable } from "./SlotManipulatable.sol"; */

/// @title A completely transparent, and thus interface-less, proxy contract.
contract Proxy is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /**
     *  @dev   The constructor requires at least one of `factory_` or `implementation_`.
     *         If an implementation is not provided, the factory is treated as an IDefaultImplementationBeacon to fetch the default implementation.
     *  @param factory_        The address of a proxy factory, if any.
     *  @param implementation_ The address of the implementation contract being proxied, if any.
     */
    constructor(address factory_, address implementation_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));

        // If the implementation is empty, fetch it from the factory, which can act as a beacon.
        address implementation = implementation_ == address(0) ? IDefaultImplementationBeacon(factory_).defaultImplementation() : implementation_;

        require(implementation != address(0));

        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation))));
    }

    fallback() payable external virtual {
        bytes32 implementation = _getSlotValue(IMPLEMENTATION_SLOT);

        require(address(uint160(uint256(implementation))).code.length != uint256(0));

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

}