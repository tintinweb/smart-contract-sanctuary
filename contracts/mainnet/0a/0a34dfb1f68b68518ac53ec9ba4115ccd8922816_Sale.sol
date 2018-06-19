// Copyright New Alchemy Limited, 2017. All rights reserved.

pragma solidity >=0.4.10;

contract Token {
	function balanceOf(address addr) returns(uint);
	function transfer(address to, uint amount) returns(bool);
}

contract Sale {
	address public owner;    // contract owner
	address public newOwner; // new contract owner for two-way ownership handshake
	string public notice;    // arbitrary public notice text
	uint public start;       // start time of sale
	uint public end;         // end time of sale
	uint public cap;         // Ether hard cap
	bool public live;        // sale is live right now

	event StartSale();
	event EndSale();
	event EtherIn(address from, uint amount);

	function Sale() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function () payable {
		require(block.timestamp >= start);
		if (block.timestamp > end || this.balance > cap) {
			require(live);
			live = false;
			EndSale();
		} else if (!live) {
			live = true;
			StartSale();
		}
		EtherIn(msg.sender, msg.value);
	}

	function init(uint _start, uint _end, uint _cap) onlyOwner {
		start = _start;
		end = _end;
		cap = _cap;
	}

	function softCap(uint _newend) onlyOwner {
		require(_newend >= block.timestamp && _newend >= start && _newend <= end);
		end = _newend;
	}

	function changeOwner(address next) onlyOwner {
		newOwner = next;
	}

	function acceptOwnership() {
		require(msg.sender == newOwner);
		owner = msg.sender;
		newOwner = 0;
	}

	function setNotice(string note) onlyOwner {
		notice = note;
	}

	function withdraw() onlyOwner {
		msg.sender.transfer(this.balance);
	}

	function withdrawSome(uint value) onlyOwner {
		require(value <= this.balance);
		msg.sender.transfer(value);
	}

	function withdrawToken(address token) onlyOwner {
		Token t = Token(token);
		require(t.transfer(msg.sender, t.balanceOf(this)));
	}

	function refundToken(address token, address sender, uint amount) onlyOwner {
		Token t = Token(token);
		require(t.transfer(sender, amount));
	}
}