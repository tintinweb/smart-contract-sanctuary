pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract AENCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner;
    uint256 public totalSold;

    event FundTransfer(address beneficiaire, uint amount);

    constructor() public {
        creator = msg.sender;
        tokenReward = Token(0xBd11eaE443eF0E96C1CC565Db5c0b51f6c829C0b);
    }

    function setOwner(address _owner) public {
        require(msg.sender == creator);
        owner = _owner;      
    }

    function setCreator(address _creator) public {
        require(msg.sender == creator);
        creator = _creator;      
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
        require(msg.value > 0 && msg.value < 5.1 ether);
	    uint amount = msg.value * 5000;
	    amount = amount / 20;
        
        // 8 september 2018 - 14 september 2018: 30% bonus
        if(now > 1536361200 && now < 1536966000) {
            amount = amount * 26;
        }
        
        // 15 september 2018 - 21 september 2018: 25% bonus
        if(now > 1536966000 && now < 1537570800) {
            amount = amount * 25;
        }
        
        // 22 september 2018 - 28 september 2018: 20% bonus
        if(now > 1537570800 && now < 1538175600) {
            amount = amount * 24;
        }
        
        // 29 september 2018 - 5 october 2018: 15% bonus
        if(now > 1538175600 && now < 1538780400) {
            amount = amount * 23;
        }

        // 6 october 2018 - 20 october 2018: 10% bonus
        if(now > 1538780400 && now < 1540076400) {
            amount = amount * 22;
        }

        // 21 october 2018
        if(now > 1540076400) {
            amount = amount * 20;
        }
        
        totalSold += amount / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        emit FundTransfer(msg.sender, amount);
        owner.transfer(msg.value);
    }
}