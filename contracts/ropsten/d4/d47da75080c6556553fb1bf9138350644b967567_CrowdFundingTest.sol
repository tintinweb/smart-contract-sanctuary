pragma solidity ^0.4.24;

interface token{
    function transfer(address receiver,uint amount) external;
}

contract CrowdFundingTest{
    
    address public beneficiary; //shou kuan fang
    
    uint public fundingGoal; //shou yi ren
    
    uint public amountRaised; //can yu shu liang
    
    uint public deadLine; //jie zhi shi jian
    
    uint public price; //token yu eth de hui lv, ji 1 ge token duo shao eth
    
    token public tokenReward; //yao mai de token shu liang 
    
    mapping(address => uint256) public balanceof; // yu e 
    
    bool fundingGoalReached = false; //zhong chou shi fou da biao
    
    bool crowsaleClosed = false; //zhong chou shi fou  jie shu 
    
    //shi jian gen zong
    event GoalReached(address recipient,uint totalAmountReached);
    
    event FundTransfer(address backer,uint amount,bool isContribution);
    
    //gou zhao han shu ,she zhi xiang guan shu xing 
    
    constructor(
            address ifSuccessfulSendTo,
            uint fundingGoalInEthers,
            uint durationInMinutes,
            uint finneyCostOfEachToken,
            address addressOfTokenUsedAsReward)
            public  {
                beneficiary = ifSuccessfulSendTo;
                fundingGoal = fundingGoalInEthers * 1 ether;
                deadLine = now + durationInMinutes * 1 minutes;
                price = finneyCostOfEachToken * 1 finney;
                tokenReward = token(addressOfTokenUsedAsReward);   // 传入已发布的 token 合约的地址来创建实例
    }
    
    
    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    function () public payable{
        require(!crowsaleClosed);
        uint amount = msg.value;
        balanceof[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender,amount/price);
    }
        
        /**
        *  定义函数修改器modifier（作用和Python的装饰器很相似）
        * 用于在函数执行前检查某种前置条件（判断通过之后才会继续执行该方法）
        * _ 表示继续执行之后的代码
        **/
        modifier afterDeadLine() { if (now >= deadLine) _; }
        
         /**
         * 判断众筹是否完成融资目标， 这个方法使用了afterDeadline函数修改器
         */
        function checkGoalReached() public afterDeadLine {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                emit GoalReached(beneficiary, amountRaised);
            }
            crowsaleClosed = true;
        }
        
    /**
     * 完成融资目标时，融资款发送到收款方
     * 未完成融资目标时，执行退款
     *
     */
    function safeWithdrawal() public afterDeadLine {
        if (!fundingGoalReached) {
            uint amount = balanceof[msg.sender];
            balanceof[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceof[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
        
}