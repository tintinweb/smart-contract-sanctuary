pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract CFNDCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x56D215183E48881f10D1FaEb9325cf02171B16B7;

    uint256 private price;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function CFNDCrowdsale() public {
        creator = msg.sender;
        price = 400;
        tokenReward = Token(0x2a7d19F2bfd99F46322B03C2d3FdC7B7756cAe1a);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;      
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;      
    }

    function setPrice(uint256 _price) isCreator public {
        price = _price;      
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
        require(now > 1527238800);
        uint256 amount = msg.value * price;
        uint256 _amount = amount / 100;

        
        // stage 1
        if (now > 1527238800 && now < 1527670800) {
            amount += _amount * 15;
        }

        // stage 2
        if (now > 1527843600 && now < 1528189200) {
            amount += _amount * 10;
        }

        // stage 3
        if (now > 1528275600 && now < 1528621200) {
            amount += _amount * 5;
        }

        // stage 4
        if (now > 1528707600 && now < 1529053200) {
            amount += _amount * 2;
        }

        // stage 5
        require(now < 1531123200);

        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}