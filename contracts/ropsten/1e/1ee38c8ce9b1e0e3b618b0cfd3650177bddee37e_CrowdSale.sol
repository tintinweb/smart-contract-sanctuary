pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract CrowdSale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    uint public amount_;
    uint public tokenCnt;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * 소유자 설정
     */
    constructor (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 finney;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    
    /**
     * Fallback function
     *
     * 이름이 없는 기능은 계약에 자금을 보낼 때마다 호출되는 기본 기능입니다.
     */
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        amount_ = amount;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, (amount / price) * 1 ether);
        tokenCnt = amount / price;
       emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * 목표 또는 시간 제한에 도달했는지 확인하고 캠페인을 종료합니다.
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
     * 목표 또는 시간 제한에 도달했는지, 도달했는지, 그리고 자금조달 목표에 도달했는지 확인한다.
     * 전체 금액을 수령인에게 보냅니다. 목표에 도달하지 못한 경우, 각 기여자는 철회할 수 있다.
     * 그들이 기부한 금액.
     */
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //우리가 수혜자에게 자금을 보내지 못하면, 자금 조달자의 잔액을 풀어준다.
                fundingGoalReached = false;
            }
        }
    }
}