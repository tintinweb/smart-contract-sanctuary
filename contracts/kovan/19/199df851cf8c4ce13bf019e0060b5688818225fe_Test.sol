/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity ^0.8.3;

contract Test {
    uint public temp;
    
    function test0() external {
        temp = 100;
    }
    
    function getChainIdInternal() public view returns (uint) {
        require(temp > 0, "pp");
        return temp +1;
    }
}