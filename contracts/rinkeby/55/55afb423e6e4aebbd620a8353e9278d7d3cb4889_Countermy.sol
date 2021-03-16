/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity 0.5.1;

contract Countermy {
    
    uint public count = 0;
    
    event Increment(uint value);
    event Decrement(uint value);
    
    
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