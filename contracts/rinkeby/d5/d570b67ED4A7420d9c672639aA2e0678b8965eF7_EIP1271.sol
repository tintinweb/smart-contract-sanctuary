/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: EIP1271.sol

/**
 * @dev
 */
contract EIP1271 {


    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    bool public success = false;

    function updateSuccess(bool suc) external {
        success = suc;
    }

    /**
     * @notice Verifies that the signer is the owner of the signing contract.
     */
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4) {
        // Validate signatures
        if (success) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }
}