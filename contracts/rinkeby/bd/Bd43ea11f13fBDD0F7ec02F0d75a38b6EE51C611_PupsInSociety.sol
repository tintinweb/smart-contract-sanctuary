//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract PupsInSociety  {	
	

	address payable public owner;
	
	enum RoomStatus { Vacant, Occupied }
	struct Rooms {
		string customerName;
		uint bookedSinceStamp;
		uint bookedTillStamp;
		RoomStatus status;
	}

	mapping(uint => Rooms) public roomRecords;

	constructor()  {
		owner = payable(msg.sender);
	}

	function ownerBalance() public view returns (uint) {
		return address(this).balance;
	}

	function bookHotel(uint roomNumber, string memory Name) public payable {
		//owner.transfer(msg.value);
		
		require(roomRecords[roomNumber].status == RoomStatus.Vacant,"This room is already occupied!");
		roomRecords[roomNumber].status = RoomStatus.Occupied;
		roomRecords[roomNumber].customerName = Name;
		roomRecords[roomNumber].bookedSinceStamp = block.timestamp;
		roomRecords[roomNumber].bookedTillStamp = block.timestamp + 86400;


	}
}