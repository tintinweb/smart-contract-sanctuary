/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title TransferController
 * @dev This contract contains the logic that enforces KYC transferability rules as outlined by a securities commission
*/
interface TransferController {

    /**
     * @dev Check if tokenAmount of token can be transfered from from address to to address, initiatied by initiator address
     * @param from address the ether address of sender
     * @param to address the ether address of receiver
     * @param initiator ether address of the original transaction initiator
     * @param tokenAddress ether address of the token contract
     * @param tokenAmount uint256 the amount of token you want to transfer
     * @return 0 if successful, positive integer if error occurred
     */
    function check(address from, address to, address initiator, address tokenAddress, uint256 tokenAmount) external view returns (uint256);
}

// File: contracts/transferController/HaltingTransferController.sol


/**
 * @title HaltingTransferController
 * @dev Halts all transfers
*/
contract HaltingTransferController is TransferController {

    function check(
        address /*from*/,
        address /*to*/,
        address /*initiator*/,
        address /*tokenAddress*/,
        uint256 /*tokenAmount*/
    ) public virtual override view returns (uint256) {
        return 503;
    }
}