/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    uint256 number;
    
    function Set(uint256 num) public {
        number = num;
    }
    
    function Get() public view returns (uint256) {
        return number;
    }
}