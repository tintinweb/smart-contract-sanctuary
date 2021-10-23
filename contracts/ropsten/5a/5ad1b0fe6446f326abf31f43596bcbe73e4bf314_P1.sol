/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity ^0.8.3;

contract P1 {
    uint public count;
    uint256 public time;
    
    function getHerDone() private {
        count = count + 1000;
    }
    
    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        count -= 1;
    }
    
    function aaaaaaaabA() public {
        count += 1;
    }
}