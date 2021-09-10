/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title TransferHook
 * @dev This hook will be invoked upon token transfer.
*/
interface TransferHook {

    /**
     * @dev hook function invoked when a transfer is determined as good to go
     * @param from address the ether address of sender
     * @param to address the ether address of receiver
     * @param initiator ether address of the original transaction initiator
     * @param tokenAddress ether address of the token contract
     * @param tokenAmount uint256 the amount of token you want to transfer
     */
    function invoke(address from, address to, address initiator, address tokenAddress, uint256 tokenAmount) external;
}

// File: contracts/transferHook/NOPTransferHook.sol


/**
 * @title NOPTransferHook
 * @dev A TransferHook that is completely no-op, suited only for primary issuance
*/
contract NOPTransferHook is TransferHook {

    /**
     * @dev hook function invoked when a transfer is determined as good to go
     */
    function invoke(
        address /*from*/,
        address /*to*/,
        address /*initiator*/,
        address /*tokenAddress*/,
        uint256 /*tokenAmount*/
    ) public virtual override {
    	// no-op
        return;
    }
}