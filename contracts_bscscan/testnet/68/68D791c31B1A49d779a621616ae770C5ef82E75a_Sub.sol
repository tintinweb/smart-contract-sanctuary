/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

pragma solidity =0.6.12;

contract Sub {
    uint256 public a;
    uint256 public b;
    function initialize(uint256 _a, uint256 _b) external {
        a = _a;
        b = _b;
    }
}