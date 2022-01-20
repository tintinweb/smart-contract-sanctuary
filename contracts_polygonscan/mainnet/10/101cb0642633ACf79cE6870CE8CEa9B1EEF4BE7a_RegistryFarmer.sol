// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";

import "./IRegistryFarmer.sol";

import "./LibraryFarmer.sol";

contract RegistryFarmer is IRegistryFarmer, Ownable {
	mapping(LibraryFarmer.FarmerContract => address) public contracts;

	function updateContract(
		LibraryFarmer.FarmerContract _contract,
		address _address
	) public onlyOwner {
		contracts[_contract] = _address;
	}
}