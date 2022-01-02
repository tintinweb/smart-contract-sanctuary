/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

pragma solidity ^0.5.0;

contract TokenERC20 {
	function transferFrom( address from, address to, uint value) public returns (bool ok);
}

contract BurnToken{
	function staking(TokenERC20[] memory _tokenAddress, uint256[] memory _value) public returns (bool) {
		require(_tokenAddress.length == _value.length);
		for (uint8 i = 0; i < _tokenAddress.length; i++) {
			require(_tokenAddress[i].transferFrom(msg.sender, address(0), _value[i]));
		}
		return true;
	}
}