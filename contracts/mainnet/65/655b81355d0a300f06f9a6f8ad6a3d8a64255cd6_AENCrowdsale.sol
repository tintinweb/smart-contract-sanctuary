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
        owner = 0xF82C31E4df853ff36F2Fc6F61F93B4CAda46E306;
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
        
        // 28 september 2018 - 4 October 2018: 30% bonus
        if(now > 1538089200 && now < 1538694000) {
            amount = amount * 26;
        }
        
        // 5 October 2018 - 11 October 2018: 25% bonus
        if(now > 1538694000 && now < 1539298800) {
            amount = amount * 25;
        }
        
        // 12 October 2018 - 18 October 2018: 20% bonus
        if(now > 1539298800 && now < 1539903600) {
            amount = amount * 24;
        }
        
        // 19 October 2018 - 25 October 2018: 15% bonus
        if(now > 1539903600 && now < 1540508400) {
            amount = amount * 23;
        }

        // 26 October 2018 - 09 November 2018: 10% bonus
        if(now > 1540508400 && now < 1541808000) {
            amount = amount * 22;
        }

        // 09 November 2018
        if(now > 1541808000) {
            amount = amount * 20;
        }
        
        totalSold += amount / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        emit FundTransfer(msg.sender, amount);
        owner.transfer(msg.value);
    }
}