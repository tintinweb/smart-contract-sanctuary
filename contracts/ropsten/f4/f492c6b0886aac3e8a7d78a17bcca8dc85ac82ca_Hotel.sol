/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.6.0;

contract Hotel {

    address public hotelAddress;
    string public hotelName;
    uint roomsNum;

    constructor(string memory _name, uint _rooms) public {
        hotelAddress = 0x6F71B9473382a19C0Ca3df4bdEA77B98daEef6c7;
        hotelName = _name;
        roomsNum = _rooms;
    }

    mapping(uint => bool) occupied;
    mapping(uint => uint) capacity;

    //izbacivanje gosta
    function kickGuest(uint _id) public {
        require(msg.sender == hotelAddress);
        occupied[_id] = false;
    }

    //rezervacija sobe
    function rentRoom(uint _id, uint _guests) public {
        require(occupied[_id] == false && capacity[_id] >= _guests);

       // if(occupied[_id] == true && capacity[_id] >= _guests) {
            occupied[_id] = true;
        //}
    }

    //prazne sobe
    function emptyRooms() view public returns (uint) {
        uint res = 0;

        for (uint  i = 0; i < roomsNum; i++) {
            if(occupied[i] == true) {
                res++;
            }
        }

        return res;
    }

    //inicijalizacija kapaciteta
    function roomsCapacity() public {
        uint rand;

        for (uint i = 0; i < roomsNum; i++) {
            rand = uint(keccak256(abi.encodePacked(now, msg.sender, i))) % 6 + 1;
            capacity[i] = rand;
        }

    }

    //provera za broj sobe
    modifier isPossible(uint _number) {
        require(roomsNum >= _number, "Room with that number doesn`t exist.");
        _;
    }

}