/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity >=0.4.22 <0.9.0;

contract Calculator {  
    int private lastValue = 0;  

    function Add(int a, int b) public returns (int) {  
        lastValue = a + b;  
        return lastValue;  
    }  
    function Subtract(int a, int b) public returns (int) {  
        lastValue = a - b;  
        return lastValue;  
    }  
    
    function LastOperation() public view returns (int) {  
        return lastValue;  
    }  
}