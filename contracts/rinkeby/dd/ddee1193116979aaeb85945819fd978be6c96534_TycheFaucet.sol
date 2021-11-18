/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity ^0.8.0;

contract TycheFaucet {

	address owner;

	constructor() public {
		owner = msg.sender;
	}

	function whitelistUsers(address payable[] memory _users) public {
		require(msg.sender == owner);

		for (uint i = 0; i < _users.length; i++) {
			_users[i].transfer(100000000000000000);
		}
	}

	receive() payable external {}
	fallback() payable external {}
}