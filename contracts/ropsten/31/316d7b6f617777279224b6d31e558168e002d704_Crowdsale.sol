pragma solidity ^0.4.25;

contract token {
    function transfer(address receiver, int amount) external;
}

contract Crowdsale {
    address public beneficiary;
    int public fundingGoal;
    int public amountRaised;
    uint256 public deadline;
    int public price;
    token public tokenReward;
    mapping(address => int) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    address public senderAddress;

    event GoalReached(address recipient, int totalAmountRaised);
    event FundTransfer(address backer, int amount, bool isContribution);

  
    constructor(
        address ifSuccessfulSendTo,
        int fundingGoalInEthers,
        uint256 durationInMinutes,
        int etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
  
    function () payable public {
        require(!crowdsaleClosed);
       
        int amount = int(msg.value);
        balanceOf[msg.sender] += amount;
        senderAddress = msg.sender;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
       emit FundTransfer(msg.sender, amount, true);
    
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


  
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            int amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(uint256(amount))) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(uint256(amountRaised))) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
    
}