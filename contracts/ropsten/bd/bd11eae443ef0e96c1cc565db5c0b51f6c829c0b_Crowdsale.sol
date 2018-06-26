pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract Crowdsale {
    
    address public owner;
    Token public token;
    event Transfer(address _to, uint _value);
    
    constructor() public {
        owner = msg.sender;
        token = Token(0xA35c38592e5C3B12E78d1A8928493B37f775127F);
    }

    function () payable public {
        require(msg.value > 0);
	    token.transfer(msg.sender, msg.value);
        emit Transfer(msg.sender, msg.value);
        owner.transfer(msg.value);
    }
}