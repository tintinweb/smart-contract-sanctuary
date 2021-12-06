/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

pragma solidity 0.8.7;

contract Counter {
    uint count = 0;

    event Increment(uint value);
    event Decrement(uint value);

    constructor() public {
        count = 0;
    }

    function getCount() view public returns(uint) {
        return count;
    }
    
    function increment() public {
        count += 1;
        emit Increment(count);
    }   

    function decrement() public {
        count -= 1;
        emit Decrement(count);
    }
}