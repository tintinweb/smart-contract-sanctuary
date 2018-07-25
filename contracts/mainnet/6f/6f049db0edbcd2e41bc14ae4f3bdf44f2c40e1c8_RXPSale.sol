pragma solidity ^0.4.16;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract RXPSale {

    Token public tokenReward;
    address public creator;
    address public owner = 0xec1f70fBfC7ae52fe6Bcb66D3e227e516743F0a6;

    uint256 public startDate;
    uint256 public endDate;
    uint256 public price;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function RXPSale() public {
        creator = msg.sender;
        startDate = 1532131200;
        price = 11250;
        tokenReward = Token(0xc35924a3661BbADaBbba4f1823fa74FcafCb08Ef);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;
    }

    function setStartDate(uint256 _startDate) isCreator public {
        startDate = _startDate;
    }

    function setEndtDate(uint256 _endDate) isCreator public {
        endDate = _endDate;
    }

    function setPrice(uint256 _price) isCreator public {
        price = _price;
    }

    function setToken(address _token) isCreator public {
        tokenReward = Token(_token);
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

    function () payable public {
        require(msg.value > 1 ether);
        require(now > startDate);
	    uint amount = msg.value * price;
	    amount += amount / 4;
        tokenReward.transferFrom(owner, msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}