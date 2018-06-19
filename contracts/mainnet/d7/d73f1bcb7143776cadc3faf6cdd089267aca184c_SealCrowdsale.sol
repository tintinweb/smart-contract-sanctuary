pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract SealCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0xD2d67e716D09dCB27F85F0ffa6661E1cd569eC7F;

    uint256 private price;
    uint256 private tokenSold;        

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function SealCrowdsale() public {
        creator = msg.sender;
        price = 10000;
        tokenReward = Token(0xc2B9E65174264159677520d951E543f9235af946);
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
        require(now > 1517443200);
        uint256 amount;
        uint256 _amount;

        // pre-ico
        if (now > 1522796400 && now < 1525302000 && tokenSold < 328836958) {
            amount = msg.value * price;
            if (msg.value >= 1 ether && msg.value < 60 ether ) {
                amount += amount / 10;
            }
            if (msg.value >= 60 ether && msg.value < 300 ether ) {
                _amount = amount / 20;
                amount += _amount * 3;
            }
            if (msg.value == 300 ether ) {
                amount += amount / 5;
            }
            if (msg.value > 300 ether ) {
                _amount = amount / 30;
                amount += _amount * 3;
            }
        }

        // ico
        if (now > 1526428800 && now < 1527811200 && tokenSold < 436836958) {
            amount = msg.value * price;
        }

        // company reserve
        if (now > 1527811200 && tokenSold > 436836957 && tokenSold < 1144836958) {
            amount = msg.value * price;
        }

        tokenSold += amount / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}