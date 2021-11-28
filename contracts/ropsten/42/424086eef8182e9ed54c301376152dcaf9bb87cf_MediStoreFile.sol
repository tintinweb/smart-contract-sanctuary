/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

pragma solidity ^0.5.1;

contract MediStoreFile {
    uint public fileCount = 0;
    string public name = 'MediStore File';
    address private owner;

    mapping(uint => File) public files;
    mapping(address => mapping(address => string)) public approvals;
    mapping(address => mapping(address => bool)) public manyApprovals;

    struct File {
        uint id;
        string hash;
        string title;
        address owner;
    }

    // Events
    event FileSent(
        uint id,
        string hash,
        string title,
        address owner
    );

    event Approval(
        address owner,
        address requester,
        string hash
    );

    // Modifiers
    modifier hashExist (string memory _hash) {
        bytes memory fileHash =  bytes(_hash);
        require (fileHash.length > 0, 'File hash is required.');
        _;
    }

    modifier titleExist (string memory _title) {
        bytes memory fileTitle =  bytes(_title);
        require(fileTitle.length > 0, 'File title is required.');
        _;
    }

    constructor() public { owner = msg.sender; }

    function sendFile(address _owner, string memory _hash, string memory _title) hashExist(_hash) titleExist(_title) public {
        require(_owner != address(0), 'Unauthorized request.');
        fileCount++;

        files[fileCount] = File(fileCount, _hash, _title, _owner);
        emit FileSent(fileCount, _hash, _title, _owner);
    }

    function approve(address _requester, string memory _hash) public returns (bool success) {
        // Add requester to the allowed addresses to see patient's record
        approvals[msg.sender][_requester] = _hash;

        emit Approval(msg.sender, _requester, _hash);

        return true;
    }

    function approvedForAll(address _requester, bool _allow) public returns (bool success) {
        bool existingApproval = manyApprovals[msg.sender][_requester];
        require(existingApproval != _allow && _allow == true, 'Already allowed.');

        manyApprovals[msg.sender][_requester] = _allow;

        return true;
    }
}