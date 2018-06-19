pragma solidity ^0.4.18;

contract ZperPreSale {

	uint256 public totalContributed;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public hardCap;
	address public owner;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	function ZperPreSale (address _owner, uint256 _start, uint256 _end, uint256 _cap) public {
		owner = _owner;
		startTime = _start;
		endTime = _end;
		hardCap = _cap * (10 ** 18);
	}

	function () external payable {
		require(now >= startTime && now <= endTime);
		require(hardCap >= msg.value + totalContributed);
		totalContributed += msg.value;
	}

	modifier onlyOwner() {
		assert(msg.sender == owner);
		_;
	}

	function showContributed() public constant returns (uint256 total) {
		return totalContributed;
	}

	function forwardFunds(address _to, uint256 _value) onlyOwner public returns (bool success) {
		require(_to != address(0));
		_to.transfer(_value);
		Transfer(address(0), _to, _value);
		return true;
	}

}