pragma solidity ^0.4.24;

/**
* interface 的概念和其他编程语言当中类似，在这里相当于我们可以通过传参引用之前发布的 token 合约
* 我们只需要使用其中的转账 transfer 方法，所以就只声明 transfer
**/
interface token {
    function transfer(address receiver, uint amount);
}

contract GACTCrowdSale {
    // 这里是发布合约时需要传入的参数
    address public beneficiary; // ICO 募资成功后的收款方
    uint public fundingGoal; // 骗多少钱
    uint public amountRaised; // 割到多少韭菜
    uint public deadline; // 割到啥时候
    /**
    * 卖多贵，即你的 token 与以太坊的汇率，你可以自己设定
    * 注意到，ICO 当中 token 的价格是由合约发布方自行设定而不是市场决定的
    * 也就是说你项目值多少钱你可以自己编
    **/
    uint public price;
    token public tokenReward; // 你要卖的 token
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false; // 是否达标
    bool crowdsaleClosed = false; // 售卖是否结束
    /**
    * 事件可以用来记录信息，每次调用事件方法时都能将相关信息存入区块链中
    * 可以用作凭证，也可以在你的 Dapp 中查询使用这些数据
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward); // 传入已发布的 token 合约的地址来创建实例
    }

    /**
     * Fallback function
     *
     * payable 用来指明向合约付款时调用的方法
     */
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        beneficiary.send(amountRaised);
        amountRaised = 0;
        FundTransfer(msg.sender, amount, true);
    }
    /**
    * modifier 可以理解为其他语言中的装饰器或中间件
    * 当通过其中定义的一些逻辑判断通过之后才会继续执行该方法
    * _ 表示继续执行之后的代码
    **/
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterDeadline {
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
    function safeWithdrawal() afterDeadline {
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