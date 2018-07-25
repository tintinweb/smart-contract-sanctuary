pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract CLVRCrowdsale {

    using SafeMath for uint256;
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x93a68484936E235e167729a4a1AB6f0d1897106F;

    uint256 public price;
    uint256 public startDate;
    uint256 public endDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor() public {
        creator = msg.sender;
        startDate = 1531958400;
        endDate = 1534636799;
        price = 5000;
        tokenReward = Token(0x92f10796da1f6fab1544cF64682Cb8c15C71d5E7);
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

    function sendToken(address _to, uint256 _value) isCreator public {
        tokenReward.transfer(_to, _value);      
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

    function () public payable {
        require(msg.value > 0);
        require(now > startDate);
        require(now < endDate);
        uint256 amount = msg.value.mul(price);
        uint256 _diff;

        // period 1 : 25%
        if (now > startDate && now < startDate + 2 days) {
            _diff = amount.div(4);
            amount = amount.add(_diff);
        }
        
        // period 2 : 15%
        if (now > startDate + 2 days && now < startDate + 16 days) {
            uint256 _amount = amount.div(20);
            _diff = _amount.mul(3);
            amount = amount.add(_diff);
        }

        // period 3 : 10%
        if (now > startDate + 16 days && now < startDate + 30 days) {
            _diff = amount.div(10);
            amount = amount.add(_diff);
        }

        tokenReward.transfer(msg.sender, amount);
        emit FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}