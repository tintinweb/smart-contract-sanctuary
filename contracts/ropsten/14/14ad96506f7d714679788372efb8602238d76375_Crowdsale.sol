pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract Crowdsale {
    
    address public owner;
    Token public tokenERC20;
    event Transfer(address _to, uint _value);
    
    constructor() public {
        owner = msg.sender;
        tokenERC20 = Token(0xA35c38592e5C3B12E78d1A8928493B37f775127F);
    }

    function () payable public {
        require(msg.value > 0);
	    tokenERC20.transfer(msg.sender, msg.value);
        emit Transfer(msg.sender, msg.value);
        owner.transfer(msg.value);
    }
}