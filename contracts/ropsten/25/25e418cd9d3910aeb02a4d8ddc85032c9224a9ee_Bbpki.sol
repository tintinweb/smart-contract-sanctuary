/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;


contract Bbpki {

// state variables

address owner;
mapping (uint => certificate) public certificates;
mapping (uint => certificateAuthority) public cAuthorities;
bytes32[] public caHashes;
uint256 public noOfcertificates = 0;
uint256 public noOfCA = 0;
bytes32 public bhash;

// constructor
constructor () {
owner = msg.sender;
bhash = blockhash(block.number);
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
        uint256 serialNumber;
        string subjectName;
        string organisation;
        string issuer;
        uint expiry;
        uint256 noOfSignatures;
        certificateStatus Status;
        string[] signatures;
    }

    struct certificateAuthority {
    uint id;
    string nameCA;
    }

   

    // events
    // certificate authority registeration event
    event caRegistered (uint noOfCA, string _name );

    // certificate signing event
    event certificateSigned(
    uint256 serialNumber,
    string  subjectName, 
     string  organisation,
     string  issuer,
     uint256 expiry,
     uint256 noOfSignatures,
     certificateStatus Status,
     string[] signatures
      );

    // functions 
    function registerCA (string memory _name) public onlyOwner{
        require ((bytes(_name).length > 0));
        require(noOfCA < 10);
        noOfCA++;
        cAuthorities[noOfCA] = certificateAuthority(noOfCA, _name);
        emit caRegistered (noOfCA, _name);
    }
    
    function b () public view returns (bytes32) {
        return bhash;
    }


    function signCertificate(string memory subjectName, string memory organisation) public returns (
     uint256 serialNumber,
     string memory, 
     string memory,
     string memory issuer,
     uint256 expiry,
     uint256 noOfSignatures,
     certificateStatus,
     string[] memory
     

     ) {
    serialNumber = block.timestamp/8;
    noOfcertificates++;

    // generate a random number between 3 and 10 inclusive to determine the number of CA to sign the certificate automatically
    uint caRequired = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 9;
    if (caRequired <3){
        caRequired = caRequired + 3;
        }
        else {
          caRequired = caRequired + 1;   
        }
    for (uint i = 1; i < caRequired; i++)
    {
    certificates[serialNumber].signatures.push(cAuthorities[i].nameCA);
    }
  
    // generate a random number between 1 and "caRequired" to select the issuer of the certificate
    uint cIssuer = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % caRequired;
    if (cIssuer < 1){
        cIssuer = cIssuer + 1;
        }
    issuer = cAuthorities[cIssuer].nameCA;
    noOfSignatures = caRequired;
   expiry = block.timestamp + (365*24*60*60);
 //   (uint year,uint month,uint day) = BokkyPooBahsDateTimeLibrary.timestampToDate(a);
    
 certificateStatus Status = certificateStatus.active;
certificates[serialNumber].serialNumber = serialNumber;
certificates[serialNumber].subjectName = subjectName;
certificates[serialNumber].organisation = organisation;
certificates[serialNumber].issuer = issuer;
certificates[serialNumber].expiry = expiry;
certificates[serialNumber].noOfSignatures = noOfSignatures;
certificates[serialNumber].Status = Status;

  //  certificates[noOfcertificates] = certificate(serialNumber, subjectName, organisation, issuer, expiry, noOfSignatures,defaultStatus,signatures);
     emit certificateSigned(serialNumber, subjectName, organisation, issuer, expiry, noOfSignatures,Status,certificates[noOfcertificates].signatures);
     return (serialNumber, subjectName, organisation, issuer, expiry, noOfSignatures,Status,certificates[noOfcertificates].signatures );
    }

    function revokeCertificate (uint256 serialNumber) public onlyOwner returns (string memory){
     certificateStatus status = certificateStatus.revoked;
     certificates[serialNumber].Status = status;
    return "revoked";
    }

    function countCertificates() view public returns (uint){ //Count how many users create certificates
      return noOfcertificates;
    }
}