pragma solidity ^0.4.18;
contract BlockmaticsGraduationCertificate_030518 {
    address public owner = msg.sender;
    string public certificate;
    bool public certIssued = false;

    function publishGraduatingClass (string cert) public {
        assert (msg.sender == owner && !certIssued);

        certIssued = true;
        certificate = cert;
    }
}