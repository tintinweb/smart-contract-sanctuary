pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract Crowdsale {
    
    address public owner;
    Token public token;
    event Transfer(address _to, uint256 _value);
    
    constructor() public {
        owner = msg.sender;
        token = Token(0x488598cbe5c44649E5b5eE95D17BB255C76954f2);
    }

    function buy() payable public {
        require(msg.value > 0);
	    token.transfer(msg.sender, msg.value);
        emit Transfer(msg.sender, msg.value);
        owner.transfer(msg.value);
    }
}