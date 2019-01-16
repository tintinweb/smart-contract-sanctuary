pragma solidity ^0.5.0;

contract AppRegistry {
	event Registration(address indexed registrar, bytes8 appId);

	function register() external {
		bytes8 appId = bytes8(keccak256(abi.encodePacked(block.number)));
		emit Registration(msg.sender, appId);
	}
}