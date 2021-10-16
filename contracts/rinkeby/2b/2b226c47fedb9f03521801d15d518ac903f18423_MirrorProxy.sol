// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MirrorProxy
 * @author MirrorXYZ
 * The MirrorProxy contract is used to deploy minimal contracts for multiple
 * economic producers on the Mirror ecosystem (e.g. crowdfunds, editions). The
 * proxies are used with the proxy-relayer pattern. The proxy delegates calls
 * to a relayer contract that calls into the storage contract. The proxy uses the
 * EIP-1967 standard to store the "implementation" logic, which in our case is
 * the relayer contract. The relayer logic is directly stored into the standard
 * slot using `sstore` in the constructor, and read using `sload` in the fallback
 * function.
 */
contract MirrorProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Initializes a proxy by delegating logic to the relayer,
     * and reverts if the call is not successful. Stores relayer logic.
     * @param relayer - the relayer holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address relayer, bytes memory initializationData) {
        // Delegatecall into the relayer, supplying initialization calldata.
        (bool ok, ) = relayer.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, relayer)
        }
    }

    /**
     * @notice When any function is called on this contract, we delegate to
     * the logic contract stored in the implementation storage slot.
     */
    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}