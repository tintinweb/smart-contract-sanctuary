/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.4.21;

contract User{
	struct UserStruct{
		bytes16 name;
		bytes32 location;
		uint city;
		uint province;
		bytes32 wa;
		uint index;
	}
	address[] private userIndex;
	address private owner;
	mapping(address => UserStruct) private addressToUser;
	mapping(address => uint256) private lastBalance;

	event NewUser(address indexed userAddress, uint index, bytes16 userName, bytes32 userLocation, uint city, uint province, bytes32 userWa);
	event UpdateUser(address indexed userAddress, uint index, bytes16 userName, bytes32 userLocation, uint city, uint province, bytes32 userWa);
	event DeleteUser(address indexed userAddress, uint index);

	modifier onlyOwner(){
		require(msg.sender == owner);
		_;
	} 

	function User() public{
		owner = msg.sender;
	}

	function isUser(address _userAddress) public view returns(bool isIndeed) {
		if(userIndex.length == 0) return false;
		return (userIndex[addressToUser[_userAddress].index] == _userAddress);
	}

	function createUser(address _userAddress, bytes16 _name, bytes32 _location, uint _city, uint _province, bytes32 _wa) public returns(bool success){
		require(!isUser(_userAddress));

		addressToUser[_userAddress].name = _name;
		addressToUser[_userAddress].location = _location;
		addressToUser[_userAddress].city = _city;
		addressToUser[_userAddress].province = _province;
		addressToUser[_userAddress].wa = _wa;
		addressToUser[_userAddress].index = userIndex.push(_userAddress)-1;

    	emit NewUser(_userAddress, addressToUser[_userAddress].index, _name, _location, _city, _province, _wa);

    	return true;
	}

	function deleteUser(address _userAddress) public returns(bool success){
		require(isUser(_userAddress));

		uint indexToDelete = addressToUser[_userAddress].index;
		address toMove = userIndex[userIndex.length-1];
		userIndex[indexToDelete] = toMove;
		addressToUser[toMove].index = indexToDelete;
		userIndex.length--;

		emit DeleteUser(_userAddress, indexToDelete);
		emit UpdateUser(toMove, indexToDelete, addressToUser[toMove].name, addressToUser[toMove].location, addressToUser[toMove].city, addressToUser[toMove].province, addressToUser[toMove].wa);
    
    	return true;
	}

	function updateName(address _userAddress, bytes16 _name) public returns(bool success){
		require(isUser(_userAddress));

		addressToUser[_userAddress].name = _name;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].index, _name, addressToUser[_userAddress].location, addressToUser[_userAddress].city, addressToUser[_userAddress].province, addressToUser[_userAddress].wa);
		
		return true;
	}

	function updateLocation(address _userAddress, bytes32 _location) public returns(bool success){
		require(isUser(_userAddress));

		addressToUser[_userAddress].location = _location;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].index, addressToUser[_userAddress].name, _location, addressToUser[_userAddress].city, addressToUser[_userAddress].province, addressToUser[_userAddress].wa);
		
		return true;
	}

	function updateCity(address _userAddress, uint _city) public returns(bool success){
		require(isUser(_userAddress));

		addressToUser[_userAddress].city = _city;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].index, addressToUser[_userAddress].name, addressToUser[_userAddress].location, _city,addressToUser[_userAddress].province, addressToUser[_userAddress].wa);
		
		return true;
	}


	function updateProvince(address _userAddress, uint _province) public returns(bool success){
		require(isUser(_userAddress));

		addressToUser[_userAddress].province = _province;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].index, addressToUser[_userAddress].name, addressToUser[_userAddress].location, addressToUser[_userAddress].city, _province, addressToUser[_userAddress].wa);
		
		return true;
	}	

	function updateWa(address _userAddress, bytes32 _wa) public returns(bool success){
		require(isUser(_userAddress));

		addressToUser[_userAddress].wa = _wa;

		emit UpdateUser(_userAddress, addressToUser[_userAddress].index, addressToUser[_userAddress].name, addressToUser[_userAddress].location, addressToUser[_userAddress].city, addressToUser[_userAddress].province, _wa);
		
		return true;
	}

	function saveBalance(address _userAddress) public returns(bool success){
		lastBalance[_userAddress] = _userAddress.balance;

		return true;
	}

	function getBalance(address _userAddress) public view returns(uint256 userBalance) {
		return lastBalance[_userAddress];
	}
	

	function getOwner() public view returns(address author){
		return owner;
	}

	function getUserCount() public view returns(uint count) {
		return userIndex.length;
	}

	function getAddressByIndex(uint _index) public view returns(address userAddress){
		return userIndex[_index];
	}

	function getNameByIndex(uint _index) public view returns(bytes16 userName){
		return addressToUser[getAddressByIndex(_index)].name;
	}

	function getLocationByIndex(uint _index) public view returns(bytes32 userLocation){
		return addressToUser[getAddressByIndex(_index)].location;
	}

	function getCityByIndex(uint _index) public view returns(uint userLocation){
		return addressToUser[getAddressByIndex(_index)].city;
	}

	function getProvinceByIndex(uint _index) public view returns(uint userLocation){
		return addressToUser[getAddressByIndex(_index)].province;
	}		

	function getWaByIndex(uint _index) public view returns(bytes32 userWa){
		return addressToUser[getAddressByIndex(_index)].wa;
	}

	function getIndexByAddress(address _userAddress) public view returns(uint index){
		return addressToUser[_userAddress].index;
	}
}