//SourceUnit: CancelPledge.sol

pragma solidity ^0.5.0;

contract CancelPledge {

	event CancelEvent(address indexed from, string pledgeId);

	function cancel(string memory _pledgeId) public returns (bool) {
		emit CancelEvent(msg.sender, _pledgeId);
		return true;
	}
}