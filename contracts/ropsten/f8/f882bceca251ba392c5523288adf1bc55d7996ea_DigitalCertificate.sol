/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract DigitalCertificate {
    enum CertificateStatus{ CREATED, DROPPED, ISSUED }

    //Certificate issuer (ADMIN)
    address public issuer;
    
    //Certificate value of keccak256(receiver_name + certificate_no + certificate_title + description_text + certificate_score + certificate_date)
    bytes32 public certificateHash;

    //Certificate receiver
    address public receiver;
    bool public signedByReceiver;

    //Certificate signer
    uint256 public totalApprover;
    uint public totalSignature;
    address[] public approvers;
    bool[] public signedByApprovers;

    CertificateStatus public status;

    event CertificateDropped(uint256 date);
    event CertificateIssued(uint256 date);
    event SignedByReceiver(address receiver, uint256 date);
    event SignedByApprover(address approver, uint256 date);

    constructor(bytes32 _certificateHash, address _receiver, address[] memory _approvers) {
        issuer = msg.sender;
        certificateHash = _certificateHash;
        receiver = _receiver;
        approvers = _approvers;
        status = CertificateStatus.CREATED;
        totalApprover = _approvers.length;
        uint256 index;
        for(index = 0; index < totalApprover; index++) {
            signedByApprovers.push(false);
        }
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, 'Invalid issuer');
        _;
    }
    
    function dropCertificate() public onlyIssuer {
        status = CertificateStatus.DROPPED;
        emit CertificateDropped(block.timestamp);
    }
    
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    
    function receiverSigning(bytes memory signature) public {
        require(status == CertificateStatus.CREATED, 'invalid certificate status');
        require(totalSignature == totalApprover, 'waiting for approver signature');
        require(!signedByReceiver, 'already signed by receiver');
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, certificateHash));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        require(ecrecover(prefixedHash, v, r, s) == receiver, 'invalid receiver signature');
        
        signedByReceiver = true;
        status = CertificateStatus.ISSUED;
        emit SignedByReceiver(receiver, block.timestamp);
        emit CertificateIssued(block.timestamp);
    }
    
    function approverSigning(bytes memory signature) public {
        require(status == CertificateStatus.CREATED, 'invalid certificate status');
        int approverIndex = -1;
        uint256 index;
        for (index = 0; index < approvers.length; index++) {
            if (approvers[index] == msg.sender) {
                approverIndex = int(index);
            }
        }
        require(approverIndex >= 0, 'approver not found');
        require(!signedByApprovers[uint256(approverIndex)], 'already signed');
        if (approverIndex > 0) {
            require(signedByApprovers[uint256(approverIndex - 1)], 'waiting for other approver');
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, certificateHash));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        require(ecrecover(prefixedHash, v, r, s) == approvers[uint256(approverIndex)], 'invalid approver signature');
        
        signedByApprovers[uint256(approverIndex)] = true;
        totalSignature = totalSignature + 1;
        emit SignedByApprover(approvers[uint256(approverIndex)], block.timestamp);
    }
}