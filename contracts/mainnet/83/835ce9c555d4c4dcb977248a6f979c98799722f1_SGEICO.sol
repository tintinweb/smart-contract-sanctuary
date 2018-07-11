pragma solidity ^0.4.16;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract SGEICO {

    Token public tokenReward;
    address public creator;
    address public owner = 0x8dfFcCE1d47C6325340712AB1B8fD7328075730C;

    uint256 public price;
    uint256 public startDate;
    uint256 public endDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function SGEICO() public {
        creator = msg.sender;
        startDate = 1531612800;
        endDate = 1544832000;
        price = 1100;
        tokenReward = Token(0x40489719e489782959486a04b765e1e93e5b221a);
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
        require(now < endDate);
	    uint amount = msg.value * price;
        amount += amount / 4;
        tokenReward.transferFrom(owner, msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}