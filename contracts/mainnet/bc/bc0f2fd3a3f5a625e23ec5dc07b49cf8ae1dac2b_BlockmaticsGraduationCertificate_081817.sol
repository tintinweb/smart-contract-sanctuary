pragma solidity ^0.4.0;
contract BlockmaticsGraduationCertificate_081817 {
    address public owner = msg.sender;
    string certificate;
    bool certIssued = false;

    function publishGraduatingClass(string cert) {
        if (msg.sender != owner || certIssued)
            revert();
        certIssued = true;
        certificate = cert;
    }

    function showBlockmaticsCertificate() constant returns (string) {
        return certificate;
    }
}