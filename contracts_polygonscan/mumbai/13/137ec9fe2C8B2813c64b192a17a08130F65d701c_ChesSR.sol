/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

contract ChesSR {

    address public owner;
    mapping(string => Room) public contests;
    mapping(string => bool) public roomIdExistence;
    string[] public roomIds;

    constructor() payable{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only Owner can change owner !!!");
        owner = newOwner;
    }

    struct Room {
        string roomId;
        uint256 betAmount;
        address payable[] players;
    }

    function getRoomList() public view returns (Room[] memory){
        Room[] memory rooms ;
        for (uint i=0;i<roomIds.length; i++){
            string memory roomId = roomIds[i];
            rooms[i]= contests[roomId];
        }
        return rooms;
    }

    modifier creatingRoom(string memory roomId){
        //require(msg.value >= 100 wei);
        Room storage room = contests[roomId];
        room.roomId = roomId;

        if(room.players.length < 2){
            room.players.push(payable(msg.sender));
            if(room.players.length == 1){
                room.betAmount = msg.value;
            }else {
                if(msg.value == room.betAmount){

                } else{
                    //revert("Bet amount is not same");
                }
            }
        } else{
            revert("Room is already filled");
        }
        contests[roomId] =room;
        if(!roomIdExistence[roomId]){
            roomIds.push(roomId);
            roomIdExistence[roomId] = true;
        }
        _;
    }


    function deposit(string memory roomId) external payable creatingRoom(roomId) returns (bool){
        return true;
    }

    function transfer(address payable receiver, uint256 amount) public returns (bool){
        require(address(this).balance >= amount, "Insufficient funds");
        receiver.transfer(amount);
        return true;
    }

    function checkBalance() public view returns (uint256){
        return (address(this).balance);
    }

}