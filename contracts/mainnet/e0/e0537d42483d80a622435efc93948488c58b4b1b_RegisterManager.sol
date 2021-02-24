/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RegisterManager {
    uint public roomFee = 0.01 ether;
    uint public systemFee = 0.05 ether;
    address public admin;
    mapping(address => bool) public isSystemRegistered;
    mapping(uint => mapping(address => bool)) private _isRoomRegistered;

    event SystemRegistered(address registrant);
    event SystemUnregistered(address registrant);
    event RoomRegistered(address registrant, uint room_id);
    event RoomUnregistered(address registrant, uint room_id);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

   function systemRegister() external payable {
        require(msg.value == systemFee, "Wrong ETH value!");
        require(!isSystemRegistered[msg.sender], "Already Registered!");
        isSystemRegistered[msg.sender] = true;
        emit SystemRegistered(msg.sender);
    }

    function roomRegister(uint roomId) external payable {
        require(msg.value == roomFee, "Wrong ETH value!");
        require(isSystemRegistered[msg.sender], "Unregistered in System!");
        require(!_isRoomRegistered[roomId][msg.sender], "Already Registered!");
        _isRoomRegistered[roomId][msg.sender] = true;
        emit RoomRegistered(msg.sender, roomId);
    }

    function isRoomRegistered(uint roomId, address registrant) external view returns(bool) {
        if (!isSystemRegistered[registrant]) return false;
        return _isRoomRegistered[roomId][registrant];
    }

    // Admin functions
    function setSystemFee(uint _systemFee) external onlyAdmin {
        systemFee = _systemFee;
    }

    function setRoomFee(uint _roomFee) external onlyAdmin {
        roomFee = _roomFee;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function roomUnregister(uint roomId, address registrant) external onlyAdmin {
        require(!isSystemRegistered[registrant], "Unexist registrant!");
        require(_isRoomRegistered[roomId][registrant], "Unexist registrant in the room!");
        _isRoomRegistered[roomId][registrant] = false;
        emit RoomUnregistered(msg.sender, roomId);
    }

    function systemUnregister(address registrant) external onlyAdmin {
        require(isSystemRegistered[registrant], "Unexist registrant!");
        isSystemRegistered[registrant] = false;
        emit SystemUnregistered(registrant);
    }

    function withdraw() external onlyAdmin {
        uint balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        if (!payable(msg.sender).send(balance)) {
            payable(msg.sender).transfer(balance);
        }
    }
}