/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract Bbpki {

// state variables

address owner;
mapping (uint => certificate) public certificates;
uint256 public noOfcertificates = 0;

// constructor
constructor () public {
owner = msg.sender;
}

 // enumerations (predetermined values)
    enum certificateStatus {active, revoked, expired}

// access restrictions
modifier onlyOwner (){
require (owner == msg.sender);
    _;
}



// structures

    struct certificate {
        string version;
        uint256 serialNumber;
        string subjectName;
        string publicKey;
        uint256 validity;
        string issuer;
        string[] Multisignatures;
        string  certificateSignature; 
        bool  certificateStatus;
        uint256 blockNumber;
    }

   

    // events
    // certificate authority registeration event
    event header (uint notBefore, uint notAfter, uint blockNumber);

    // certificate signing event
    event certificateSigned(
        string version,
        uint256 serialNumber,
        string subjectName,
        string publicKey,
        uint256 blockNumber
      );
      
      event addcertpropss(
        
        string issuer,
        string[] Multisignatures,
        string  certificateSignature, 
        bool  certificateStatus,
        uint256 validity
      );
    


    function issueCertificate(
        string memory _version,
        uint256 _serialNumber,
        string memory _subjectName,
        string memory _publicKey,
        uint256 _validity,
        string memory _issuer,
        string[] memory _Multisignatures,
        string memory  _certificateSignature, 
        bool  _certificateStatus
    ) public returns (
        string memory,
        uint256 ,
        string memory,
        string memory,
        uint256
      
     ) {
    noOfcertificates++;
certificates[_serialNumber].serialNumber = _serialNumber;
certificates[_serialNumber].version = _version;
certificates[_serialNumber].subjectName = _subjectName;
certificates[_serialNumber].publicKey = _publicKey;
certificates[_serialNumber].blockNumber = block.number;

addcertprops( _serialNumber, _issuer, _Multisignatures, _certificateSignature, _certificateStatus, _validity); 


  //  certificates[noOfcertificates] = certificate(serialNumber, subjectName, organisation, issuer, expiry, noOfSignatures,defaultStatus,signatures);
     emit certificateSigned(
        _version,
        _serialNumber,
        _subjectName,
        _publicKey,
        block.number);
     return ( 
         _version,
        _serialNumber,
        _subjectName,
        _publicKey,
        block.number
        );
    }

    function addcertprops(
        uint256 _serialNumber,
        string memory _issuer,
        string[] memory _Multisignatures,
        string memory  _certificateSignature, 
        bool  _certificateStatus,
        uint256 _validity
    ) public returns (
        string memory,
        string[] memory,
        string memory, 
        bool,
        uint256
      
     ) {
certificates[_serialNumber].issuer = _issuer;
certificates[_serialNumber].certificateStatus = _certificateStatus;
certificates[_serialNumber].Multisignatures = _Multisignatures;
certificates[_serialNumber].certificateSignature = _certificateSignature;
certificates[_serialNumber].validity = _validity;



  //  certificates[noOfcertificates] = certificate(serialNumber, subjectName, organisation, issuer, expiry, noOfSignatures,defaultStatus,signatures);
     emit addcertpropss(
        _issuer,
        _Multisignatures,
        _certificateSignature, 
        _certificateStatus,
        _validity
        );
     return ( _issuer ,_Multisignatures, _certificateSignature,  _certificateStatus, _validity);
    }


    function revokeCertificate (uint256 _serialNumber) public returns (bool){
     certificates[_serialNumber].certificateStatus = false;
    return false;
    }
    
    function clientVerifyCert(uint _serialNumber) public view returns (uint){
        return certificates[_serialNumber].blockNumber;
    }

    function countCertificates() view public returns (uint){ //Count how many users create certificates
      return noOfcertificates;
    }
    
    
}