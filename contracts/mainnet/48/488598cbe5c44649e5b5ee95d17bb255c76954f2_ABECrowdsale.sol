pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract ABECrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0xdc8a235Ca0D64b172a8fF89760a15A3021371c63;

    uint256 public startDate;
    uint256 public endDate;

    event FundTransfer(address backer, uint amount);

    constructor() public {
        creator = msg.sender;
        startDate = 1536447600;
        endDate = 1541894400;
        tokenReward = Token(0x64C8dD01056Ab8C1C8e1B704eCa60D9aA34cFb54);
    }

    function setOwner(address _owner) public {
        require(msg.sender == creator);
        owner = _owner;      
    }

    function setCreator(address _creator) public {
        require(msg.sender == creator);
        creator = _creator;      
    }

    function setStartDate(uint256 _startDate) public {
        require(msg.sender == creator);
        startDate = _startDate;      
    }

    function setEndtDate(uint256 _endDate) public {
        require(msg.sender == creator);
        endDate = _endDate;      
    }

    function setToken(address _token) public {
        require(msg.sender == creator);
        tokenReward = Token(_token);      
    }
    
    function sendToken(address _to, uint256 _value) public {
        require(msg.sender == creator);
        tokenReward.transfer(_to, _value);      
    }
    
    function kill() public {
        require(msg.sender == creator);
        selfdestruct(owner);
    }

    function () payable public {
        require(msg.value > 0);
        require(now > startDate);
        require(now < endDate);
	    uint amount;
        
        // Pre-Sale
        if(now > 1533682800 && now < 1535497200) {
            amount = msg.value * 10000;
        }
        
        // Round 1
        if(now > 1536447600 && now < 1538262000) {
            amount = msg.value * 8333;
        }
        
        // Round 2
        if(now > 1538262000 && now < 1540076400) {
            amount = msg.value * 7142;
        }
        
        // Round 3
        if(now > 1540076400 && now < 1541894400) {
            amount = msg.value * 6249;
        }

        tokenReward.transfer(msg.sender, amount);
        emit FundTransfer(msg.sender, amount);
        owner.transfer(msg.value);
    }
}