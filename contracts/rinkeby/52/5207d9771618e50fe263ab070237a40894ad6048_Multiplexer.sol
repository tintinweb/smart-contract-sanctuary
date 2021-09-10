pragma solidity ^0.4.16;

import './TRC20.sol';

contract Multiplexer {

	function sendTrx(address[] _to, uint256[] _value) payable returns (bool _success) {
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		uint256 beforeValue = msg.value;
		uint256 afterValue = 0;
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			assert(_to[i].send(_value[i]));
		}
		uint256 remainingValue = beforeValue - afterValue;
		if (remainingValue > 0) {
			assert(msg.sender.send(remainingValue));
		}
		return true;
	}

	function sendToken(address _tokenAddress, address[] _to, uint256[] _value) returns (bool _success) {
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		TRC20 token = TRC20(_tokenAddress);
		for (uint8 i = 0; i < _to.length; i++) {
			assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
		}
		return true;
	}
}