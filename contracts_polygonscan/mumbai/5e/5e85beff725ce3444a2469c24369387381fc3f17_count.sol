/**
 *Submitted for verification at polygonscan.com on 2021-06-26
*/

pragma solidity 0.8.0;

contract count {
    
    uint256 public count = 0;
    
    function harvest() public{
        count = count + 1;
    }
    
}