pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract Crowdsale {
    
    address public owner;
    Token public tokenReward;
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    modifier isowner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        tokenReward = Token(0xD57eec4f0217924E0fA9652579Eb84eDFfee2B01);
    }

    function setOwner(address _owner) isowner public {
        owner = _owner;      
    }
    
    function sendToken(address _to, uint256 _value) isowner public {
        tokenReward.transfer(_to, _value);      
    }
    
    function kill() isowner public {
        selfdestruct(owner);
    }

    function buy() payable public {
        require(msg.value > 0);
	    tokenReward.transfer(msg.sender, msg.value);
        emit FundTransfer(msg.sender, msg.value, true);
        owner.transfer(msg.value);
    }
}