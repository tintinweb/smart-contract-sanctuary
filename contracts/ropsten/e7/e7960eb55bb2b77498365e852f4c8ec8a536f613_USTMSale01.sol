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

    uint public _minimum;
    uint public _maximum;
    uint public _balance;
    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Constructor(
       
        
    ) public {
       
        
    }
    
    function StartSale( address beneficiary,
        uint durationInMinutes,
        uint tokenPriceMillionth,
        address addressOfTokenUsedAsReward,
        uint minimum,
        uint maximum,
        uint total) public
    {
        _beneficiary = beneficiary;
        _deadline = now + durationInMinutes * 1 minutes;
        _price = tokenPriceMillionth * 1000000000000;
        _tokenReward = token(addressOfTokenUsedAsReward);
        _minimum = minimum * 1000000000000000000;
        _maximum = maximum * 1000000000000000000;
        _balance = total * 1000000000000000000;
        _saleclosed= false;
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
        uint tosend = amount / _price;
        if (tosend > _balance)
            require(false);
            
            _balance-=tosend;
    _tokenReward.transfer(msg.sender, tosend);
       emit FundTransfer(msg.sender, amount, true);
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


    
    
}