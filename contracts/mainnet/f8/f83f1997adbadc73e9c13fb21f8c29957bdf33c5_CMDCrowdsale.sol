pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract CMDCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x16F4b9b85Ed28F11D0b7b52B7ad48eFe217E0D48;

    uint256 private tokenSold;
    uint256 public price;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function CMDCrowdsale() public {
        creator = msg.sender;
        tokenReward = Token(0xf04eAba18e56ECA6be0f29f09082f62D3865782a);
        price = 2000;
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
        uint256 amount;
        uint256 bonus;
        
        // Private Sale
        if (now > 1522018800 && now < 1523228400 && tokenSold < 42000001) {
            amount = msg.value * price;
            amount += amount / 3;
        }

        // Pre-Sale
        if (now > 1523228399 && now < 1525388400 && tokenSold > 42000000 && tokenSold < 84000001) {
            amount = msg.value * price;
            amount += amount / 5;
        }

        // Public ICO
        if (now > 1525388399 && now < 1530399600 && tokenSold > 84000001 && tokenSold < 140000001) {
            amount = msg.value * price;
            bonus = amount / 100;

            if (now < 1525388399 + 1 days) {
                amount += bonus * 15;
            }

            if (now > 1525388399 + 1 days && now < 1525388399 + 2 days) {
                amount += bonus * 14;
            }

            if (now > 1525388399 + 2 days && now < 1525388399 + 3 days) {
                amount += bonus * 13;
            }

            if (now > 1525388399 + 3 days && now < 1525388399 + 4 days) {
                amount += bonus * 12;
            }

            if (now > 1525388399 + 4 days && now < 1525388399 + 5 days) {
                amount += bonus * 11;
            }

            if (now > 1525388399 + 5 days && now < 1525388399 + 6 days) {
                amount += bonus * 10;
            }

            if (now > 1525388399 + 6 days && now < 1525388399 + 7 days) {
                amount += bonus * 9;
            }

            if (now > 1525388399 + 7 days && now < 1525388399 + 8 days) {
                amount += bonus * 8;
            }

            if (now > 1525388399 + 8 days && now < 1525388399 + 9 days) {
                amount += bonus * 7;
            }

            if (now > 1525388399 + 9 days && now < 1525388399 + 10 days) {
                amount += bonus * 6;
            }

            if (now > 1525388399 + 10 days && now < 1525388399 + 11 days) {
                amount += bonus * 5;
            }

            if (now > 1525388399 + 11 days && now < 1525388399 + 12 days) {
                amount += bonus * 4;
            }

            if (now > 1525388399 + 12 days && now < 1525388399 + 13 days) {
                amount += bonus * 3;
            }

            if (now > 1525388399 + 14 days && now < 1525388399 + 15 days) {
                amount += bonus * 2;
            }

            if (now > 1525388399 + 15 days && now < 1525388399 + 16 days) {
                amount += bonus;
            }
        }

        tokenSold += amount / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}