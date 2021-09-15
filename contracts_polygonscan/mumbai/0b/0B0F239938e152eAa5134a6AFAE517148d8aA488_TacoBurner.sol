/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

interface ITacoParty {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 _amount) external;
}

contract TacoBurner {
    
    address public tacoparty;
    mapping(address => uint256) public burnTotals; 
    
    constructor(address _tacoparty){
        tacoparty = _tacoparty;
    }
    
    function burn() public {
        uint256 tokenBalance = ITacoParty(tacoparty).balanceOf(address(this));
        ITacoParty(tacoparty).burn(tokenBalance);
        burnTotals[msg.sender]+=tokenBalance;
    }
}