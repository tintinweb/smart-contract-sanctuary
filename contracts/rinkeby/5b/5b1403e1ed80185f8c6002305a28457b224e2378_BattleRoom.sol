pragma solidity ^0.8.0;

import "./joinBattleRoom.sol";

contract BattleRoom is joinBattleRoom {
    function readRoomName(uint8 _roomId) public view returns (string memory) {
        return rooms[_roomId].roomName;
    }

    function readRoomIdFromOrganizer(address _organizer) public view returns (uint64) {
        return roomIdToOwner[_organizer];
    }
    
    function readOrganizerFromRoomId(uint8 _roomId) public view returns (address) {
        return rooms[_roomId].roomOwner;
    }

    function readOrganizerClaimChoice(uint8 _roomId) public view returns (string memory) {
        return rooms[_roomId].organizerClaimChoice;
    }

    function readOrganizerActualChoice(uint8 _roomId) public view returns (string memory) {
        require(rooms[_roomId].status == false);
        return rooms[_roomId].organizerActualChoice;
    }

    function readChallenger(uint8 _roomId) public view returns (address) {
        return rooms[_roomId].roomChallenger;
    }

    function readChallengerChoice(uint8 _roomId) public view returns (string memory) {
        return rooms[_roomId].challengerChoice;
    }

    function readResult(uint8 _roomId) public view returns (string memory) {
        return rooms[_roomId].result;
    }

    function readBattleRoomList() public view returns (string[] memory) {
        return battleRoomList;
    }

    function readRoomBalance(uint _roomId) public view returns (uint) {
        return rooms[_roomId].roomTotalPayment;
    }

    function readRoomstatus(uint _roomId) public view returns (bool) {
        return rooms[_roomId].status;
    }
}