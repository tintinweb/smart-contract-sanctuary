//"SPDX-License-Identifier: UNLICENSED"
pragma solidity >= 0.6.0 <= 0.8.0;

interface InterfaceHotelBooking {
    function bookRoom(uint256 _roomId) external payable returns(bool success);
    
    function listRoom(uint32 _rooms, uint256 _price, bool _attachBath) external returns(uint,bool success);
}
contract HotelBooking is InterfaceHotelBooking{
    //state
    //mapping(uint256 => address) private bookedBy;
    
    // No of rooms;
    //currently 0;
    uint256 private roomCount;
    
    struct RoomDetail {
        uint32 rooms;
        uint256 price;
        bool attachBath;
    }
    mapping(uint256 => RoomDetail) public RoomById;
    
    event RoomListed(uint256 rooms, uint256 price, bool attachBath, uint32 roomId);
    event RoomBooked(uint256 roomId, address by);
    
    function bookRoom(uint256 _roomId) external payable override returns(bool success){ //user
    ///@notice to prevent booking on unlisted rooms
    require(RoomById[_roomId].price > 0, "Room not available currently");
    require(msg.value >= RoomById[_roomId].price, "enter valid amount");
    success = true;
    emit RoomBooked(_roomId, msg.sender);
    }
    
    function listRoom(uint32 _rooms, uint256 _price, bool _attachBath) external override returns(uint,bool success) { //admin
    roomCount++;
    uint32 roomId = uint32(roomCount);
    //RoomDetail memory obj = RoomDetail(_rooms, _price, _attachBath);
    RoomById[roomId] = RoomDetail(_rooms, _price, _attachBath);
    emit RoomListed(_rooms, _price, _attachBath, roomId);
    }
    
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}