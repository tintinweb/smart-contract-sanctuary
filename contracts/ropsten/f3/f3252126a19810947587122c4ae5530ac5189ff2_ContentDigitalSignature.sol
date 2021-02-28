/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.1;

/// @author Gil Brodsky
/// @title Proof of digital artifact existence - www.ourwebsite.com

library Library {
    struct signatureEnvelope {
        string fullName;
        string description;
        uint timestamp;
        uint lastUpdateTimestamp;
        bool isValue;
        address senderAddress;
   }
}

contract ContentDigitalSignature {
    uint public transactionAmount;
    address public ownerAddress;
    address payable public payableAddress;
    mapping(string => Library.signatureEnvelope ) public digital_signature_timestamp_unix;
    
    constructor() public {
        ownerAddress = msg.sender;
        transactionAmount = 5000000000000000; // in Wei = 0.005 ETH
        payableAddress=payable(0x962c10A6512c35b4cd14d876bb70dEA433798f41);
    }
    
    modifier onlyOwner() {
        require (msg.sender == ownerAddress);
        _;
    }
    
    function setPayableAddress(address payable _payableAddress) onlyOwner public {
        payableAddress=_payableAddress;
    }
    
    function setTransactionAmount(uint _transactionAmount) onlyOwner public {
        transactionAmount=_transactionAmount;
    }
    
    function withdraw() onlyOwner public payable {
        require(address(this).balance >= 0);
        payableAddress.transfer(address(this).balance);
    }
    
    function makePayment() private {
        require(msg.value >= transactionAmount);
        payableAddress.transfer(msg.value);
    }
    
    function create(string memory _contentSignature, string memory _fullName, string memory _description) public payable {
        if (!digital_signature_timestamp_unix[_contentSignature].isValue) {
            if (msg.sender!=ownerAddress) {
               makePayment();
            }
            Library.signatureEnvelope memory _envelope;
            _envelope.fullName = _fullName;
            _envelope.description = _description;
            _envelope.timestamp = block.timestamp;
            _envelope.lastUpdateTimestamp = block.timestamp;
            _envelope.isValue = true;
            _envelope.senderAddress = msg.sender;
            digital_signature_timestamp_unix[_contentSignature] = _envelope;
        }
    }
    
    function updateOwner(string memory _contentSignature, string memory _fullName) public payable {
        if (digital_signature_timestamp_unix[_contentSignature].isValue && digital_signature_timestamp_unix[_contentSignature].senderAddress == msg.sender) {
            if (msg.sender!=ownerAddress) {
                makePayment();
            }
            digital_signature_timestamp_unix[_contentSignature].fullName = _fullName;
            digital_signature_timestamp_unix[_contentSignature].lastUpdateTimestamp = block.timestamp;
        } 
    }
}