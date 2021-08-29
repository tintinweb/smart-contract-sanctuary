/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity ^0.8.0;

contract Go {
    
    uint256 public v;
    
    function g(uint256 id) public {
        require(id <= 1000);
        v = id;
    }
}