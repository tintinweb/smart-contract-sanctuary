/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.6.0;

contract RevertTest {
    uint256 public num;
    function test(uint256 _num) external returns (uint256) {
        require(_num > 10, 'The num should be more than 10');
        num = _num;
        return _num;
    }
}