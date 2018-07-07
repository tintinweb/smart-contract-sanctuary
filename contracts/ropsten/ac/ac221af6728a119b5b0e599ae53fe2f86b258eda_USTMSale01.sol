pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract USTMSale01 {
    address public _beneficiary;
   
    uint public _deadline;
    uint public _price;
    token public _tokenReward;
    mapping(address => uint256) public balanceOf;
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool public _saleclosed = true;

    bool public _beneficiaryWithdraw = false;
    uint public _minimum;
    uint public _maximum;
    uint public _tokenbalance;
    uint public _etherbalance;
    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Constructor(
       
        
    ) public {
       
        
    }
    
    function StartSale( address beneficiary,
        uint durationInDays,
        uint tokenPriceMillionth,
        address addressOfTokenUsedAsReward,
        uint minimumMillionth,
        uint maximumMillionth,
        uint totalInt) public
    {
        require (_saleclosed);
        require(_beneficiaryWithdraw);
        
        uint millionth = 1000000000000;
        _beneficiary = beneficiary;
        _deadline = now + durationInDays * 1 days;
        _price = tokenPriceMillionth * millionth;
        _tokenReward = token(addressOfTokenUsedAsReward);
        _minimum = minimumMillionth * millionth;
        _maximum = maximumMillionth * millionth;
        _tokenbalance = totalInt * 1 ether;
        _etherbalance = 0;
        _saleclosed= false;
        _beneficiaryWithdraw = false;
    }
    
    function StopSale() public
    {
        _saleclosed = true;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        
        if (msg.sender == _beneficiary)
            return;
        
        require(!_saleclosed);
        
        uint amount = msg.value;
        if (amount < _minimum || amount > _maximum)
            require(false);
            
        uint tosend = amount / _price * 1 ether;
        if (tosend > _tokenbalance)
            require(false);
            
        
       _tokenReward.transfer(msg.sender, tosend);
       emit FundTransfer(msg.sender, amount, true);
       _tokenbalance-=tosend;
       _etherbalance+=amount;
    }

    modifier afterDeadline() { if (now >= _deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        _saleclosed = true;
    }
    
    

    function safeWithdrawal() public afterDeadline {
        require(msg.sender == _beneficiary);
        
   
            uint amount = _tokenbalance;
            
            if (amount > 0) 
            {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                   _tokenbalance = 0;
                } else {
                    
                }
            }
        

       if (_etherbalance > 0)
       {
            if (_beneficiary.send(_etherbalance)) 
            {
               emit FundTransfer(_beneficiary, _etherbalance, false);
               _etherbalance = 0;
            } 
            else 
            {
            }
       }
        
    }




    
    
}