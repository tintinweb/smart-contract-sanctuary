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


    bool public success = false;

    function updateSuccess(bool suc) external {
        success = suc;
    }

    /**
     * @notice Verifies that the signer is the owner of the signing contract.
     */
    function isValidSignature(bytes32 _message, bytes calldata _signature) public view returns (bool) {
        // Validate signatures
        return success;
    }
}