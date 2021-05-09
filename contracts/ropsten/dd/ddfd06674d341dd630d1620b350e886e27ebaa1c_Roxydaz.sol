pragma solidity ^0.4.24;

import "./StandardToken.sol";

contract Roxydaz is StandardToken {
    string public constant symbol = "RXDZ";
    string public constant name = "Roxydaz";
    uint256 public constant decimal = 18;

    uint256 internal constant maxTokens = 100000000000;
    
    constructor() public {
        totalSupply_ = maxTokens;
        balances[msg.sender] = maxTokens;
    }
}