pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal pure returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal pure returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal pure returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

interface token {
    function transfer(address receiver, uint amount) external;
    function decimals() external constant returns (uint8);
    function balanceOf(address who) constant external returns (uint256);
}

contract Crowdsale {
    using SafeMath for uint256;
    
    address public owner;
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public maxFunding;
    uint256 public amountRaised;
    uint256 public deadline;
    uint256 public rate;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    bool tokenDispatched = false;
    
    //record all the contributors&#39; address
    address [] public contributors;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event ReturnRemainRewardToken(address owner, uint256 amount);
    event ReturnFunding(address owner, uint256 amount);
    event DispatchRewardTokenSuccess();

    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        uint256 _maxFunding,
        uint256 durationInMinutes,
        uint256 _rate,
        address addressOfTokenUsedAsReward
    ) public {
        owner = msg.sender;
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        maxFunding  = _maxFunding * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        rate = _rate;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!crowdsaleClosed);
        require(amountRaised < maxFunding);
        require(amountRaised.add(msg.value) <= maxFunding);

        uint256 amount = uint256(msg.value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        contributors.push(msg.sender);
        emit FundTransfer(msg.sender, amount, true);     
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() public afterDeadline {
        //众筹失败，众筹者可以自己领取自己的众筹资金
        if (!fundingGoalReached) {
            uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        //众筹成功，资金划给受益人
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
    
    //返还剩余的token给项目方
    function returnRemainRewardToken() public afterDeadline{
        if( msg.sender == owner )
        {
            uint256 amountRemain = tokenReward.balanceOf(this);
            tokenReward.transfer(msg.sender, amountRemain);
            emit ReturnRemainRewardToken(msg.sender, amountRemain);           
        }
    }
    
    //如果众筹失败就返还资金
    function returnFunding() public afterDeadline{
        if( msg.sender == owner && !fundingGoalReached)
        {
            uint total = contributors.length;
            for (uint i=0; i<total; i++)
            {
                address contributor = contributors[i];                
                uint256 amount = balanceOf[contributor];
                balanceOf[contributor] = 0;
                if (amount > 0) {
                    if (contributor.send(amount)) {
                    emit ReturnFunding(contributor, amount);
                    } else {
                        balanceOf[contributor] = amount;
                    }
                }   
            }         
        }
    }
    
    //众筹成功就分发token给众筹者
    function dispatchRewardToken() public afterDeadline{
        if (fundingGoalReached && msg.sender == owner && !tokenDispatched)
        {  
            uint total = contributors.length;
            for (uint i=0; i<total; i++)
            {
                address contributor = contributors[i];
                uint256 amountETH   = balanceOf[contributor];
                uint256 amountTokenReward = amountETH.mul(rate).div(10 ** 18);
                uint256 rewardTokenDecimals = uint256(tokenReward.decimals());
                amountTokenReward = amountTokenReward.mul(10 ** rewardTokenDecimals);
                tokenReward.transfer(contributor, amountTokenReward);   
            }
            tokenDispatched = true;
            emit DispatchRewardTokenSuccess();
        }
    }
}