pragma solidity ^0.4.16;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract RgiftTokenSale {

    Token public tokenReward;
    address public creator;
    address public owner = 0x829130A7Af5A4654aF6d7bC06125a1Bcf32cd8cA;

    uint256 public price;
    uint256 public startDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function RgiftTokenSale() public {
        creator = msg.sender;
        startDate = 1527022077;
        price = 140000;
        tokenReward = Token(0x2b93194d0984201aB0220A3eC6B80D9a0BD49ed7);
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
        require(msg.value == (1 ether / 2) || msg.value == 1 ether  || msg.value == (1 ether + (1 ether / 2)) || msg.value == 2 ether || msg.value >= 3 ether);
        require(now > startDate);
        uint amount = 0;
        if (msg.value < 1 ether){ 
            amount = msg.value * price;
        } else if (msg.value >= 1 ether && msg.value < 2 ether){
            amount = msg.value * price;
            uint _amount = amount / 10;
            amount += _amount * 3;
        } else if (msg.value >= 2 ether && msg.value < 3 ether){
            amount = msg.value * price;
             _amount = amount / 5;
            amount += _amount * 2;
        } else if (msg.value >= 3 ether){
            amount = msg.value * price;
             _amount = amount / 5;
            amount += _amount * 3;
        }
        

        tokenReward.transferFrom(owner, msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}