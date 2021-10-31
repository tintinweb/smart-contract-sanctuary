/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

pragma solidity 0.5.1;

contract Counter {
    uint count = 0;
    
    event Increment(uint value);
    event Decrement(uint value);
    
    function getCount() view public returns(uint){
        return count;
    }
    function increment() public {
        count++;
        emit Increment(count);
    }
     function decrement() public {
        count--;
        emit Decrement(count);
    }
}