/**
 *Submitted for verification at arbiscan.io on 2021-12-31
*/

pragma solidity ^0.7.0;

contract Adoption {


    event PetAdopted(uint returnValue);

	address[16] public adopters = [
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),	
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),
		address(0),
		address(0)
	];

	// Adopting a pet
	function adopt(uint petId) public returns (uint) {
  		require(petId >= 0 && petId <= 15);

  		adopters[petId] = msg.sender;
        emit PetAdopted(petId);
  		return petId;
	}

	// Retrieving the adopters
	function getAdopters() public view returns (address[16] memory) {
  		return adopters;
	}
}