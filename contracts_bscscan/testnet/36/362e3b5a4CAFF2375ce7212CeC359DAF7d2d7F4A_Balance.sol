/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
interface IBEP20 {
	function balanceOf(address account) external view returns (uint256);
}
contract Balance {
	function getBalance(address _account, IBEP20[] memory _tokens) public view returns(uint256[] memory tokensBal_)
	{
		tokensBal_ = new uint256[](_tokens.length);
		for (uint256 idx = 0; idx < _tokens.length; idx++) {
			tokensBal_[idx] = _tokens[idx].balanceOf(_account);
		}
	}
}