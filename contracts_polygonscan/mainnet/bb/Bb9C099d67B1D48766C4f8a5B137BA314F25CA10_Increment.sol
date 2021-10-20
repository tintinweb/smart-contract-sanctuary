/**
 *Submitted for verification at polygonscan.com on 2021-10-20
*/

pragma solidity >=0.7.0 <0.9.0;

contract Increment {
     uint public count;
    
    function increment() public returns(uint) {
        count+=1;
        return count;
    }
    
    
}