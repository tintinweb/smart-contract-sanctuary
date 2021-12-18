/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: LICENSED

pragma solidity ^0.8.7;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract KYC is Auth {

    bool payToSee;
    uint256 feeToAdd = 100000000000000000; //=> represent 0.5BNB or 0.5ETH decimals
    address payable ownerAddress; // contract creator's address

    struct participant {
        string fName;
        string lName;
        bool valid;
        bool scam;
        string documentNumber;
        address contractAddress;
    }

    constructor () Auth(msg.sender) {
        ownerAddress = payable(msg.sender); // setting the contract creator
    }

    mapping (address => participant) participants;
    address[] participantsAddress; // use to count

    function addParticipant(string memory _fName, string memory _lName, string memory _documentNumber) internal {

        require(!participants[msg.sender].valid, "This user exists. You cannot add it again!");

        participants[msg.sender].fName = _fName;
        participants[msg.sender].lName = _lName;
        participants[msg.sender].documentNumber = _documentNumber;
        participants[msg.sender].valid = true;
        participants[msg.sender].scam = false;

        participantsAddress.push(msg.sender);
    }

    function userAddParticipant(string memory _fName, string memory _lName, string memory _documentNumber) public payable {
        
        require(msg.value >= feeToAdd, "You need pay the minimum to procede");
        (bool success,) = ownerAddress.call{value: msg.value}("");
        require(success, "Failed to send money");

        addParticipant(_fName, _lName, _documentNumber);
    }

    function teamAddParticipant(string memory _fName, string memory _lName, string memory _documentNumber) public onlyOwner {

        addParticipant(_fName, _lName, _documentNumber);
    }

    function changeIsScam(address _address) public authorized {
        participants[_address].scam = !participants[_address].scam;
    }

    function getParticipants() view public returns(address[] memory) {
        return participantsAddress;
    }

    function getParticipantInfo(address _address) view public returns (string memory, string memory, bool) {
        return (
            participants[_address].fName, 
            participants[_address].lName,
            participants[_address].scam
        );
    }

    function getParticipantFullInfo(address _address) view public returns (string memory, string memory, string memory, bool) {

        require(participants[_address].scam == true, "This KYC account is not flagged as SCAM. You cannot see the full information");

        return (
            participants[_address].fName, 
            participants[_address].lName,
            participants[_address].documentNumber,
            participants[_address].scam
        );
    }

    function getAddFee() public view returns (uint256){
        return (feeToAdd);
    }

    function setAddFee(uint256 _valueFee) public onlyOwner () {
        feeToAdd = _valueFee;
    }
}