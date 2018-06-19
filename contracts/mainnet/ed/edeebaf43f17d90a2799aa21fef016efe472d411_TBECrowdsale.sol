pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract TBECrowdsale {
    
    Token public tokenReward;
    uint256 public price;
    address public creator;
    address public owner = 0x0;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public bonusDate;
    uint256 public tokenCap;

    mapping (address => bool) public whitelist;
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
        tokenReward = Token(0x647972c6A5bD977Db85dC364d18cC05D3Db70378);
        
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
            // require(tokenAddress.balanceOf[msg.sender] <= tokenCap);
        }

        uint256 amount = msg.value * price;

        if (now > startDate && now <= bonusDate) {
            uint256 _amount = amount / 10;
            amount += _amount * 3;
        }

        balanceOfEther[msg.sender] += msg.value / 1 ether;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}