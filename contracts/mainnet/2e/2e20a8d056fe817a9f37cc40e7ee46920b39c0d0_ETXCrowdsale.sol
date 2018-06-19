pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract ETXCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0xC745dA5e0CC68E6Ba91429Ec0F467939f4005Db6;

    uint256 private tokenSold;
    uint256 private price_1;
    uint256 private price_2;
    uint256 private price_3;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function ETXCrowdsale() public {
        creator = msg.sender;
        price_1 = 600;
        price_2 = 500;
        price_3 = 400;
        tokenReward = Token(0x4CFB59BDfB47396e1720F7fF1C1e37071d927112);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;      
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;      
    }

    function setPrice1(uint256 _price_1) isCreator public {
        price_3 = _price_1;      
    }

    function setPrice2(uint256 _price_2) isCreator public {
        price_3 = _price_2;      
    }

    function setPrice3(uint256 _price_3) isCreator public {
        price_3 = _price_3;      
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
        
        // period 1
        if (now > 1519862400 && now < 1522018800 && tokenSold < 2100001) {
            amount = msg.value * price_1;
        }

        // period 2
        if (now > 1522537200 && now < 1524697200 && tokenSold < 6300001) {
            amount = msg.value * price_2;
        }

        // period 3
        if (now > 1525129200 && now < 1527721200 && tokenSold < 12600001) {
            amount = msg.value * price_3;
        }

        tokenSold += amount / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}