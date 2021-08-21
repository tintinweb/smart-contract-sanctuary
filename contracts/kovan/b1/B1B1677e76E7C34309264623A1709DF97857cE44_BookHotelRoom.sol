/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

/**
 * A simple contract the let users book hotel rooms.
 * This contract has four basic functionalities which let the the owner set the cost of room, let users book the room,
 * let users check their details and a checkout function so users can leave the room.
 * It also has a special function "receive" which let the contract receive payments. 
 * 
 */

//SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.6.0<0.9.0;

/**
 * Title: _BookHotelRoom
 * An abstract contract in which all the functions are defined which is used as base for the contract BookHotelRoom.
 */

abstract contract _BookHotelRoom{
    //sets the cost of the rooms
    function set_Room_Cost(uint256 _cost) external virtual returns(uint256);
    
    //sets the total available rooms
    function set_Available_Rooms(uint8 _availableRooms) external virtual returns(uint8);
    
    //let users book the room
    function Book_Room(string memory _UserName, uint56 _mobile_No) external payable virtual returns(uint8 total_Rooms_Available);
    
    //let users check their details
    function check_User_Details() external view virtual returns(address, string memory, uint56);
    
    //let users leave the room
    function checkOut() external virtual returns(uint8 total_Rooms_Available);
    
    
}

/**
 * Title: modified
 * This contract contains all the the modifiers used in BookHotelRoom contract
 */
contract modified{
     //declaring a public variable total_Rooms_Available to keep the count of available rooms
     uint8 public total_Rooms_Available;
     address payable public owner;
     address[] BookedRooms;
     
     enum RoomStatus{ Vacant, Occupied } // defining an enum RoomStatus
     RoomStatus roomStatus;
     
    modifier OnlyOwner{
        require(msg.sender==owner, "You are not the owner");
        _;
    }
     
     modifier OnlyUser{
        bool _OnyUser=false; //defining and setting the variable _OnyUser to false, which means the user is not in the database.
        for(uint i=0;i<BookedRooms.length;i++){ //This loop checks whether the user is present in the BookedRooms array and returns true.
            if(BookedRooms[i]==msg.sender){
                _OnyUser=true;
            }
                
        }
        
        
        require(_OnyUser," You have no booked rooms!!");
        _;
    }
    
    modifier onlyWhenVacant{
        //this checks whether the user has booked a room or not and is present in the array 
        for (uint i=0;i<BookedRooms.length;i++){
            if(BookedRooms[i]!=msg.sender){
                roomStatus = RoomStatus.Vacant;
            }
            else{
                roomStatus = RoomStatus.Occupied;
            }
        }
        require(roomStatus == RoomStatus.Vacant,"Room Ocuppied");
        _;
    }
    
     modifier bookCost(uint256 _cost){
        require(msg.value >= _cost, "Not enough ether");
        _;
    }
    
    modifier isAvailable{
        require(total_Rooms_Available>0,"No Rooms Available");
        _;
    }
 }
 
 /**
  * Title: BookHotelRoom
  * This contract extends abstract contract _BookHotelRoom and contract  modified
  */ 

contract BookHotelRoom is _BookHotelRoom, modified{
   
   
    uint256 cost;
    
    //defining an event Occupy
    event Occupy(address Occupant, uint value);
    
    //defining an event Checkout
    event Checkout(address _Occupant, string Empty);
    
    
    //defining a struct MyBooking 
    struct MyBooking{
        address UserAddress;
        string Name_Of_The_Occupant;
        uint56 mobile_No;

    } 
    
    
    //defining a mapping with address as key and MyBooking as value
    mapping(address => MyBooking) MyRoom;
    
    //initializing values
    constructor(){
        
        owner = payable (msg.sender);
        roomStatus = RoomStatus.Vacant;
       
    }
    
    //setting the cost of rooms and modifier "OnlyOwner" let only the owner set the cost
    function set_Room_Cost(uint256 _cost) external override OnlyOwner returns(uint256){
        cost = _cost;
        return cost;
    }
    
    //this function lets the owner set the total available rooms
    function set_Available_Rooms(uint8 _availableRooms) external override OnlyOwner returns(uint8){
        total_Rooms_Available = _availableRooms;
        return total_Rooms_Available;
    }
   
   //this function let the users book the room and takes user details and store it in the mapping
   function Book_Room(string memory _UserName, uint56 _mobile_No ) payable override external onlyWhenVacant isAvailable bookCost(cost) returns(uint8){
        
        MyRoom[msg.sender] = MyBooking(msg.sender, _UserName, _mobile_No); // 
        
        roomStatus = RoomStatus.Occupied;
        owner.transfer(msg.value);              //transfering value to the owner
        emit Occupy(msg.sender, msg.value);     
        BookedRooms.push(msg.sender);
        total_Rooms_Available--;                //total_Rooms_Available decreasing by 1
        
        return total_Rooms_Available;
    }
    
    receive() payable external { }              // a special function that let this contract receive payments
     
     
    //this function let users check their details and only the users can access it
    function check_User_Details() external view override OnlyUser returns(address, string memory, uint56){
        return(MyRoom[msg.sender].UserAddress, MyRoom[msg.sender].Name_Of_The_Occupant, MyRoom[msg.sender].mobile_No);
    }
    
    
    //this function let the user checkOut or leave the room 
    function checkOut() external override  OnlyUser returns(uint8){
        
        //this loop checks whether the msg.sender(user) is present in the array and delete their data
        for(uint i =0; i<BookedRooms.length;i++){
            if(BookedRooms[i]==msg.sender){
                delete BookedRooms[i];
                delete MyRoom[msg.sender];
            }
        }
        
        roomStatus = RoomStatus.Vacant;             //setting roomStatus = Vacant
        emit Checkout(msg.sender, "Room_Empty_Available_For_Booking");
        total_Rooms_Available++;                    //increasing total_Rooms_Available every time someone checkOut
        return total_Rooms_Available;
    }
}