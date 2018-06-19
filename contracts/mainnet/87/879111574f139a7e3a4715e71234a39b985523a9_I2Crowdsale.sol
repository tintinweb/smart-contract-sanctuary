pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract I2Crowdsale is Ownable {
    using SafeMath for uint256;

    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public usd = 550;
    uint public tokensPerDollar = 10; // $0.1 = 10
    uint public bonus = 30;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function I2Crowdsale (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        // how many token units a buyer gets per dollar
        // how many token units a buyer gets per wei
        // uint etherCostOfEachToken,
        // uint bonusInPercent,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        // mean set 100-1000 ETH
        fundingGoal = fundingGoalInEthers.mul(1 ether); 
        deadline = now.add(durationInMinutes.mul(1 minutes));
        price = 10**18 / tokensPerDollar / usd; 
        // price = etherCostOfEachToken * 1 ether;
        // price = etherCostOfEachToken.mul(1 ether).div(1000).mul(usd);
        // bonus = bonusInPercent;

        tokenReward = token(addressOfTokenUsedAsReward);
    }

    /**
    * Change Crowdsale bonus rate
    */
    function changeBonus (uint _bonus) public onlyOwner {
        bonus = _bonus;
    }
    
    /**
    * Set USD/ETH rate in USD (1000)
    */
    function setUSDPrice (uint _usd) public onlyOwner {
        usd = _usd;
        price = 10**18 / tokensPerDollar / usd; 
    }
    
    /**
    * Finish Crowdsale in some reason like Goals Reached or etc
    */
    function finishCrowdsale () public onlyOwner {
        deadline = now;
        crowdsaleClosed = true;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable {
        require(beneficiary != address(0));
        require(!crowdsaleClosed);
        require(msg.value != 0);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        // bonus in percent 
        // msg.value.add(msg.value.mul(bonus).div(100));
        uint tokensToSend = amount.div(price).mul(10**18);
        uint tokenToSendWithBonus = tokensToSend.add(tokensToSend.mul(bonus).div(100));
        tokenReward.transfer(msg.sender, tokenToSendWithBonus);
        FundTransfer(msg.sender, amount, true);
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
            GoalReached(beneficiary, amountRaised);
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
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
}