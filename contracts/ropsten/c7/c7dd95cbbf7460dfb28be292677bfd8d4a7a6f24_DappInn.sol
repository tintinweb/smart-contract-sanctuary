/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Dapp Inn 
/// @author ricardo85x
/// @dev allow users to rent a room in the dApp Inn. 
contract DappInn {

    enum RoomStatus { Vacant, Occupied }

    uint8 public numberOfRooms = 10;

    uint public defaultRoomPriceInWei = 100;

    address public owner;

    struct Room {
        RoomStatus status;
        address guest;
        uint checkoutDate;
        uint price;
        RoomService[] tab; // rooms tap, check pad
    }

    mapping(uint8 => Room) public rooms;

    struct RoomService {
        string name;
        uint price;
        bool enabled;
    }

    uint8 public numberOfServices;

    mapping(uint8 => RoomService) public roomService;

    /// @dev consider using openzeppelin Owener contract
    constructor() {
        owner = address(msg.sender);
    }

    /// @dev consider using openzeppelin Owener contract
    modifier onlyOwner {
        require(address(msg.sender) == owner, "Not owner");
        _;
    }

    /// @dev check if the room is vaacant.
    /// @notice it can become vacant when the checkoutDate expires.
    modifier IsVacant(uint8 _roomNumber){
        require(_roomNumber < numberOfRooms, "This room does not exists");
        // check if the room is occupied when checkoutDate is in the past.
        if ( rooms[_roomNumber].checkoutDate > block.timestamp  ) {
            require(rooms[_roomNumber].status == RoomStatus.Vacant, "This room is occupied");
        }
        _;
    }

    event setRoomPriceEvent(uint8 _roomNumber, uint _price);

    /// @notice set Rooms price.
    /// @dev set price to zero when you want to use defaultRoomPriceInWei.
    function setRoomPrice(uint8 _roomNumber, uint _price) public onlyOwner IsVacant(_roomNumber) {
        rooms[_roomNumber].price = _price; 

        emit setRoomPriceEvent(_roomNumber, _price);
    }

    event setDefaultRoomPriceEvent(uint _price);


    /// @notice set the defaut room price.
    function setDefaultRoomPrice(uint _price) public onlyOwner {
        require(_price > 0, "Money doesn't grow on trees");
        defaultRoomPriceInWei = _price; 

        emit setDefaultRoomPriceEvent(_price);
    }

    event setNumberOfRoomsEvent(uint8 _numberOfRooms);

    /// @notice set the number of rooms available to rent.
    /// @dev please verifify manualy if the room is empty before continue.
    function setNumberOfRooms(uint8 _numberOfRooms) public onlyOwner {
        numberOfRooms = _numberOfRooms;

        emit setNumberOfRoomsEvent(_numberOfRooms);
    }


    event withdrawAllEvent(uint _amount);


    /// @notice withdraw all funds.
    function withdrawAll() public onlyOwner {

        uint _amount = address(this).balance;
        require(_amount > 0, "I'm broke, sorry...");
        payable(msg.sender).transfer(_amount);

        emit withdrawAllEvent(_amount);

    }

    /// @return the balance in this smart contract.
    function balance() public  onlyOwner view returns (uint) {
        return address(this).balance;
    }

    event checkInEvent(address indexed _address, uint8  _roomNumber);

    /// @notice check in the room.
    function checkIn(uint8 _roomNumber, uint _timeToStay) public payable {
        require(_timeToStay > 0, "You have to stay at least one period");

        // if rooms price is zero, set the price to be the defaultRoomPriceInWei
        uint actualPrice = rooms[_roomNumber].price;
        if (actualPrice == 0){
            actualPrice = defaultRoomPriceInWei;
        }

        require(msg.value >= (actualPrice * _timeToStay), "Not enough money");
        require(_roomNumber < numberOfRooms, "This room does not exists");

        // check if the room is occupied when checkoutDate is in the past.
        if ( rooms[_roomNumber].checkoutDate > block.timestamp ) {
            require(rooms[_roomNumber].status == RoomStatus.Vacant, "This room is occupied");
        }

        rooms[_roomNumber].status = RoomStatus.Occupied;
        rooms[_roomNumber].guest = address(msg.sender);

        // calculate checkout Date multiplying the _timeToStay by 1 seconds
        // plus current timestamp
        uint timeToStay = block.timestamp + ((1 seconds) * _timeToStay );
        
        rooms[_roomNumber].checkoutDate = timeToStay;

        // empty current rooms'tab
        delete rooms[_roomNumber].tab;

        RoomService memory checkInService;
        checkInService.name = "stay";
        checkInService.price = msg.value;

        rooms[_roomNumber].tab.push(checkInService);


        emit checkInEvent(msg.sender, _roomNumber);
        
    }

    /// @return current timestamp.
    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }

    event checkOutEvent(address indexed _address, uint8 _roomNumber);

    /// @notice checkout the user before the checkoutDate.
    /// @dev no money back!
    function checkOut(uint8 _roomNumber) public {

        require(rooms[_roomNumber].guest == address(msg.sender), "you are not in the room");
        require(rooms[_roomNumber].status == RoomStatus.Occupied, "This room is not occupied");

        rooms[_roomNumber].status = RoomStatus.Vacant;
        rooms[_roomNumber].guest = address(0);
        rooms[_roomNumber].checkoutDate = block.timestamp;

        emit checkOutEvent(msg.sender, _roomNumber);

    }

    event addRoomServiceEvent(uint8  _serviceNumber, string  _name);

    /// @dev add a service so guest can buy it.
    function addRoomService(string memory _name, uint _price) public onlyOwner {
        roomService[numberOfServices].name = _name;
        roomService[numberOfServices].price = _price;
        roomService[numberOfServices].enabled = true;
        emit addRoomServiceEvent(numberOfServices, _name);
        numberOfServices++;
    }

    event updateRoomServiceEvent(uint8  _serviceNumber, string  _name);

    /// @dev update a service.
    function updateRoomService(uint8 _serviceNumber, string memory _name, uint _price, bool _enabled) public onlyOwner {
        require(_serviceNumber < numberOfServices, "This service does not exists");
        roomService[_serviceNumber].name = _name;
        roomService[_serviceNumber].price = _price;
        roomService[_serviceNumber].enabled = _enabled;

        emit updateRoomServiceEvent(numberOfServices, _name);

    }

    event buyRoomServiceEvent(address indexed _address, string _service);


    /// @notice buy a service to make your stay more happy.
    function buyRoomService(uint8 _roomNumber, uint8 _serviceNumber) public payable {
        require(rooms[_roomNumber].guest == address(msg.sender), "you are not in the room");
        require(rooms[_roomNumber].checkoutDate > block.timestamp , "Your time is over, please leave the room");
        require(_serviceNumber < numberOfServices, "This item does not exists");
        require(roomService[_serviceNumber].enabled == true, "This service is unavailable");
        require(msg.value >= roomService[_serviceNumber].price, "Not enough money");

        rooms[_roomNumber].tab.push(roomService[_serviceNumber]);

        emit buyRoomServiceEvent(msg.sender, roomService[_serviceNumber].name);

    }

    /// @return rooms'tab.
    /// @dev I could not directly use rooms[num].tab from etherjs
    /// So I created this function.
    function getRoomTab(uint8 _roomNumber) public view returns (RoomService[] memory) {
        require(rooms[_roomNumber].guest == address(msg.sender), "you are not in the room");
        return rooms[_roomNumber].tab;
    }

}