// Estimated Gas: 1,368,083
pragma solidity ^0.4.21;

library StringOperation {function concat(string string1, string string2, string sep) internal pure returns (string){

        bytes memory string1Bytes = bytes(string1);
        bytes memory string2Bytes = bytes(string2);
        bytes memory sepBytes = bytes(sep);

        string memory concatString = new string(string1Bytes.length + sepBytes.length + string2Bytes.length);
        bytes memory concatStringBytes = bytes(concatString);
        uint k = 0;

        // Concat string1
        for (uint i = 0; i < string1Bytes.length; i++) concatStringBytes[k++] = string1Bytes[i];
        // Concat sep
        for (i = 0; i < sepBytes.length; i++) concatStringBytes[k++] = sepBytes[i];
        // Concat string2
        for (i = 0; i < string2Bytes.length; i++) concatStringBytes[k++] = string2Bytes[i];

        return string(concatStringBytes);
    }
}

contract HamroCertificate {
    using StringOperation for *;

    struct Certificate {
        string id;
        string courseName;
        string issueDate;
        string detail;
    }

    address owner;
    address[] private admins;
    // user => Certificate
    mapping (address => Certificate[]) userCertificate;

    event BroadcastCertificate(address receiver, string issueDate, string certificateDetails);

    // modifier to check if caller is owner
    modifier ifOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _; /*  _means contiune normal flow */
    }

    constructor() public {
        owner = msg.sender;
        admins.push(owner);
    }

    function assignCertificate(address user, string id, string courseName, string issueDate, string detail) public ifOwner {

        Certificate memory certificate;
        certificate.id = id;
        certificate.courseName = courseName;
        certificate.issueDate = issueDate;
        certificate.detail = detail;

        userCertificate[user].push(certificate);

        emit BroadcastCertificate(user, issueDate, detail);
    }

    function viewAllCertificate(address user) public constant returns (string allCertificate){

        Certificate[] memory certificates = userCertificate[user];
        string memory certificateString;

        for(uint i = 0; i < certificates.length; i++) {
            certificateString = StringOperation.concat(
                                    certificates[i].id,
                                    certificates[i].courseName,
                                    "	");
            certificateString = StringOperation.concat(
                                    certificateString,
                                    certificates[i].issueDate,
                                    "	");
            certificateString = StringOperation.concat(
                                    certificateString,
                                    certificates[i].detail,
                                    "	");
            if (i > 0) {
                allCertificate = StringOperation.concat(
                                    allCertificate,
                                    certificateString,
                                    ",");
            } else {
                allCertificate = certificateString;
            }
        }
        allCertificate = StringOperation.concat(
                            "CertificateID	CourseName	IssueDate	CertificateDetail",
                            allCertificate,
                            ",");
    }

    function viewCertificateByCourse(address user, string courseName) public constant returns (string certificate){

        Certificate[] memory certificates = userCertificate[user];

        for(uint i = 0; i < certificates.length; i++) {
            if (keccak256(certificates[i].courseName) == keccak256(courseName)) {
                certificate = StringOperation.concat(
                                certificates[i].id,
                                certificates[i].courseName,
                                "	");
                certificate = StringOperation.concat(
                                certificate,
                                certificates[i].issueDate,
                                "	");
                certificate = StringOperation.concat(
                                certificate,
                                certificates[i].detail,
                                "	");
                certificate = StringOperation.concat(
                                "CertificateID	CourseName	IssueDate	CertificateDetail",
                                certificate,
                                ",");
            }
        }
    }
}