pragma solidity ^0.4.11;

interface token 
{
    function transfer(address _to, uint256 _value);
    function transferFrom(address _from, address _to, uint256 _value);
    function approve(address _spender, uint256 _value);
    function allowance(address _owner, address _spender) constant returns(uint256 remaining);
    function getBalanceOf(address _who) returns(uint256 amount);
}

contract DCY_preICO 
{
    string public name = &#39;CONTRACT DICEYBIT.COM preICO&#39;;
    address public beneficiary;

    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;

    token public tokenReward;
    uint256 public tokensLeft;

    mapping(address => uint256) public balanceOf;

    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address benef, uint amount);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /*  at initialization, setup the owner */
    function DCY_preICO(
        address beneficiaryAddress,
        token addressOfTokenUsedAsReward,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint weiPrice
    ) {

        beneficiary = beneficiaryAddress;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiPrice;

        tokenReward = token(addressOfTokenUsedAsReward);
    }

    function () payable 
    {
        require(!crowdsaleClosed);
        require(tokensLeft >= amount / price);

        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;

        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);

        tokensLeft = tokenReward.getBalanceOf(address(this));
        if (tokensLeft == 0) 
        {
            crowdsaleClosed = true;
        }
    }

    function updateTokensAvailable() 
    {
        tokensLeft = tokenReward.getBalanceOf(address(this));
    }

    modifier afterDeadline() 
    {
        if (now >= deadline) _;
    }

    /* checks if the goal or time limit has been reached and ends the campaign */
    function checkGoalReached() afterDeadline 
    {        
        if (amountRaised >= fundingGoal) 
        {
            fundingGoalReached = true;
            crowdsaleClosed = true;
            GoalReached(beneficiary, amountRaised);
        }
    }

    function safeWithdrawal() afterDeadline 
    {
        
        if (!fundingGoalReached) 
        {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) 
            {
                if (msg.sender.send(amount)) 
                {
                    FundTransfer(msg.sender, amount, false);
                } 
                else 
                {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) 
        {
            if (beneficiary.send(amountRaised)) 
            {
                FundTransfer(beneficiary, amountRaised, false);
            } 
            else 
            {
                fundingGoalReached = false;
            }
        }
    }

    function bringBackTokens() afterDeadline 
    {
        require(tokensLeft > 0);

        if (msg.sender == beneficiary) 
        {
            tokenReward.transfer(beneficiary, tokensLeft);
            tokensLeft = tokenReward.getBalanceOf(address(this));
        }
    }
}