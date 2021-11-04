/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract RoomBooking {

    struct Room {
        bool booked;
        address owner;
    }

    uint8 public constant MAX_ROOM = 10;
    uint8 public constant MAX_SLOT = 8;

    mapping(string => mapping(uint8 => Room[MAX_ROOM])) public roomlist;
    mapping(string => mapping(address => bool)) public whitelist;

    string[] private companies;

    event Reserved(address _occupant, string _company, uint8 _slot, uint8 _roomSpace);
    event Canceled(address _occupant, string _company, uint8 _slot, uint8 _roomSpace);
    event Whitelisted(string _company, address _address);

    modifier inSlotRange (uint8 _slot) {
        // check if the slot is under MAX_SLOT
        require(_slot < MAX_SLOT, "Slot is out of range!");
        _;
    }

    modifier inRoomRange (uint8 _roomSpace) {
        // check if the room is under MAX_ROOM
        require(_roomSpace < MAX_ROOM, "Room is out of range!");
        _;
    }

    constructor(string[] memory _companies, address[] memory _addresses) {
        companies = _companies;
        // For each company, we add address in whitelist
        for (uint i = 0; i < _companies.length; i++) {
            whitelist[_companies[i]][_addresses[i]] = true;
        }

    }

    function getCompanies() public view returns(string[] memory) {
        return companies;
    }

    function reserveRoomSpace(string memory _company, uint8 _slot, uint8 _roomSpace) public inSlotRange(_slot) inRoomRange(_roomSpace) {
        // Check that is an Admin call this function
        require(whitelist[_company][msg.sender], "Not allowed to reserve room!");
        roomlist[_company][_slot][_roomSpace].booked = true;
        roomlist[_company][_slot][_roomSpace].owner = msg.sender;
        emit Reserved(msg.sender, _company, _slot, _roomSpace);
    }

    function cancelRoomSpace(string memory _company, uint8 _slot, uint8 _roomSpace) public inSlotRange(_slot) inRoomRange(_roomSpace) {
        // Check that is an Admin call this function
        require(whitelist[_company][msg.sender], "Not allowed to cancel room!");
        roomlist[_company][_slot][_roomSpace].booked = false;
        roomlist[_company][_slot][_roomSpace].owner = address(0);
        emit Canceled(msg.sender, _company, _slot, _roomSpace);
    }

    function addWhitelist(string memory _company, address _address) public {
        // Check that is an Admin call this function
        require(whitelist[_company][msg.sender], "Operation not allowed!");
        // Check if address already in whitelist
        require(!whitelist[_company][_address], "Address already whitelisted!");
        whitelist[_company][_address] = true;
        emit Whitelisted(_company, _address);
    }
}