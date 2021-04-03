pragma solidity =0.8.3;

import "./token1.sol";

contract DeCalled2 {
    address public owner;
    Token public token;
    
    constructor() {
        owner = msg.sender;
        token = new Token();
    }
    
    function transfer(uint256 amount) public {
        token.transfer(owner, amount);
    }
}