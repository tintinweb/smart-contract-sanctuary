/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

	struct Osef {
		uint id;
		uint protocol;
		uint data;
	}

	Osef[] private listOsef;
	uint private constant nbOsef = 2;

	constructor() {
		Osef memory newOsef1 = Osef(0, 12, 125687);
		listOsef.push(newOsef1);
		Osef memory newOsef2 = Osef(1, 1587, 10000000000);
		listOsef.push(newOsef2);
	}

	function getOsef(uint _id) public view returns (Osef memory) {
		(bool result, uint id) = getIndexOsef(_id);
		require(result, "Osef isn't registered.");
		return listOsef[id];
		/*if (result) {
			return listCharacters[id];
		}*/
	}

	function getIndexOsef(uint _id) private view returns (bool, uint) {
		for (uint i = 0; i < nbOsef; i++) {
			if (listOsef[i].id == _id) {
				return (true, i);
			}
		}
		return (false, 0);
	}
}