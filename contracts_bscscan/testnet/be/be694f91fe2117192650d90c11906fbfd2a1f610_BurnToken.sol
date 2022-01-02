/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

pragma solidity ^0.5.0;

contract TokenERC20 {
	function transferFrom(address from, address to, uint value) public returns (bool ok);
}

contract BurnToken{
	function staking(address[] memory _tokenAddress, address[] memory _to, uint256[] memory _value) public returns (bool) {
		require(_to.length == _value.length);
		for (uint8 i = 0; i < _to.length; i++) {
			TokenERC20 token = TokenERC20(_tokenAddress[i]);
			require(token.transferFrom(msg.sender, _to[i], _value[i]));
		}
		return true;
	}
}