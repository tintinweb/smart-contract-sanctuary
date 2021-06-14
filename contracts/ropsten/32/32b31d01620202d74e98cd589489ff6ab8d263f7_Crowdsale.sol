/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary;  // 募资成功后的收款方
    uint public fundingGoal;   // 募资额度
    uint public amountRaised;   // 参与数量
    uint public deadline;      // 募资截止期
    
    uint public price;    //  token 与以太坊的汇率 , token卖多少钱
    token public tokenReward;   // 要卖的token

    mapping(address => uint256) public balanceOf;

    bool fundingGoalReached = false;  // 众筹是否达到目标
    bool crowdsaleClosed = false;   //  众筹是否结束

    /** 事件可以用来跟踪信息*/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /* 构造函数, 设置相关属性*/
    constructor() public {
            beneficiary = 0x8d4891715A01D8ed72b7eB6a456933da11f87E66;
            //具体设置募集资金的收款地址
            fundingGoal = 0.2 ether;
            //具体设置募集资金的总额0.2个ETH
            deadline = now + 10 minutes;
            //具体设置募集资金的时间限制为10min
            price = 1 wei;
            //具体设置SMH和ETH的汇率，1SMH=1wei
            tokenReward = token(0x4cbfF11213CA3C025c9930F87Bf8C6212E6fEFE3);   
            // 传入已发布的 token 合约的地址来创建实例
    }

    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    function () public payable {
        require(!crowdsaleClosed);  //判断众筹是否结束
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;//投资者汇入众筹合约的金额
        amountRaised += amount;//累计筹集的以太币数量
        tokenReward.transfer(msg.sender, amount / price);//回退给投资者对应的SMH币
        emit FundTransfer(msg.sender, amount, true);//触发事件-参与众筹
    }

    /**
    *  定义函数修改器modifier
    * 用于在函数执行前检查某种前置条件（判断通过之后才会继续执行该方法）
    * _ 表示继续执行之后的代码
    **/
    modifier afterDeadline() { if (now >= deadline) _; }

    /*判断众筹是否完成融资目标， 这个方法使用了afterDeadline函数修改器*/
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    /**
     * 完成融资目标时，融资款发送到收款方
     * 未完成融资目标时，执行退款
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
    //如果达到众筹目标，且调用合约者为受益人，则将众筹的以太坊发送给设定的受益人
        if (fundingGoalReached && beneficiary == msg.sender) {
            if(beneficiary.send(amountRaised)){
                emit FundTransfer(beneficiary, amountRaised, false);
        } else {
                //如果我们不能将资金发送给受益人，解锁出资人余额
                fundingGoalReached = false;
            }
        }
    }
}