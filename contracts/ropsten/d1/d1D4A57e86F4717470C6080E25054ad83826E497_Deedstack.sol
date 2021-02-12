/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity >=0.4.25 <0.7.0;

contract Deedstack {

	string private _info;

	function getInfo() public view returns (string memory) {
			return _info;
	}

	constructor(string memory __info) public {
		_info = __info;
	}
}