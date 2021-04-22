/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.24;

contract Callee {
    uint[] public values; 
    
    function getValue(uint initial) public pure returns(uint) {
        return initial + 150; 
        
    } 
    
    function storeValue(uint value) public {
        values.push(value); 
        
    }
    
    function getValues() public view returns(uint) {
        return values.length; 

    } 
    
}