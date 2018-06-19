pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract CPCCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x1Fa6E50fA413b20F43270bE69895c4C250244162;

    uint256 private tokenSold;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function CPCCrowdsale() public {
        creator = msg.sender;
        tokenReward = Token(0x30281939B520a15CdadB509c94e491404af87385);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;      
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;      
    }

    function setToken(address _token) isCreator public {
        tokenReward = Token(_token);      
    }

    function sendToken(address _to, uint256 _value) isCreator public {
        tokenReward.transfer(_to, _value);      
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

    function () payable public {
        require(msg.value > 0);
        uint256 amount;
        
        // pre ico
        if (now > 1523311200 && now < 1525125600) {
            amount = msg.value * 11000;
            amount += amount / 5;
        }
        
        // stage 1
        if (now > 1525125599 && now < 1527717600) {
            amount = msg.value * 7000;
            amount += amount / 5;
        }

        // stage 2
        if (now > 1527717599 && now < 1530482400) {
            amount = msg.value * 5800;
            amount += amount / 5;
        }

        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}