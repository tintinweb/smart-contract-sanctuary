/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <0.9.0;

contract SimpleStorage {
	string private _data = "Hello World";

	function getData() public view returns (string memory data) {
		return _data;
	}

	function setData(string memory newData) public {
		_data = newData;
	}
}