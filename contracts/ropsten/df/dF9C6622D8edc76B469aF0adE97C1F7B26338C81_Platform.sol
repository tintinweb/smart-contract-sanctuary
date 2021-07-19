/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.8.0;

contract Platform {
    
    //VARIABLES
    mapping (address => uint256) private tournament;
    
    //FUNCTIONS
    function subscribe(uint256 _tournament) external {
        tournament[msg.sender] = _tournament;
    }
}