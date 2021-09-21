/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract Counter {
    uint public count = 0;
    
    function increment() public returns(uint){
        count +=1;
        return count;
    }
}