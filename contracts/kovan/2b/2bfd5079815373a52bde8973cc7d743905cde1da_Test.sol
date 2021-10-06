/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.8.3;

contract Test {
    uint public temp;
    
    function test0(uint96 a, uint256 b) external returns (uint96) {
        temp = add256(a, b);
        return a;
    }
    
    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }
}