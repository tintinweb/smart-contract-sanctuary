pragma solidity ^0.4.11;

contract token {
    function transfer(address receiver, uint amount);
    function balanceOf( address _address )returns(uint256);
}

contract DragonCrowdsale {
    address public beneficiary;
    address public owner;
  
    uint public amountRaised;
    uint public tokensSold;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public contributions;
    bool crowdSaleStart;
    bool crowdSalePause;
    bool crowdSaleClosed;

   
    event FundTransfer(address participant, uint amount);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    function DragonCrowdsale() {
        beneficiary = msg.sender;
        owner = msg.sender;
        price =  .003333333333333 ether;
        tokenReward = token(0x5b29a6277c996b477d6632E60EEf41268311cE1c);
    }

    function () payable {
        require(!crowdSaleClosed);
        require(!crowdSalePause);
        if ( crowdSaleStart) require( now < deadline );
        uint amount = msg.value;
        contributions[msg.sender] += amount;
        amountRaised += amount;
        tokensSold += amount / price;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount );
        beneficiary.transfer( amount );
    }

    // Start this October 27
    function startCrowdsale() onlyOwner  {
        
        crowdSaleStart = true;
        deadline = now + 60 days;
    }

    function endCrowdsale() onlyOwner  {
        
        
        crowdSaleClosed = true;
    }


    function pauseCrowdsale() onlyOwner {
        
        crowdSalePause = true;
        
        
    }

    function unpauseCrowdsale() onlyOwner {
        
        crowdSalePause = false;
        
        
    }
    
    function transferOwnership ( address _newowner ) onlyOwner {
        
        owner = _newowner;
        
    }
    
    function transferBeneficiary ( address _newbeneficiary ) onlyOwner {
        
        beneficiary = _newbeneficiary;
        
    }
    
    function withdrawDragons() onlyOwner{
        
        uint256 balance = tokenReward.balanceOf(address(this));
        
        tokenReward.transfer( beneficiary, balance );
        
        
    }
    
}