/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ReceiveEther {
    /*
    Which function is called, fallback() or receive()?
    */

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

/**
 * @title MatchingPenny
 * @dev MatchingPenny Game Smart Contract
 */
contract MatchingPenny {
    // struct for save room information
    struct Room {
        address betUser1;
        address betUser2;
        bool    userBet1;
        bool    userBet2;
        uint256 betAmount;
        bool    isFinished;
        bool    isOtherReady;
    }
    
    // Array of Rooms 
    mapping(uint256 => Room) private rooms;
    
    // Array of Room IDs
    uint256[] public roomsIds ; 

    // Array of rooms of a user
    mapping(address => uint256[]) public userRooms;

    // Pool Colleced for a room
    mapping(uint256 => uint256) public poolcollected;

    // Allow to create room with betamount
    function createRoom(uint256 _betAmount) public payable {
        uint256 id = roomsIds.length;
        roomsIds.push(id);
        
        rooms[id].betUser1 = msg.sender;
        rooms[id].userBet1 = false;
        rooms[id].userBet2 = false;
        rooms[id].betAmount = _betAmount;
        rooms[id].isFinished = false;
        rooms[id].isOtherReady = false;
        
        userRooms[msg.sender].push(id);
    }
    
    // Allow to join room with roomid
    function joinRoom(uint256 _id) public {
        require(rooms[_id].isFinished == false);
        require(rooms[_id].isOtherReady == false);

        rooms[_id].betUser2 = msg.sender;
        userRooms[msg.sender].push(_id);
    }
    
    // Allow to player bet to game.
    function playerReady(uint _id, bool _bet) public {
        require(rooms[_id].isFinished == false);
        require(rooms[_id].betUser1 == msg.sender || rooms[_id].betUser2 == msg.sender);
        
        if (rooms[_id].betUser1 == msg.sender) {
            rooms[_id].userBet1 = _bet;
        }
        else {
            rooms[_id].userBet2 = _bet;
        }
        
        if (rooms[_id].isOtherReady) {
            finishRoom(_id);
        }

        rooms[_id].isOtherReady = true;
    }
    
    // Finish room with room id.
    function finishRoom(uint _id) internal {
        if (rooms[_id].betUser1 == rooms[_id].betUser2) {
            (bool success, ) = rooms[_id].betUser1.call{ value : rooms[_id].betAmount }("");
            require(success, "Transfer failed.");  
        }
        else {
            (bool success, ) = rooms[_id].betUser2.call{ value : rooms[_id].betAmount }("");
            require(success, "Transfer failed.");  
        }
        
        rooms[_id].isFinished = true;
    }
}