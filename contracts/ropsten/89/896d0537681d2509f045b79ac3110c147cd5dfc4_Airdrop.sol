pragma solidity ^0.4.18;

contract ERC20Interface {
	function transfer(address _recipient, uint256 _value) public returns (bool success);
}

contract Airdrop {
	function airdrop(address token, address[] recipients, uint256 value) public {
		for (uint256 i = 0; i < recipients.length; i++) {
			ERC20Interface(token).transfer(recipients[i], value);
		}
	}
}