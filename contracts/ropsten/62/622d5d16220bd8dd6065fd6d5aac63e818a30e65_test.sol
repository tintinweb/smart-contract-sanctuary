/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.0;

contract test{
    uint256 a;
    uint256 b;
    
    function plus(uint256 a, uint256 b) public view returns(uint256){
        return a+b;
    }
    
    function minus(uint256 a, uint256 b) public view returns(uint256){
        return a-b;
    }
    
    function multi(uint256 a, uint256 b) public view returns(uint256){
        return a*b;
    }
    
    function mod(uint256 a, uint256 b) public view returns(uint256){
        return a/b;
    }
}