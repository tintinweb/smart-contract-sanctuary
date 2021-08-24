/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

pragma solidity ^0.8.7;

contract AutoTaskTest {
    uint256 calls;
    
    uint256 events;
    
    event Update(uint256 id); 
    
    function update() public virtual returns (bool) {
        calls += 1;
        emit Update(calls);
        return true;
    }
    
    function eventUpdate() public virtual returns (bool) {
        events += 1;
        return true;
    }
}