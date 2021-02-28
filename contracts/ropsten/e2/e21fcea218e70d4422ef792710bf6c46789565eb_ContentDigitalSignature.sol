/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.7;

/// @author Gil Brodsky
/// @title Proof of digital artifact existence - www.ourwebsite.com

contract ContentDigitalSignature {
    
    struct SignatureEnvelope {
        string fullName;
        string description;
        address senderAddress;
        bool isValue;
        uint timestamp;
        uint lastUpdateTimestamp;
    }    
    
    uint public transactionAmount;
    address public ownerAddress;
    address payable public payableAddress;
    mapping(string => SignatureEnvelope ) public  digital_signature;
    
    constructor() public {
        ownerAddress = msg.sender;
        transactionAmount = 5000000000000000; // in Wei = 0.005 ETH
        payableAddress=0x962c10A6512c35b4cd14d876bb70dEA433798f41;
    }
    
    event Create(address indexed _from, string _contentSignature, string _fullName, string _description);
    
    function create(string memory _contentSignature, string memory _fullName, string memory _description) public payable {
        if (!digital_signature[_contentSignature].isValue) {
            if (msg.sender!=ownerAddress) {
               makePayment("C");
            }
            SignatureEnvelope memory _envelope;
            _envelope.fullName = _fullName;
            _envelope.description = _description;
            _envelope.timestamp = block.timestamp;
            _envelope.lastUpdateTimestamp = block.timestamp;
            _envelope.isValue = true;
            _envelope.senderAddress = msg.sender;
            digital_signature[_contentSignature] = _envelope;
            emit Create(msg.sender, _contentSignature, _fullName, _description);
        }
    }
    
    event UpdateOwner(address indexed _from, string _contentSignature, string _fullName);
    
    function updateOwner(string memory _contentSignature, string memory _fullName) public payable {
        if (digital_signature[_contentSignature].isValue && digital_signature[_contentSignature].senderAddress == msg.sender) {
            if (msg.sender!=ownerAddress) {
                makePayment("U");
            }
            digital_signature[_contentSignature].fullName = _fullName;
            digital_signature[_contentSignature].lastUpdateTimestamp = block.timestamp;
            
            emit UpdateOwner(msg.sender, _contentSignature, _fullName);
        } 
    }
    
    event Payment(address indexed _from, uint _value, string mode);
    
    function makePayment(string memory mode) private {
        require(msg.value >= transactionAmount);
        payableAddress.transfer(msg.value);
        emit Payment(msg.sender, msg.value, mode);
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
    
    event Withdraw(address indexed _from, uint _value);
    
    function withdraw() onlyOwner public payable {
        require(address(this).balance >= 0);
        payableAddress.transfer(address(this).balance);
        emit Withdraw(msg.sender, address(this).balance);
    }
}