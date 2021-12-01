/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.4.0; 

contract Test {
    
    int counter = 0; 
    
    function test() public pure returns(string) {
        return "hello world!"; 
    }

    string public message; 
    function set(string m) public {
        message = m; 
    }
   
}