pragma solidity ^0.4.25;

contract Owned {

	address owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(
			msg.sender == owner,
			"Only owner can call this function."
		);
		_;
	}
}

contract Test is Owned {

	function close() public onlyOwner {
		selfdestruct(owner);
	}

	function viewBalance() public view returns (uint balance) {
        return address(this).balance;
    }

	function () public onlyOwner payable {}
}