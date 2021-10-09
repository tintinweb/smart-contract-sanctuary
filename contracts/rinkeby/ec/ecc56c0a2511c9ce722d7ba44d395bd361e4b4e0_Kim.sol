/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT
// written by Beomjoong Kim
pragma solidity ^0.8.0;

contract Kim{
    
    event safeTX_made(bytes32 Receipt);
    
    mapping (bytes32 => receipt) txInfo;
    
    struct receipt{
        address receiver;
        address backup;
        uint deadline;
        uint asset;
        bool claimed;
    }
    
    function Store(address receiver_, address backup_, uint deadline_) payable public {
        require (msg.value > 0);
        uint current = block.timestamp;
        
        bytes32 receipt_ = keccak256(abi.encodePacked(msg.sender, receiver_, backup_, current, deadline_, msg.value));
        
        txInfo[receipt_].receiver = receiver_;
        txInfo[receipt_].backup = backup_;
        txInfo[receipt_].deadline = block.timestamp + deadline_;
        txInfo[receipt_].asset = txInfo[receipt_].asset + msg.value;
    
        emit safeTX_made(receipt_);
    }
    
    function Receive(bytes32 receipt_) public {
        require (msg.sender == txInfo[receipt_].receiver);
        require (txInfo[receipt_].claimed == false);
        txInfo[receipt_].claimed = true;
        payable(msg.sender).transfer(txInfo[receipt_].asset);
    }
    
    function Move (bytes32 receipt_) public {
        require (block.timestamp >= txInfo[receipt_].deadline);
        require (txInfo[receipt_].claimed == false);
        txInfo[receipt_].claimed = true;
        payable(txInfo[receipt_].backup).transfer(txInfo[receipt_].asset);
    }
}