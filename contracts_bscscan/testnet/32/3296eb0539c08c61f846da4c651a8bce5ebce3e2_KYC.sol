// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract KYC is Ownable {

    event AdminAdded(address);
    event AdminRemoved(address);
    event RecordAdded(address, string indexed, uint8);

    struct Record {
        string uuidv4;
        uint8 level;
        bool exist;
    }

    mapping (address => bool) private isAdmin;
    mapping (address => Record) private addressRecord;

    constructor() Ownable() {
        isAdmin[_msgSender()] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    function addAdmin(address _address) public onlyOwner {
        isAdmin[_address] = true;
        emit AdminAdded(_address);
    }

    function removeAdmin(address _address) public onlyOwner {
        isAdmin[_address] = false;
        emit AdminRemoved(_address);
    }

    function register(address _address, string memory uuidv4, uint8 level) public onlyAdmin {
        addressRecord[_address] = Record(uuidv4, level, true);
        emit RecordAdded(_address, uuidv4, level);
    }

    function checkStatus(address _address) public view returns(uint8) {
        require(addressRecord[_address].exist == true);
        return addressRecord[_address].level;
    }
}