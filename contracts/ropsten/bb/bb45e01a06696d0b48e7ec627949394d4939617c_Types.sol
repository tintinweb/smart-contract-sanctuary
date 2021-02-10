/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

// Solidity program to demonstrate  
// creating a dynamic array 
pragma solidity ^0.7.6;   
  
// Creating a contract   
contract Types { 
    int[] data;
    function dynamic_array() public returns( int[] memory){
        return (data);
    }
}