/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

/**
 * @title OpenHouse
 * @dev Create, join, and interact with OpenHouse-enabled rooms
 */
contract OpenHouse {

    string[] private rooms;
    
    mapping (string => bool) private _roomsMap;
    
    mapping (string => address[]) private _memberships;
    
    mapping (string => mapping (address => bool)) private _membershipsMap;

    /**
     * @dev Create a room, or join it if it already exists.
     * @param name defines the room
     */
    function addRoom(string calldata name) public {
        if (!_roomsMap[name]){
            _roomsMap[name] = true;
            rooms.push(name);
        }
        
        address sender = msg.sender;
        if (!_membershipsMap[name][sender]) {
            _membershipsMap[name][sender] = true;
            _memberships[name].push(sender);
        }
    }
    
    /**
     * @dev List all rooms that have already been created.
     */
    function listRooms() public view returns (string[] memory) {
        return rooms;
    }
    
    /**
     * @dev Return the list of addresses that belong to a room.
     * @param name specifies the room to list memberships for.
     */
    function members(string calldata name) public view returns (address[] memory) {
        return _memberships[name];
    }
}