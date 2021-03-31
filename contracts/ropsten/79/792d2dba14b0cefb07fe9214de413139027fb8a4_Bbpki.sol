/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

contract Bbpki {

// state variables

address owner;
mapping (uint => certificate) public certificates;
mapping (uint => certificateAuthority) public certificateAuthorities;
uint256 public noOfcertificates = 0;
uint256 public noOfCA = 0;
uint256 public blockNumber;

// constructor
constructor () {
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
        uint256 serialNumber;
        string subjectName;
        string issuer;
        uint notBefore;
        uint notAfter;
        certificateStatus Status;
        string[] signatures;
        uint256 blockNumber;
    }

    struct certificateAuthority {
    uint id;
    string nameCA;
    }

   

    // events
    // certificate authority registeration event
    event caRegistered (uint noOfCA, string _name );
    event header (uint notBefore, uint notAfter, uint blockNumber);

    // certificate signing event
    event certificateSigned(
    uint256 serialNumber,
    string  subjectName,
     string  issuer,
     certificateStatus Status,
     string[] signatures
      );

    // functions 
    function registerCA (string memory _name) public onlyOwner{
        require ((bytes(_name).length > 0));
        require(noOfCA < 10);
        noOfCA++;
        uint256 CA_Id = noOfCA;
        certificateAuthorities[CA_Id] = certificateAuthority(noOfCA, _name);
        emit caRegistered (CA_Id, _name);
    }


    function signCertificate(string memory subjectName) public returns (
     uint256 serialNumber,
     string memory,
     string memory issuer,
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
    certificates[serialNumber].signatures.push(certificateAuthorities[i].nameCA);
    }
  
    // generate a random number between 1 and "caRequired" to select the issuer of the certificate
    uint cIssuer = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % caRequired;
    if (cIssuer < 1){
        cIssuer = cIssuer + 1;
        }
    issuer = certificateAuthorities[cIssuer].nameCA;
   
 //   (uint year,uint month,uint day) = BokkyPooBahsDateTimeLibrary.timestampToDate(a);
    
 certificateStatus Status = certificateStatus.active;
certificates[serialNumber].serialNumber = serialNumber;
certificates[serialNumber].subjectName = subjectName;
certificates[serialNumber].issuer = issuer;
certificates[serialNumber].Status = Status;
addblockandexpiry(serialNumber);


  //  certificates[noOfcertificates] = certificate(serialNumber, subjectName, organisation, issuer, expiry, noOfSignatures,defaultStatus,signatures);
     emit certificateSigned(serialNumber, subjectName, issuer, Status,certificates[serialNumber].signatures);
     return (serialNumber, subjectName, issuer, Status,certificates[serialNumber].signatures);
    }

    function revokeCertificate (uint256 serialNumber) public onlyOwner returns (string memory){
     certificateStatus status = certificateStatus.revoked;
     certificates[serialNumber].Status = status;
    return "revoked";
    }
    
    function clientVerifyCert(uint serialNumber) public view returns (uint){
        return certificates[serialNumber].blockNumber;
    }

    function countCertificates() view public returns (uint){ //Count how many users create certificates
      return noOfcertificates;
    }
    
    function addblockandexpiry (uint256 serialNumber) private returns (uint256, uint256, uint256) {
        uint256 notBefore = block.timestamp;
        uint256 notAfter = block.timestamp + (365*24*60*60);
        certificates[serialNumber].notBefore = notBefore;
        certificates[serialNumber].notAfter = notAfter;
        certificates[serialNumber].blockNumber = block.number;
        emit header(notBefore, notAfter, block.number);
        return (notBefore, notAfter, block.number);
        
    }
}