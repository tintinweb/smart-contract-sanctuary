pragma solidity ^0.4.18;

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract Splitter {

	address addr1 = 0xA7657C41a30FDC5F8857F44B18296b8C6aD7B752;
	address addr2 = 0xf0C08C66735F6809A5144881755C4204FB2Fed07;

	function split() public payable {
		addr1.transfer(msg.value /2);
		addr2.transfer(msg.value /2);
	}
}