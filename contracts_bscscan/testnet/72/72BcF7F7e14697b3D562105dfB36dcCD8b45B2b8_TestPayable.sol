// SPDX-License-Identifier: WTFPL License
pragma solidity >=0.6.0;

contract TestPayable {
	mapping(address => uint256) public sentValues;

	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	function test() public payable {
		uint256 val = msg.value;
		sentValues[msg.sender] = val;
	}

	// Internal function to handle safe transfer
	function safeTransferBNB(address to, uint256 value) internal {
		(bool success, ) = to.call{ value: value }(new bytes(0));
		require(success, "TransferHelper: BNB_TRANSFER_FAILED");
	}

	function withdraw() public {
		require(msg.sender == owner);

		uint256 totalBalance = address(this).balance;

		safeTransferBNB(msg.sender, totalBalance);
	}
}

