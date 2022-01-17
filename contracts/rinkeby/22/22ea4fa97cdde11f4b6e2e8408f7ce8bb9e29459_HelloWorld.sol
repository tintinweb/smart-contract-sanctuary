/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

pragma solidity ^0.8.11;
contract HelloWorld {
    uint256 counter = 5;
    function increment() public {  
        counter++;
    }
    function decrement() public { 
        counter--;
    }
}