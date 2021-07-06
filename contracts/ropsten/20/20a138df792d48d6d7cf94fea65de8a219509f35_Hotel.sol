/**
 *Submitted for verification at Etherscan.io on 2021-07-06
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
    mapping(uint => uint) guestsNum;

    //izbacivanje gosta
    function kickGuest(uint _id) public isPossible(_id) {
        require(msg.sender == hotelAddress);
        occupied[_id] = false;
    }

    //rezervacija sobe
    function rentRoom(uint _id, uint _guests) public isPossible(_id) {

        if (occupied[_id] == false && capacity[_id] >= _guests) {
            occupied[_id] = true;
            guestsNum[_id] = _guests;
        }
    }

    //prazne sobe
    function emptyRooms() view public returns (uint) {
        uint res = 0;

        for (uint  i = 0; i < roomsNum; i++) {
            if(occupied[i] == false) {
                res++;
            }
        }

        return res;
    }

    //trenutan broj ljui u hotelu
    function currGuestsNum() view public returns (uint) {
        uint res = 0;

        for (uint  i = 0; i < roomsNum; i++) {
            res += guestsNum[i];
        }

        return res;
    }

    //inicijalizacija
    function initialize() public {
        uint rand;

        for (uint i = 0; i < roomsNum; i++) {
            rand = uint(keccak256(abi.encodePacked(now, msg.sender, i))) % 6 + 1;
            capacity[i] = rand;
        }

        for (uint i = 0; i < roomsNum; i++) {
            occupied[i] = false;
        }

    }

    //provera za broj sobe
    modifier isPossible(uint _number) {
        require(roomsNum >= _number, "Room with that number doesn`t exist.");
        _;
    }

}