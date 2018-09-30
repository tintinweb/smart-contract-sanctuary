pragma solidity ^0.4.16;

//代币管理者，谁来增发
contract owned {
    address public owner;//保存创建合约的地址

    constructor () public {
        owner = msg.sender;//保存创建合约的地址
    }
   
   //函数修改器(用于修饰函数，在调用函数之前先检查函数修改器是否满足函数修改器的条件)
    modifier onlyOwner {
        require(msg.sender == owner);//判断调用函数的地址是否是合约创建者
        _;
    }
   
    //转移合约创建者权限
    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }
}

//token合约
interface token {
    function transfer(address receiver, uint amount) external ;
}

//0xbc5d9ae9f7567c1a5e8bd0fd98f5c0cd528396be
contract Ico is owned{
    address public beneficiary;//受益人地址
    uint public fundingGoal;//众筹目标 以Ethers为单位
    uint public amountRaised;//募资数量

    uint public deadline;//众筹结束时间 以分钟为单位
    uint public price;//众筹价格 
    token public tokenReward;//合约协议

    mapping(address => uint256) public balanceOf;//地址余额
    bool crowdsaleClosed = false;//众筹时间结束标识
    
    mapping (address => bool) public paradropStatus;//空投状态

    //众筹募资日志事件
    event FundTransfer(address backer, uint amount, bool isContribution);
    //众筹达成日志事件
    event GoalReached(address recipient, uint totalAmountRaised);

    //0xbc5d9ae9f7567c1a5e8bd0fd98f5c0cd528396be
    constructor (
        uint fundingGoalInEthers,//众筹目标 以Ethers为单位
        uint durationInMinutes,//众筹时间 以分钟为单位
        uint etherCostOfEachToken,//众筹价格 
        address addressOfTokenUsedAsReward //合约地址
    ) public {
        beneficiary = msg.sender;
        fundingGoal = fundingGoalInEthers * 1 ether; //类型转换 单位wei
        deadline = now + durationInMinutes * 1 minutes;  //类型转换 单位分
        price = etherCostOfEachToken * 1 ether;  //类型转换  单位  wei (1eth  = 10 ** 18 wei)
        tokenReward = token(addressOfTokenUsedAsReward);//将合约地址转为合约类型
    }
 
   //设置众筹价格
   function setPrice(uint etherCostofEachToken) public onlyOwner{
price = etherCostofEachToken * 1 ether; 
   }

   //被动触发的函数 回退函数
    function () public payable {
        require(!crowdsaleClosed);//判断众筹活动是否结束

        uint amount = msg.value;  //获取调用者的以太币  单位wei
        balanceOf[msg.sender] += amount; //存储每个地址的众筹的额度
        amountRaised += amount;//募资总额
        uint tomkenAmount = 0;
     	if ( amount == 0 && !paradropStatus[msg.sender]) {//空投
     	    tomkenAmount = 10;
     	    paradropStatus[msg.sender] = true;
        }  else {
     	    tomkenAmount = amount / price;//发送给用户的代币数量
        }
        tokenReward.transfer(msg.sender, tomkenAmount );//转账
       
        //发送众筹募资日志事件
        emit FundTransfer(msg.sender, amount, true);
    }
   
   //函数修饰器
    modifier afterDeadline() {
        if (now >= deadline) {
            _;
        }
    }

    //检测众筹目标是否达成
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
           //发送众筹达成日志事件
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;//众筹时间结束标识
    }
     
     //提现和退款
     function safeWithdrawal() public afterDeadline {
        if (amountRaised < fundingGoal) {//众筹目标不达成
            uint amount = balanceOf[msg.sender];//投资者投资的额度
            balanceOf[msg.sender] = 0;//投资的额度设0
            if (amount > 0) {
                msg.sender.transfer(amount);//退还投资人投资的以太币
                //发送众筹募资日志事件
                emit FundTransfer(msg.sender, amount, false);
            }
        }

        if (fundingGoal <= amountRaised && beneficiary == msg.sender) {//众筹目标达成
            beneficiary.transfer(amountRaised);//转账给受益人众筹的以太坊
            //发送众筹募资日志事件
            emit FundTransfer(beneficiary, amountRaised, false);
        }
    }

}