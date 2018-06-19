pragma solidity ^0.4.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract ScicoinsICO {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0xA32289544B9B8de7fB8Dfc83FBCB537745b71Be3;

    uint256 public price;
    uint256 public startDate;
    uint256 public endDate;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function ScicoinsICO() public {
        creator = msg.sender;
        startDate = 1521068400;     // 15/03/2018
        endDate = 1526335200;       // 15/05/2018
        price = 1000;
        tokenReward = Token(0x57E84E2c6dFD300F798794F8B330a2A519114B3d);
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
    
    function setPrice(uint256 _price) public {
        require(msg.sender == creator);
        price = _price;      
    }

    function setToken(address _token) public {
        require(msg.sender == creator);
        tokenReward = Token(_token);      
    }
    
    function kill() public {
        require(msg.sender == creator);
        selfdestruct(owner);
    }

    function () payable public {
        require(msg.value > 0);
        require(now > startDate);
        require(now < endDate);
	    uint amount = msg.value * price;
        tokenReward.transferFrom(owner, msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}