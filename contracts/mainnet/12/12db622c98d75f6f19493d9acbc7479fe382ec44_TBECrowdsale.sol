pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract TBECrowdsale {
    
    Token public tokenReward;
    uint256 public price;
    address public creator;
    address public owner = 0x700635ad386228dEBCfBb5705d2207F529af8323;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public bonusDate;
    uint256 public tokenCap;

    mapping (address => bool) public whitelist;
    mapping (address => uint256) public whitelistedMax;
    mapping (address => bool) public categorie1;
    mapping (address => bool) public categorie2;
    mapping (address => bool) public tokenAddress;
    mapping (address => uint256) public balanceOfEther;
    mapping (address => uint256) public balanceOf;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function TBECrowdsale() public {
        creator = msg.sender;
        price = 8000;
        startDate = now;
        endDate = startDate + 30 days;
        bonusDate = startDate + 5 days;
        tokenCap = 2400000000000000000000;
        tokenReward = Token(0xf18b97b312EF48C5d2b5C21c739d499B7c65Cf96);
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
    
    function setbonusDate(uint256 _bonusDate) isCreator public {
        bonusDate = _bonusDate;      
    }
    function setPrice(uint256 _price) isCreator public {
        price = _price;      
    }
     function settokenCap(uint256 _tokenCap) isCreator public {
        tokenCap = _tokenCap;      
    }

    function addToWhitelist(address _address) isCreator public {
        whitelist[_address] = true;
    }

    function addToCategorie1(address _address) isCreator public {
        categorie1[_address] = true;
    }

    function addToCategorie2(address _address) isCreator public {
        categorie2[_address] = true;
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
        require(now > startDate);
        require(now < endDate);
        require(whitelist[msg.sender]);
        
        if (categorie1[msg.sender] == false) {
            require((whitelistedMax[msg.sender] +  msg.value) <= 5000000000000000000);
        }

        uint256 amount = msg.value * price;

        if (now > startDate && now <= bonusDate) {
            uint256 _amount = amount / 10;
            amount += _amount * 3;
        }

        balanceOfEther[msg.sender] += msg.value / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        whitelistedMax[msg.sender] = whitelistedMax[msg.sender] + msg.value;
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}