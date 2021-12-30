/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.6.0;

library withCreate {

    function createMe1() public returns (address _a)
	{
		return address(new beingCreated1());
	}

    function createMe2() public returns (address _a)
	{
		return address(new beingCreated2());
	}
}

contract beingCreated1 {
    function add(uint256 _a, uint256 _b) public pure returns (uint256) {
        return _a + _b;
    }
}

contract beingCreated2 is beingCreated1 {
    function minus(uint256 _a, uint256 _b) public pure returns (uint256) {
        return _a - _b;
    }
}