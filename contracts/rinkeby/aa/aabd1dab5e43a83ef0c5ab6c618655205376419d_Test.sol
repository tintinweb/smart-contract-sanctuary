/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity ^0.8.6;

contract Test {
    uint public test = 0;
    
    function balanceOf(address user_) public view returns (uint) {
        require(user_ != address(0), "Trying to take zero address balance");

        return test;
    }

    function balanceOf2(address user_) public view returns (uint) {
        user_;
        
        return test;
    }
}