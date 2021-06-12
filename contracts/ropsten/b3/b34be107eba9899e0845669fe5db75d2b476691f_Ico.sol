/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.4.20;


interface token{
    function transfer(address _to,uint amount) external;
}

contract Ico{

    uint public fundingGoal;    //众筹的目标价格
    uint public deadline;       //众筹的截止时间
    uint public price;          //以太币和代币的兑换价格
    address beneficiary;        //众筹的受益人,这里设置为合约的创建者
    uint funAmount;             //当前募集的总额

    token public tokenReward;//定义一个合约类型

    mapping(address => uint256) public balanceOf;       //定义一个mapping来记录每个人打入的以太币

    event FundTransfer(address backer,uint amount);     //定义一个事件，记录每次募集的记录
    event GoadReached(bool success);                    //定义众筹完成时的事件

    //构造函数
    constructor(uint  fundingGoalInEthers,
                uint  durationMinutes,
                uint  etherCostofEachToken,
                address addresOfToken){

        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationMinutes * 1 minutes;
        price =etherCostofEachToken * 1 ether;// 1eth = 10**18 wei
        tokenReward = token(addresOfToken); //把一个地址强制转换为一个合约类型,这个地址其实就是合约地址
        beneficiary = msg.sender;           //受益人默认是合约的创建者

    }

    //定义一个回退函数，回退函数没有函数名，并且定义的类型为payable,这样在有以太币打来这个合约时，就会触发这个函数来来计算用户打过来的以太币。
    function() public payable{

        require(now<deadline);//判断现在的时间是否小于截止日期，否的话就触发异常，捐赠时间必须小于截止时间

        //拿到用户发送过来的以太币
        uint amount = msg.value;  //单位为：wei

        uint tokenAmount = amount / price;  //单位为：eth

        balanceOf[msg.sender] += amount; //记录用户自己每次众筹累积的以太币数量

        funAmount += amount; //记录当前募集的总额

        tokenReward.transfer(msg.sender,tokenAmount);//返回相应代币给捐赠者

        emit FundTransfer(msg.sender,amount);       //触发记录事件
    }

    //提款函数
    function withDrawal() public{

        require(now >= deadline);//提款时间必须大于截止时间

        if (funAmount >= fundingGoal){
            //众筹的金额达到目标金额，受益人可转走
            if (beneficiary==msg.sender){
                beneficiary.transfer(funAmount);
            }

        }else{
            //如果还没有达到目标金额，其他用户可以转走自己之前捐的金额
            uint amount=balanceOf[msg.sender];
            if (amount>0){
                msg.sender.transfer(amount);
                balanceOf[msg.sender]=0;
            }
        }

    }

    //检测众筹是否完成的函数
    function checkGoadReached() public{
         require(now >= deadline);
         if (funAmount>=fundingGoal){
             emit GoadReached(true);
         }
    }   
}