/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.6.0;

contract Hotel {

    address public hotelAddress = 0x6F71B9473382a19C0Ca3df4bdEA77B98daEef6c7;
    string public hotelName;
    uint roomsNum = 52;
    //0x6F71B9473382a19C0Ca3df4bdEA77B98daEef6c7
    //, uint _rooms address _address,

    constructor(string memory _name) public {
        hotelName = _name;
    }

    mapping(uint => bool) occupied;
    mapping(uint => uint) capacity;

    //izbacivanje gosta
    function _kickGuest(uint _id) private {
        require(msg.sender == hotelAddress);
        occupied[_id] = false;
    }

    //rezervacija sobe
    function rentRoom(uint _id, uint _guests) public {
        if(occupied[_id] == true && capacity[_id] >= _guests) {
            occupied[_id] = true;
        }
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
    function _roomsCapacity() private {
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