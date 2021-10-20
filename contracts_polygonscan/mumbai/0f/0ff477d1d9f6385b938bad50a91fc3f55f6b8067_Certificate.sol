/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.4;

interface ICertificateDirectory {
    function addToDirectory(address _certificate, uint256 _serialNumber)
        external;
}

pragma solidity 0.8.4;

contract Certificate {
    string public name;
    string public field;
    string public certificateType;
    uint256 public issueTime;
    uint256 public expireTime;
    uint256 public serialNumber;
    bool public revoke;
    address public addressDirectory;

    constructor(
        string memory _name,
        string memory _field,
        string memory _certificateType,
        uint256 _expireTime,
        uint256 _serialNumber
    ) {
        name = _name;
        field = _field;
        certificateType = _certificateType;
        issueTime = block.timestamp;
        expireTime = _expireTime;
        serialNumber = _serialNumber;
        revoke = false;
        addressDirectory = address(0x2916C2710Bf98C0C02cD8fd1Cd884baC9A594034);
        ICertificateDirectory certificateDirectory = ICertificateDirectory(
            addressDirectory
        );
        certificateDirectory.addToDirectory(address(this), serialNumber);
    }

    function RevokeCertificate() public {
        revoke = true;
    }
}