/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity 0.8.1;

contract Counter {
    
    // Public variable of type unsigned int to keep the number of counts
    uint256 public count = 0;

    // Function that increments our counter
    function increment() public {
        count += 1;
    }
    
    // Not necessary getter to get the count value
    function getCount() public view returns (uint256) {
        return count;
    }

}