/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.6.6;

library SafeMath {
	function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
	function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
}