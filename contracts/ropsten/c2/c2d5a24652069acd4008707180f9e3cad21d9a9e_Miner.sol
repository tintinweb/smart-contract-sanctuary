pragma solidity >=0.4.22 <0.6.0;
contract Miner {
    struct miner{
        uint8 price;
    }
    struct Room{
        uint id;
        uint8 person_limit;
        uint8 money;
        bool finish;
        address owner;
        address[] player_list;
    }
    
    
    Room[] RoomList;
    
    event synRoom(address[]);
    //mapping (address => miner) public Player;
    function createRoom(uint8 person_limit,uint8 money)public returns(uint) {
        address[] memory list;
        RoomList.push(Room(RoomList.length,person_limit,money,false,msg.sender,list));
        return RoomList.length;
        
    }
    
    function intoRoom(uint id) public{
        require(RoomList[id].finish==false && RoomList[id].player_list.length < RoomList[id].person_limit);
        RoomList[id].player_list.push(msg.sender);
       
    }
    
}