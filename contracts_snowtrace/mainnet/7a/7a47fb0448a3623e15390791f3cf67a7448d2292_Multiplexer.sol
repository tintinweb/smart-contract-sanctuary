/**
 *Submitted for verification at snowtrace.io on 2022-01-12
*/

pragma solidity ^0.4.16;

contract ERC20 {
  function transferFrom( address from, address to, uint value) returns (bool ok);
}

contract Multiplexer {

	function sendEth(address[] _to, uint256[] _value) payable returns (bool _success) {
		// input validation
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		// count values for refunding sender
		uint256 beforeValue = msg.value;
		uint256 afterValue = 0;
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			assert(_to[i].send(_value[i]));
		}
		// send back remaining value to sender
		uint256 remainingValue = beforeValue - afterValue;
		if (remainingValue > 0) {
			assert(msg.sender.send(remainingValue));
		}
		return true;
	}
}