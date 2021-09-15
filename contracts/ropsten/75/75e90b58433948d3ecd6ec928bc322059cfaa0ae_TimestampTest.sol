/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.0;

contract TimestampTest {
    
    event Time(uint256 time);
    
    function getTime() external {
        emit Time(block.timestamp);
    }
}