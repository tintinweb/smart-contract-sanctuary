/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 *  	Date	 : 30 November 2020
 	Properti : bytes16 name, bytes16 wa, bytes32 location, uint index
 	Argumen	 : bytes16 _name, bytes16 _wa, bytes32 _location, uint _index
 */
contract User {
	struct UserStruct{
		bytes16 name;
		bytes16 wa;
		bytes32 location;
		uint index;
	}
	address public owner;
	address[] private userIndex;

	mapping (address => UserStruct) private addressToUser;

	event NewUser(address indexed userAddress, bytes16 name, bytes16 wa, bytes32 location, uint index);
	event UpdateUser(address indexed userAddress, bytes16 name, bytes16 wa, bytes32 location, uint index);

	modifier onlyOwner {
		require(msg.sender == owner, "You are not the contract owner");
		_;
	}
	
	function isUser(address _userAddress) public view returns(bool isRegistered){
		if(userIndex.length == 0) return false;
		return(userIndex[addressToUser[_userAddress].index] == msg.sender);
	}
	
	function createUser(address _userAddress, bytes16 _name, bytes16 _wa, bytes32 _location) public returns(bool successRegistered){
	require (!isUser(_userAddress));
	
	addressToUser[_userAddress].name = _name;
	addressToUser[_userAddress].wa = _wa;
	addressToUser[_userAddress].location = _location;
	userIndex.push(_userAddress);
	addressToUser[_userAddress].index = userIndex.length - 1;

	emit NewUser(_userAddress, _name, _wa, _location, addressToUser[_userAddress].index);
	
	return true;
	}

	function updateName(address _userAddress, bytes16 _name) public returns(bool successUpdateName){
		require (isUser(_userAddress));
		
		addressToUser[_userAddress].name = _name;

		emit UpdateUser(_userAddress, _name, addressToUser[_userAddress].wa, addressToUser[_userAddress].location, addressToUser[_userAddress].index);
		return true;
	}
	
	
	function updateWa(address _userAddress, bytes16 _wa) public returns(bool successUpdateWa){
		require (isUser(_userAddress));
		
		addressToUser[_userAddress].wa = _wa;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].name, _wa, addressToUser[_userAddress].location, addressToUser[_userAddress].index);
		return true;
	}


	function updateLocation(address _userAddress, bytes32 _location) public returns(bool successUpdateLocation){
		require (isUser(_userAddress));
		
		addressToUser[_userAddress].location = _location;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].name, addressToUser[_userAddress].wa, _location, addressToUser[_userAddress].index);
		return true;
	}

	function getUserCount() public view returns(uint count){
		return userIndex.length;
	}
	
	function getAddressByIndex(uint _index) public view returns(address userAddress){
		return userIndex[_index];
	}

	function getNameByIndex(uint _index) public view returns(bytes16 userName){
		return addressToUser[userIndex[_index]].name;
	}

	function getWaByIndex(uint _index) public view returns(bytes16 userWa){
		return addressToUser[userIndex[_index]].wa;
	}

	function getLocationByIndex(uint _index) public view returns(bytes32 userLocation){
		return addressToUser[userIndex[_index]].location;
	}

	function getIndexByAddress(address _userAddress) public view returns(uint index){
		return addressToUser[_userAddress].index;
	}
	

}