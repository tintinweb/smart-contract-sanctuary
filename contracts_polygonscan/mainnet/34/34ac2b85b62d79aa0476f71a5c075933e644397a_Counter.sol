/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

pragma solidity 0.6.12;

contract Counter {
    uint public count = 0;
    
    function increment() public returns(uint){
        count += 1;
        return count;
    }
}