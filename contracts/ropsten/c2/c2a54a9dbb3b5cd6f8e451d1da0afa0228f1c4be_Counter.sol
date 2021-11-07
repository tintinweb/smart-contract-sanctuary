/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

pragma solidity 0.8.9;

contract Counter
{
    uint count = 0; 
    
    event Increment(uint value);
    event Decrement(uint value);
    
    function getCount() view public returns (uint)
    {
        return count;
    }
    
    function increment() public
    {
        count = count + 1;
        emit Increment(count);
    }
    
    function decrement() public
    {
        count = count -1;
        emit Decrement(count);
    }
    
}