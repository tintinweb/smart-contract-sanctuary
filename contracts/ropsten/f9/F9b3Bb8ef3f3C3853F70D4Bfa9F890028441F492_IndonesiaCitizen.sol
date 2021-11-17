/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

// (c) 2021 Thortech Asia Software
// Authors: Wuri Nugrahadi <[email protected]>; Alvin Chistanto <[email protected]>
contract IndonesiaCitizen {
    address public proprietor;
    mapping(address => bool) public administrators;

    enum CredenceState { Unknown, Registered, Validated, Verified, Trusted }
    struct Subject {
        string name;
        CredenceState credenceState;
        bool isExists;
    }
    struct DigitalCertificate {
        string cid;
        uint expiryTime;
    }
    mapping(bytes20 => Subject) subjects;
    mapping(bytes20 => DigitalCertificate) digitalCertificates;
    mapping(address => bytes20) subjectClaims;

    event SubjectRegistered(bytes20 hashOfNik, uint256 date);
    event SubjectValidated(bytes20 hashOfNik, uint256 date);
    event SubjectVerified(bytes20 hashOfNik, uint256 date, uint expiryTime);
    event SubjectEnrolled(bytes20 hashOfNik, uint256 date);
    event SubjectUpdated(bytes20 hashOfNik, string oldName, string newName, uint256 date);
    event SubjectDeleted(bytes20 hashOfNik, uint256 date);

    modifier onlyProprietor() {
        require(msg.sender == proprietor, 'This method can only be accessed by the Proprietor.');
        _;
    }
    modifier onlyAllowedToAdminister() {
        bool isProprietor = (msg.sender == proprietor);
        bool isAdministrator = administrators[msg.sender];

        require(
            (isProprietor || isAdministrator) == true,
            'This method can only be accessed by the Administrator.'
        );
        _;
    }

    constructor () {
        proprietor = msg.sender;
    }

    function assignAdministrator(address _account) public
    onlyProprietor
    returns(bool isAssigned) {
        administrators[_account] = true;

        return administrators[_account];
    }

    function revokeAdministrator(address _account) public
    onlyProprietor
    returns(bool isAssigned) {
        administrators[_account] = false;

        return administrators[_account];
    }

    function isExists(int _nik) public view
    returns(bool) {
        bytes20 key = calculateHash(_nik);

        return subjects[key].isExists;
    }

    function getSubject(int _nik) public view
    onlyAllowedToAdminister
    returns(string memory name, CredenceState credenceState) {
        require(isExists(_nik), 'NIK not recorded in the network!');
        bytes20 key = calculateHash(_nik);

        name = subjects[key].name;
        credenceState = subjects[key].credenceState;

        return (name, credenceState);
    }

    function getDigitalCertificate(int _nik) public view
    onlyAllowedToAdminister
    returns(string memory cid, uint expiryTime) {
        require(isExists(_nik), 'NIK not recorded in the network!');
        bytes20 key = calculateHash(_nik);
        DigitalCertificate memory digiCert = digitalCertificates[key];

        require((digiCert.expiryTime >= block.timestamp), 'No valid digital certificate belongs to the subject.');

        cid = digiCert.cid;
        expiryTime = digiCert.expiryTime;

        return (cid, expiryTime);
    }

    function register(int _nik, string memory _name) public
    onlyAllowedToAdminister
    returns(bool success) {
        require(!isExists(_nik), 'NIK has been recorded in the network!');

        bytes20 key = calculateHash(_nik);

        subjects[key].name = _name;
        subjects[key].credenceState = CredenceState.Registered;
        subjects[key].isExists = true;

        emit SubjectRegistered(key, block.timestamp);

        return true;
    }

    function validate(int _nik) public
    onlyAllowedToAdminister
    returns(bool success) {
        require(isExists(_nik), 'NIK not recorded in the network!');

        bytes20 key = calculateHash(_nik);
        subjects[key].credenceState = CredenceState.Validated;

        emit SubjectValidated(key, block.timestamp);

        return true;
    }

    function verify(int _nik, string memory _cid, uint _expiryTime) public
    onlyAllowedToAdminister
    returns(bool success) {
        require(isExists(_nik), 'NIK not recorded in the network!');

        bytes20 key = calculateHash(_nik);
        subjects[key].credenceState = CredenceState.Verified;
        // associate digitalcert to subject
        digitalCertificates[key].cid = _cid;
        digitalCertificates[key].expiryTime = _expiryTime;

        emit SubjectVerified(key, block.timestamp, _expiryTime);

        return true;
    }

    function updateSubject(int _nik, string memory _name) public
    onlyAllowedToAdminister
    returns(bool success) {
        require(isExists(_nik), 'NIK not recorded in the network!');

        bytes20 key = calculateHash(_nik);
        string memory oldName = subjects[key].name;
        subjects[key].name = _name;

        emit SubjectUpdated(key, oldName, _name, block.timestamp);

        return true;
    }

    function deleteSubject(int _nik) public
    onlyAllowedToAdminister
    returns(bool success) {
        require(isExists(_nik), 'NIK not recorded in the network!');
        bytes20 key = calculateHash(_nik);

        subjects[key].isExists = false;

        emit SubjectDeleted(key, block.timestamp);

        return true;
    }
}

// helper
function calculateHash(int nik) pure returns (bytes20 result) {
    bytes32 resultBase = keccak256(abi.encodePacked(nik));

    result = bytes20(resultBase << 64*0);
}