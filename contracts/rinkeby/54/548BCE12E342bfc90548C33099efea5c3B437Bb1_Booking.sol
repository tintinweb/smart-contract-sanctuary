// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract Booking {
    event addHotel(
        uint256 hotelId,
        string name,
        string city,
        uint256 noOfBeds
    );
    event NewRoomBooking(uint256 roomId, address name);

    struct Hotel {
        string name;
        string city;
        uint256 roomPrice;
        uint roomAvailable;
    }
    struct Room {
        uint256 roomId; uint256 hotelId; address name;
    }

    mapping(uint256 => Hotel) hotels;
    mapping(uint256 => Room) public bookedRooms;

    uint256 hotelId;
    uint256 roomId;

    Hotel[] public hotelsList;
    mapping(uint => address) hotelToOwner;


    function _addHotel(
        string memory _name,
        string memory _city,
        uint256 _noOfBeds,
        uint _roomPrice
    ) public {
        Hotel memory hotel = Hotel(_name, _city , _roomPrice, _noOfBeds);
        hotelToOwner[hotelId] = msg.sender;
        hotels[hotelId] = hotel;
        hotelsList.push(hotel);
        emit addHotel(hotelId++, _name, _city,_noOfBeds);
    }
    
    function _bookOneRoom(uint _hotelId) public {
        Hotel storage hotel = hotels[_hotelId];
        require(hotel.roomAvailable > 0, "room not available");
        hotel.roomAvailable--;
        hotelsList[_hotelId].roomAvailable--;
        bookedRooms[roomId] = Room(roomId, _hotelId, msg.sender);
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}