pragma solidity ^0.4.24;

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
        price = 100;
        startDate = now;
        endDate = startDate + 3 days;
        tokenReward = Token(0xf18b97b312EF48C5d2b5C21c739d499B7c65Cf96);
    }



    function setOwner(address _owner) isCreator public {
        owner = _owner;      
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

    
    function () payable public {
        require(now > startDate);
        require(now < endDate);
        
        
        uint256 amount = price;

       
        balanceOfEther[msg.sender] += msg.value / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}