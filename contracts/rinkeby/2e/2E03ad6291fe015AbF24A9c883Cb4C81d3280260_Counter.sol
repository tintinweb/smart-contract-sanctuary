/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.6.0;

contract Counter {
    uint256 count;
    
    function getCount() public view returns(uint256) {
        return count;
    }
    
    
    
    function increment() public {
        // increment count
        count++;
    }
}