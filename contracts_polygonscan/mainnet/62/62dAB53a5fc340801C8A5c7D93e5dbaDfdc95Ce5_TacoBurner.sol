// SPDX-License-Identifier: MIT

// Super simple function will burn the tokens sent.
// Ownership cannot be changed, but it simply calls a token's burn function.

pragma solidity ^0.8.4;  // Includes SafeMath functions in the compiler

interface ITacoParty {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 _amount) external;
}

contract TacoBurner {
    
    address public immutable tacoparty;  // fix recommended by Paladin
    mapping(address => uint256) public burnTotals; 
    
    constructor(address _tacoparty){
        tacoparty = _tacoparty;
    }
    
    function burn() external {  // fix recommended by Paladin
        uint256 tokenBalance = ITacoParty(tacoparty).balanceOf(address(this));
        ITacoParty(tacoparty).burn(tokenBalance);
        burnTotals[msg.sender] += tokenBalance;
    }
}

