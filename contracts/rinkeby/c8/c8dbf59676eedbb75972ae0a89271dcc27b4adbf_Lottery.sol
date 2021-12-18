/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract Lottery {
	//管理员地址
    address payable manager;
    //中奖人地址
    address payable winner;
    //投注人地址集合
    address payable [] lotteryPlayers;
	//中奖人的编号
    uint public winningNum;
    //彩票期数
    uint public roundNum;
    //中奖人获奖比例(例：当获奖金比例为80%时，该值为80.)
    uint public rewardRate;
    //中奖人获得奖金的具体金额
    uint public winningReward;
    //每次投注的金额
    uint public lotteryBet;
    //每次管理员可以开奖的起始时间点
    uint public drawStartTime;
    //每次管理员可以开奖的结束时间点
    uint public drawEndTime;
    constructor() public {
    	//创建合约者自动为管理员
        manager = msg.sender;
        //奖池内以太坊的80%给中奖者
        rewardRate = 80;
        //每次限投 1 ether
        lotteryBet = 1 ether;
        drawStartTime = now;
        //允许开奖时间为 30 minutes
        drawEndTime = now +30 minutes;
    }


    function throwIn() public payable{
 		//保证彩民投注的金额为额定金额
        require(msg.value == lotteryBet);
        //只有在开奖时间之前才可以投注
        require(now < drawStartTime);
        //将该彩民的地址添加进数组
        lotteryPlayers.push(msg.sender);
    }

    //修饰器，确保只有管理员有权限来操作
	 modifier managerLimit {
        require(msg.sender == manager);
        _;
    }
    
    //事务，用于测试
    //event test(uint,uint);
    function draw() public managerLimit  {
    	//确保当前盘内有人投注
        require(lotteryPlayers.length != 0);
        //确保在允许的开奖时间段内
        require(now >= drawStartTime && now < drawEndTime);
        //利用当前区块的时间戳、挖矿难度和盘内投注彩民数来取随机值
        bytes memory randomInfo = abi.encodePacked(now,block.difficulty,lotteryPlayers.length); 
        bytes32 randomHash =keccak256(randomInfo);
        //利用随机值来取获奖人在数组中的索引
        winningNum = uint(randomHash)%lotteryPlayers.length;
        //确定中奖人地址
        winner=lotteryPlayers[winningNum];
        //根据当前盘内以太坊总额来确定本次中奖人可得到的奖金
        winningReward = address(this).balance*rewardRate/100;
        //转账给中奖人
        winner.transfer(winningReward);
        //用于测试
        //emit test(reward,address(this).balance);
        //给管理员抽水
        manager.transfer(address(this).balance);
        //彩票期数+1
        roundNum++;
        //下次开奖开始时间和结束时间增加1天
        drawStartTime+=1 days;
        drawEndTime+=1 days;
        //清空本次投注者数组
        delete lotteryPlayers;
    }

    //返回当前奖池中以太坊的总额
	function getBalance()public view returns(uint){
        return address(this).balance;
    }
    //返回已结束的一期彩票的中奖地址
    function getWinner()public view returns(address){
        return winner;
    }
    //返回管理员的地址
    function getManager()public view returns(address){
        return manager;
    }
    //返回当前参与到投注的彩民地址集合
    function getLotteryPlayers() public view returns(address payable [] memory){
        return lotteryPlayers;
    }
    //返回当前参与到投注的彩民人数
    function getPlayersNum() public view returns(uint){
        return lotteryPlayers.length;
    }


    //只有管理员才能发出退款操作
    function refund()public managerLimit{
		//确保此时盘内有人参与投注
        require(lotteryPlayers.length != 0);
        //只有在开奖结束时间之后才可以进行退款操作
        require(now>=drawEndTime);
        uint lenLotteryPlayers = lotteryPlayers.length;
        //给本轮所有参与的投注人退款，款额为额定款额
        for(uint i = 0; i<lenLotteryPlayers;i++){
            lotteryPlayers[i].transfer(lotteryBet);
        }
        //因为流局，期数+1
        roundNum++;
        //因为流局，下一次开奖开始时间和开奖结束时间增加一天
        drawStartTime+=1 days;
        drawEndTime+=1 days;
        //清空参与的投注人集合
        delete lotteryPlayers;   
    }
}