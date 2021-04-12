/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^0.4.16;
 
interface token {
    function transfer(address receiver, uint amount);
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
 
    /**
    * 事件可以用来跟踪信息
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
 
    /**
     * 构造函数, 设置相关属性
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint finneyCostOfEachToken,
        address addressOfTokenUsedAsReward) {
            beneficiary = ifSuccessfulSendTo;
            fundingGoal = fundingGoalInEthers * 1 ether;
            deadline = now + durationInMinutes * 1 days;
            price = finneyCostOfEachToken * 1 finney;
            tokenReward = token(addressOfTokenUsedAsReward);   // 传入已发布的 token 合约的地址来创建实例
    }
 
    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
 
          // 当有人付款直接取走资金
        beneficiary.send(amount);
    }
}