pragma solidity ^0.4.6;

contract BlockApps_Blockmatics_Certificate_081117 {
    address public owner = msg.sender;
    string certificate;
    bool certIssued = false;

    function publishGraduatingClass(string cert) {
        if (msg.sender != owner || certIssued)
            revert();
        certIssued = true;
        certificate = cert;
    }

    function showCertificate() constant returns (string) {
        return certificate;
    }
}