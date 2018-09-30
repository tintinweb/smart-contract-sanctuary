pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    //管理者
    address public admin;
    //受益人
    address public beneficiary;
    //募资额度
    uint public fundingGoal;
    //当前已募集
    uint public amountRaised;   
    //单人募集金额
    mapping(address => uint) public balanceOf;
    //截止时间
    uint public deadline;
    //众筹是否达到目标
    bool public fundingGoalReached = false;
    //众筹是否结束
    bool public crowdsaleClosed = false;
    //token 与以太坊的汇率 , token卖多少钱
    uint public price;
    //要卖的token
    token public tokenReward;


    function Crowdsale(
        address ifSuccessfulSendTo,
        uint durationInMinutes,
        uint weiCostOfEachToken,
        address addressOfTokenUsedAsReward) {
        admin = msg.sender;
        beneficiary = ifSuccessfulSendTo;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken * 1 wei;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    modifier afterDeadline() { if (now >= deadline) _; }
   

    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, 10000 * (amount / price));
    }

    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() afterDeadline  {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);           
            }
        }
        if (fundingGoalReached && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
        }
    }
}