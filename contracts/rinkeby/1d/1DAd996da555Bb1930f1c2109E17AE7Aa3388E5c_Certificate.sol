/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.5.11;

contract Certificate {

    address public issuerAddress;

    string public certificateTitle;
    string public certificateType;
    string public result;
    string public description;
    string public courseName;
    string public studentName;
    string public teacherName;
    string public issuedDate;
    string public certificateURL;
    string public certificateHash;

    event UrlUpdated(address indexed issuer, uint timestamp);

    constructor(string memory cTitle,
        string memory cType,
        string memory res,
        string memory desc,
        string memory cName,
        string memory sName,
        string memory tName,
        string memory iDate,
        string memory cUrl,
        string memory cHash)
    public {
        certificateTitle = cTitle;
        certificateType = cType;
        result = res;
        description = desc;
        courseName = cName;
        studentName = sName;
        teacherName = tName;
        issuedDate = iDate;
        certificateURL = cUrl;
        certificateHash = cHash;
        issuerAddress = msg.sender;
    }

    function updateURL(string memory cUrl) public {
        require(msg.sender == issuerAddress, "Unauthorized issuer");
        certificateURL = cUrl;
        emit UrlUpdated(msg.sender, now);
    }

}