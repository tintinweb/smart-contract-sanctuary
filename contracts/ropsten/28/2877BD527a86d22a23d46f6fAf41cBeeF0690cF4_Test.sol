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

	uint balance;

	constructor() public {
		balance = 0;
	}

	function close() public onlyOwner {
		selfdestruct(owner);
	}

	function deposit() public onlyOwner payable {
		balance += msg.value;
	}

	function viewBalance() public pure returns (uint balance) {
        return balance;
    }
}