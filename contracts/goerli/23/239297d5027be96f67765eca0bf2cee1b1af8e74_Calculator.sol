/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity >= 0.4.22 < 1;

contract Calculator{
    int private result;
    
    function add(int a, int b) public view returns (int c){
        c = a + b;
        return c;
        
    }
    
    function getResult() public view returns (int){
        
        return result;
        
    }
    
    
}