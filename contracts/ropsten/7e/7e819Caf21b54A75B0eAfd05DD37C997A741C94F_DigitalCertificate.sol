/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

struct Certificate{
    uint index;
    string certificateNumber;
    string certificateName;
    string certificateHash;
    string receiverName;
    uint dateOfAchivement;
    address issuerAddress;
    bool isValue;
}

contract DigitalCertificate{

    mapping(string => Certificate) private certificateMap;
    uint8 public countCertificateArray=0;
    Certificate [] public certificateArray;

    event AddNewCertificate(string  certificateNumber,string  certificateName,string  certificateHash,string  receiverName,uint dateOfAchivement,address issuerAddress);
    event EditCertificate(string  certificateNumber,string  certificateName,string  certificateHash,string  receiverName,uint dateOfAchivement,address issuerAddress);

    function addCertificate(string memory certificateNumber,string memory certificateName,string memory certificateHash,string memory receiverName,uint dateOfAchivement)public {
        require(!certificateMap[certificateNumber].isValue,"current certificateNumber is already exists.");
        certificateArray.push(Certificate(countCertificateArray,certificateNumber,certificateName,certificateHash,receiverName,dateOfAchivement,msg.sender,true));
        certificateMap[certificateNumber]=certificateArray[countCertificateArray];
        countCertificateArray++;
        emit AddNewCertificate(certificateNumber,certificateName,certificateHash,receiverName,dateOfAchivement,msg.sender);
    }

    function infoCertificate(string memory certificateNumber)public view returns(string memory ,string memory,string memory,string memory,uint,address){
        if(!certificateMap[certificateNumber].isValue) return ("Not Found this Certificate Number","Not Found this Certificate Number","Not Found this Certificate Number","Not Found this Certificate Number",0,0x0000000000000000000000000000000000000000); 
        Certificate storage thisCertificate= certificateMap[certificateNumber];
        return (thisCertificate.certificateNumber,thisCertificate.certificateName,thisCertificate.certificateHash,thisCertificate.receiverName,thisCertificate.dateOfAchivement,thisCertificate.issuerAddress);
    }

    function editCertificate(string memory certificateNumber,string memory certificateName,string memory certificateHash,string memory receiverName,uint dateOfAchivement)public{
        require(certificateMap[certificateNumber].isValue,"Not Found this Certificate Number");
        Certificate storage thisCertificate= certificateMap[certificateNumber];
        require(thisCertificate.issuerAddress==msg.sender,"You're not a issuer");
        thisCertificate.certificateName=certificateName;
        thisCertificate.certificateHash=certificateHash;
        thisCertificate.receiverName=receiverName;
        thisCertificate.dateOfAchivement=dateOfAchivement;
        Certificate storage thisCertificateArray =certificateArray[thisCertificate.index];
        thisCertificateArray.certificateName=certificateName;
        thisCertificateArray.certificateHash=certificateHash;
        thisCertificateArray.receiverName=receiverName;
        thisCertificateArray.dateOfAchivement=dateOfAchivement;
        emit EditCertificate(thisCertificate.certificateNumber,thisCertificate.certificateName,thisCertificate.certificateHash,thisCertificate.receiverName,thisCertificate.dateOfAchivement,msg.sender);
    }


}