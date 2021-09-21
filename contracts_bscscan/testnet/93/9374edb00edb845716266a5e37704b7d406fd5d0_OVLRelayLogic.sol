/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// File: contracts\OVLRelayLogic.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface IRandomness {
	function getRandomNumber(uint256 _totalWeight, uint256 randomNumber) external view returns (uint256);
}

interface IOVLGarage {
	function createPart(
		uint256 category,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external;

	function createCar(
		uint256 skinId,
		uint256 bodyId,
		uint256 engineId,
		uint256 nitrousId,
		uint256 handlerId,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external;

	function destroyCar(
		uint256 carId,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external;

	function fusion(
		uint256 category,
		uint256[] memory parts,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external;
}

contract OVLRelayLogic {
	event Convert(address indexed sender, uint256 nftId, uint256 amount);

	constructor() public {}

	/////////////////////////////////////////////////////////////
	// OVLGarage
	/////////////////////////////////////////////////////////////
	function createPart(
		IOVLGarage _contract,
		uint256 category,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external {
		_contract.createPart(category, price, owner, vericationSignature, dataSignature);
	}

	function createCar(
		IOVLGarage _contract,
		uint256 skinId,
		uint256 bodyId,
		uint256 engineId,
		uint256 nitrousId,
		uint256 handlerId,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external {
		_contract.createCar(skinId, bodyId, engineId, nitrousId, handlerId, price, owner, vericationSignature, dataSignature);
	}

	function destroyCar(
		IOVLGarage _contract,
		uint256 carId,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external {
		_contract.destroyCar(carId, price, owner, vericationSignature, dataSignature);
	}

	function fusion(
		IOVLGarage _contract,
		uint256 category,
		uint256[] memory parts,
		uint256 price,
		address owner,
		bytes memory vericationSignature,
		bytes memory dataSignature
	) external {
		_contract.fusion(category, parts, price, owner, vericationSignature, dataSignature);
	}

	function getRandomNumber(
		IRandomness _contract,
		uint256 _totalWeight,
		uint256 randomNumber
	) public {
		_contract.getRandomNumber(_totalWeight, randomNumber);
		emit Convert(msg.sender, 1222, 1111);
	}
}