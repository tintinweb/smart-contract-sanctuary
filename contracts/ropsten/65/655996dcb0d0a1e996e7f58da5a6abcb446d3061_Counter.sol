/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.8.1;

contract Counter {
    uint public count = 0;
    
    event Increment(uint value);
    event Decrement(uint value);
    
    function increment() public {
        count += 1;
        emit Increment(count);
    }
    
    function decrement() public {
        count -= 1;
        emit Decrement(count);
    }
}