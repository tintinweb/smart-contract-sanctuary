/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

contract TestSlots {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor() {
        updateSlot(_IMPLEMENTATION_SLOT, bytes32(bytes20(0x1C0EeEF670d82498F7547062Aac7eE2143eC52ff)));
    }
    /**
    * Allow storage slots to be manually updated
    */
    function updateSlot(bytes32 slot, bytes32 value) public {
        assembly {
            sstore(slot, value)
        }
    }

    /**
    * Get storage slot value
    */
    function getSlot(bytes32 slot) public view returns (bytes32) {
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
}