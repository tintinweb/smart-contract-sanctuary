/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity >=0.4.22 <0.9.0;

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
    constructor() {
            tokenReward = token(0x6ad2a6ef6fe006830d6e35449b302f3d5ce8afc2);   // 传入已发布的 token 合约的地址来创建实例
    }

    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    function pay(uint amount) payable {
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
    }

    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    function () payable {
          uint amount = msg.value;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
    }
}