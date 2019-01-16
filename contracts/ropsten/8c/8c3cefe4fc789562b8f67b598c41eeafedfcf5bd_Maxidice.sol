pragma solidity ^0.4.23;

contract Maxidice {
    struct Room {
        bytes32 roomID;
        uint256 currentPlayers;
        uint256 totalAmountBetting;
        uint256 numberWin;
        address[] players;
        mapping(address => Player) playerInfo;
    }

    struct Player {
        uint256 amountBet;
        uint256 numberSelected;
    }

    mapping(bytes32 => Room) rooms;
    uint256 currentRoomID = 0;
    
    constructor() public{

    }
    function createRoom() public returns(bytes32){
        bytes32 roomID = keccak256(abi.encode(block.timestamp));
        refreshRoom(roomID);
        return roomID;
    }

    function refreshRoom(bytes32 roomID) public {
        Room memory newRoom;
        newRoom.roomID = roomID;
        newRoom.currentPlayers = 0;
        newRoom.totalAmountBetting = 0;
        rooms[roomID] = newRoom;
    }
    
    function bet(uint256 numberSelected, bytes32 roomID) public payable returns(bool){
        require(!checkRoomExists(roomID));
        require(numberSelected >=1 && numberSelected <= 6);
        rooms[roomID].playerInfo[msg.sender].amountBet = msg.value;
        rooms[roomID].playerInfo[msg.sender].numberSelected = numberSelected;
        rooms[roomID].currentPlayers += 1;
        rooms[roomID].totalAmountBetting += msg.value;
        rooms[roomID].players.push(msg.sender);
    }

    function checkRoomExists(bytes32 roomID) public view returns(bool) {
        if (rooms[roomID].roomID == roomID) {
            return true;
        }
        return false;
    }
    
    function startGame(bytes32 roomID) public {
        uint256 numberGenerated = block.number % 6 + 1;
        distributePrizes(roomID, numberGenerated);
    }
    
    function distributePrizes(bytes32 roomID, uint256 numberWinner) public {
        address[100] memory winners;
        uint256 count = 0;
        Room storage room = rooms[roomID];
        uint256 totalBet = room.totalAmountBetting;
        for (uint256 i = 0; i < room.players.length; i++) {
            address playerAddress = room.players[i];
            if (room.playerInfo[playerAddress].numberSelected == numberWinner) {
                winners[count] = playerAddress;
                count++;
            }
        }
        uint256 winnerEtherAmount = totalBet / winners.length;
        for (uint256 j = 0; j < count; j++) {
            if (winners[j] != address(0)) {
                winners[j].transfer(winnerEtherAmount);
            }
        }
    }
}