pragma solidity ^0.4.16;

interface token {
    function transfer(address to, uint256 amount) public;
}

contract CrowdSale {
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
    uint256 public tokenPrice;

    token public rewardToken;

    bool public crowdSaleClosed;
    bool public fundingGoalReached;

    mapping(address => uint256) public balanceOf;

    event GoalReached(address beneficiary, uint256 amountRaised);
    event FundTransfer(address to, uint256 amount, bool isContribution);

    function CrowdSale (
        uint256 goalAmountInEther,
        uint256 crowdSaleDurationInMinutes,
        uint256 priceOfEachRewardToken,
        address rewardTokenAddress
    ) public {
        beneficiary = msg.sender;
        fundingGoal = goalAmountInEther;
        amountRaised = 0;
        deadline = now + crowdSaleDurationInMinutes * 1 minutes;
        tokenPrice = priceOfEachRewardToken * 1 ether;
        rewardToken = token(rewardTokenAddress);
        crowdSaleClosed = false;
        fundingGoalReached = false;

    }

    function () public payable {
        require(!crowdSaleClosed);
        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;

        rewardToken.transfer(msg.sender, amount / tokenPrice);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        if (now >= deadline) {
            _;
        }
    
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }

        crowdSaleClosed = true;
    }

    function safeTransfer() public afterDeadline {
        require(crowdSaleClosed);

        if (!fundingGoalReached) {
            uint256 amount = balanceOf[msg.sender];
            if (msg.sender.send(amount)) {
                balanceOf[msg.sender] = 0;
                FundTransfer(msg.sender, amount, false);
            }
            
        } 

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (msg.sender.send(amountRaised)) {
                amountRaised = 0;
                FundTransfer(msg.sender, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }

}