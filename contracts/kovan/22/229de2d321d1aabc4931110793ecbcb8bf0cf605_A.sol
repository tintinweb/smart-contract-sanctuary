/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract A {
    
    address public temp;
    bytes tempBytes;

    function executeProposal(bytes calldata data) external {
        uint256       amount;
        uint256       lenDestinationRecipientAddress;
        bytes  memory destinationRecipientAddress;

        (amount, lenDestinationRecipientAddress) = abi.decode(data, (uint, uint));
        destinationRecipientAddress = bytes(data[64:64 + lenDestinationRecipientAddress]);

        bytes20 recipientAddress;

        assembly {
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }
        
        tempBytes = destinationRecipientAddress;
        temp = address(recipientAddress);
    }
    
}