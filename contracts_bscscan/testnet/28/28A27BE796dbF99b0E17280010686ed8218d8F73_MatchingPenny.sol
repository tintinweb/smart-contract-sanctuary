/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Penny token interface
 */
interface PennyInterface {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external payable returns (bool success);
    
    function transfer(
        address _to,
        uint256 _value
    ) external payable returns (bool success);
    
    function approve(
        address _spender, 
        uint256 _value
    ) external returns (bool success);
}


// struct for save room information
struct Room {
    address betUser1;
    address betUser2;
    bool    userBet1;
    bool    userBet2;
    uint256 betAmount;
    bool    isFinished;
    uint256 playersReady;
}

/**
 * @title MatchingPenny
 * @dev MatchingPenny Game Smart Contract
 */
contract MatchingPenny {
    /**
     * @dev MPro token address.
     */
    address public tokenAddress = 0xeA344CF4e6e805c86276a3e77a98bA4C36752286;
    
    // Array of Rooms 
    mapping(uint256 => Room) private rooms;
    
    // Array of Room IDs
    uint256[] public roomsIds ; 

    // Array of rooms of a user
    mapping(address => uint256[]) public userRooms;

    // Pool Colleced for a room
    mapping(uint256 => uint256) public poolcollected;
    
    PennyInterface public penny = PennyInterface(tokenAddress);

    // Allow to create room with betamount
    function createRoom(uint256 _betAmount) public payable {
        
        require(penny.transferFrom(msg.sender, address(this), _betAmount * 1e18));

        uint256 id = roomsIds.length;
        roomsIds.push(id);
        
        rooms[id].betUser1 = msg.sender;
        rooms[id].userBet1 = false;
        rooms[id].userBet2 = false;
        rooms[id].betAmount = _betAmount;
        rooms[id].isFinished = false;
        rooms[id].playersReady = 0;
        
        userRooms[msg.sender].push(id);
    }
    
    // Allow to join room with roomid
    function joinRoom(uint256 _id) public {
        require(rooms[_id].isFinished == false);
        require(rooms[_id].playersReady == 1);

        require(penny.transferFrom(msg.sender, address(this), rooms[_id].betAmount * 1e18));
        
        rooms[_id].betUser2 = msg.sender;
        userRooms[msg.sender].push(_id);
    }
    
    // Allow to player bet to game.
    function playerReady(uint _id, bool _bet) public {
        require(rooms[_id].isFinished == false);
        require(rooms[_id].betUser1 == msg.sender || rooms[_id].betUser2 == msg.sender);

        rooms[_id].playersReady += 1;
        
        if (rooms[_id].betUser1 == msg.sender) {
            rooms[_id].userBet1 = _bet;
        }
        else {
            rooms[_id].userBet2 = _bet;
        }
        
        if (rooms[_id].playersReady == 2) {
            finishRoom(_id);
            rooms[_id].isFinished = true;
        }
    }
    
    // Finish room with room id.
    function finishRoom(uint _id) public payable {
        require(rooms[_id].isFinished == false);
        require(rooms[_id].playersReady == 2);
        
        if (rooms[_id].userBet1 == rooms[_id].userBet2) {
            require(penny.transfer(rooms[_id].betUser1, rooms[_id].betAmount * 2 * 1e18));
        }
        else {
            require(penny.transfer(rooms[_id].betUser2, rooms[_id].betAmount * 2 * 1e18));
        }
    }
}