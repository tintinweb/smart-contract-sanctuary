//SourceUnit: ChangeAsc1.sol

pragma solidity ^0.5.0;

contract ChangeAsc1 {

	event ChangeEvent(address indexed from, string toAscAddress, uint256 num);

	function change(string memory _toAscAddress, uint256 _num) public returns (bool) {
		emit ChangeEvent(msg.sender, _toAscAddress, _num);
		return true;
	}
}