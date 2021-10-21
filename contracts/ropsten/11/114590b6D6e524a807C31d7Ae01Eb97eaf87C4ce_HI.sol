/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity 0.8.0;

contract HI {
    uint256 cnt = 0;
    
    function sayHi() external pure returns (string memory) {
        return "HI";
    }
    
    function state() external view returns (uint256) {
        return cnt;
    }
    
    function increase() external {
        cnt += 1;
    }
}