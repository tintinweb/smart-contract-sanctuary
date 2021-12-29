/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-09-12
*/
pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: Unlicensed

contract SafeMath {
    //乘法
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
    //除法
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
    //减法
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
    //加法
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }


}
//the twelve Chinese zodiac signs
contract Token  is SafeMath{
    address owner;
	mapping (address => uint256) balances;
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;

    //ERC20 Token Standard: https://eips.ethereum.org/EIPS/eip-20
    constructor() { 
        name = "chinese zodiac signs";                                         	// Set the name 
        symbol = "CZS";                                              // Set the symbol 
        decimals = 18;                                              // Amount of decimals for display purposes
		totalSupply = 1000;                       // Not set total supply	壹亿 one hundred million
		balances[msg.sender] = totalSupply * 10 ** uint256(decimals);
        owner = msg.sender;
    }
	
    //Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public view returns (uint256 balance) {
		 return balances[_owner];	
	}

    /* Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
       The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
	   Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.*/
    function transfer(address _to, uint256 _value) public returns (bool success) {
	    require(_value > 0 );                                      // Check if token's value to be send > 0
		require(balances[msg.sender] >= _value);                   // Check if the sender has enough token
        require(balances[_to] + _value > balances[_to]);           // Check for overflows											
		balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                            // Subtract token from the sender
		balances[_to] = SafeMath.safeAdd(balances[_to],_value);                                   // Add the same amount to the receiver                      
		 
		emit Transfer(msg.sender, _to, _value); 				   // Notify anyone listening that this transaction happen.
		return true;      
	}

	/* The transferFrom method is used for a withdraw workflow, 
	   allowing contracts to transfer tokens on your behalf. 
	   This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
	   The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
	   Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.*/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	  
	    require(balances[_from] >= _value);                 // Check if the sender has enough token
        require(balances[_to] + _value >= balances[_to]);   // Check for overflows
        require(_value <= allowed[_from][msg.sender]);      // Check allowance
        balances[_from] = SafeMath.safeSub(balances[_from], _value);                          // Subtract from the sender
        balances[_to] = SafeMath.safeAdd(balances[_to],_value);                            // Add the same amount to the receiver
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
	}

	/* Allows _spender to withdraw from your account multiple times, 
	   up to the _value amount. If this function is called again it overwrites the current allowance with _value.
	   NOTE: To prevent attack vectors like the one described here and discussed here, 
	   clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender. 
	   THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before */
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);
		allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
		return true;
	
	}
	
	//Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
	}
	

	//The event for tranfer and approve
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Lottery is Token {
	//管理员地址
    address manager;
    //中奖人地址
    ticket[] public winners;
	//中奖生肖
    uint public winningZodiac;
    //十二生肖地址
    string[] public zodiacSigns = ["rat","cow","tiger","rabbit","dragon","snake","horse","sheep","monkey","chicken","dog","pig"];
    //投注人地址、投注生肖 集合
    ticket[] public lotteryPlayers;
    //兑奖失败集合
    ticket[] public lotteryFails;
    //彩票期数
    uint public roundNum;
    //中奖人获奖比例(例：当获奖金比例为90%)
    uint public rewardRate;
    //管理员维护费用比例 (例：当获奖金比例为1%)
    uint public mgRewardRate;
    //中奖人获得奖金的具体金额
    uint public winningReward;
    //每次管理员可以开奖的起始时间点
    uint public drawStartTime;
    //每次管理员可以开奖的结束时间点
    uint public drawEndTime;

    constructor() {
    	//创建合约者自动为管理员
        manager = msg.sender;
        //奖池内以太坊的90%给中奖者
        rewardRate = 90;
        mgRewardRate = 1;
        uint nowTime = block.timestamp;

        drawStartTime = nowTime + 300 minutes;
        //允许开奖时间为 30 minutes
        drawEndTime = drawStartTime +30 minutes;
    }

   //修饰器，确保只有管理员有权限来操作
	modifier managerLimit {
        require(msg.sender == manager);
        _;
    }

    //投注票据
    struct ticket{
        //玩家地址
        address player;
        //投注数量 单位 wei
        uint256 throwSum;
        //投注生肖
        uint8 throwZodiac;
    }

     //投注函数
    function throwInT(uint8 zodiac, uint16 _value) public returns(uint16){
        return zodiac + _value;
    }

    //投注函数
    function throwIn(uint8 zodiac, uint16 _value) public returns(bool){
        //校验投注生肖是否正确
        require(zodiac >= 0 && zodiac <= 12);
 		//保证彩民投注的金额大于1
        require(_value >= 1);

        //wei 单位换算
        uint256 transValue = _value * 10 ** uint256(decimals);

        //只有在开奖时间之前才可以投注
        require(block.timestamp < drawStartTime);
        //判断彩民账户余额是否足够
        require(balances[msg.sender] >= transValue);
        //把投注数转入合约账户
	    balances[address(this)] += transValue;
        //扣除投注者账户余额
        balances[msg.sender] -= transValue;

        //将投注者投注信息添加进数组
        lotteryPlayers.push(ticket({player:msg.sender, throwSum: _value, throwZodiac:zodiac}));
        //记录日志
        return true;
    }
    
    //开奖函数
    function draw() public managerLimit returns(bool) {
    	//确保当前盘内有人投注
        require(lotteryPlayers.length != 0, "No betting");
        //确保在允许的开奖时间段内
        // require(block.timestamp >= drawStartTime && block.timestamp < drawEndTime);
        //利用随机值来获取此次中奖生肖下标
        winningZodiac = 1; //getRandom();
        //中奖总注数
        uint lotteryTotal = 0;

        //遍历投注集合，获取中奖人信息及中奖总注数
        for(uint i=0; i<lotteryPlayers.length; i++){
            ticket memory throwTicket = lotteryPlayers[i];
             if(winningZodiac == throwTicket.throwZodiac){
                lotteryTotal = SafeMath.safeAdd(lotteryTotal,throwTicket.throwSum);
                //放入中奖名单结合
                winners.push(throwTicket);
             }
        }
        require(lotteryTotal > 0, "No one won the prize");    

        //根据当前盘内可以分给中奖人的总量
        winningReward = balances[address(this)] * (rewardRate/100);
        //计算每一注中奖数量
        uint256 single = SafeMath.safeDiv(winningReward, lotteryTotal);
        require(single > 0 && single < winningReward, "single reward error");

        //给管理员提成
        uint256 managerProfit = balances[address(this)] * (mgRewardRate/100);
        balances[manager] = SafeMath.safeAdd(balances[manager], managerProfit);
        balances[address(this)] = SafeMath.safeSub(balances[address(this)], managerProfit);

        //转账给中奖人
        for(uint i=0; i<winners.length; i++){
            ticket memory throwTicket = winners[i];
            //中奖地址
            address addr = throwTicket.player;
            //中奖数量
            uint256 winSum = SafeMath.safeMul(single,throwTicket.throwSum);
            if(balances[address(this)] > winSum){
                //合约账户扣除
                balances[address(this)] = SafeMath.safeSub(balances[address(this)], winSum);
                //中奖人账户增加
                balances[addr] = SafeMath.safeAdd(balances[addr], winSum);
            }else{
                //记录日志 
                lotteryFails.push(throwTicket); 
            }
        }
 
        //彩票期数+1
        roundNum++;
        //下次开奖开始时间和结束时间增加1天
        drawStartTime+=3 minutes;
        drawEndTime= drawStartTime + 5 minutes;
        //清空本次投注者数组
        delete lotteryPlayers;
        return true;
    }

    //只有管理员才能发出退款操作
    function refund() public managerLimit{
		//确保此时盘内有人参与投注
        require(lotteryPlayers.length != 0);
        //只有在开奖之前才可以进行退款操作
        require(block.timestamp <= drawEndTime);

        //给本轮所有参与的投注人退款
        for(uint i = 0; i<lotteryPlayers.length; i++){
            ticket memory ticketInfo = lotteryPlayers[i];
            //投注者地址
            address addr = ticketInfo.player;
            uint256 _sum = ticketInfo.throwSum;
            //合约账户扣除
            balances[address(this)] -= _sum;
            //中奖人账户增加
            balances[addr] += _sum;
        }
       
        //清空参与的投注人集合
        delete lotteryPlayers;   
    }

     //只有管理员才能发出退款操作
    function failToRefund() public managerLimit{
	
        require(lotteryFails.length > 0);
        //只有在开奖结束时间之后才可以进行退款操作
        require(block.timestamp >= drawEndTime);
        //遍历给失败者退款
        for(uint i = 0; i<lotteryFails.length; i++){
            ticket memory ticketInfo = lotteryFails[i];
            //投注者地址
            address addr = ticketInfo.player;
            uint256 _sum = ticketInfo.throwSum;
            //合约账户扣除
            balances[address(this)] -= _sum;
            //中奖人账户增加
            balances[addr] += _sum;
        }
        //清空兑奖失败集合
        delete lotteryFails;   
    }

    //获取0~12的随机数 
    function getRandom() public view returns(uint){
        //利用当前区块的时间戳、挖矿难度和盘内投注彩民数来取随机值
        bytes memory randomInfo = abi.encodePacked(block.timestamp,block.difficulty,lotteryPlayers.length); 
        bytes32 randomHash =keccak256(randomInfo);
        uint random =  uint(randomHash)%13;

        return random;
    } 

    //test
    // function testCalc(uint256 one ,uint256 two) public view returns(uint256) {
    //     return SafeMath.safeDiv(one,two);
    // }


     //更换管理员
    function changeManager(address _addr) public managerLimit{
        manager = _addr;
    }

    //返回当前奖池中以太坊的总额
	function getBalance()public view returns(uint){
        return address(this).balance;
    }
    //返回已结束的一期彩票的中奖地址
    function getWinners()public view returns(ticket[] memory){
        return winners;
    }
    //返回管理员的地址
    function getManager()public view returns(address){
        return manager;
    }
    //返回当前参与到投注的彩民地址集合
    function getLotteryPlayers() public view returns(ticket[] memory){
        return lotteryPlayers;
    }
    //返回当前参与到投注的彩民人数
    function getPlayersNum() public view returns(uint){
        return lotteryPlayers.length;
    }
    //返回下一期开奖时间
    function getDrawStartTime() public view returns(uint){
        return drawStartTime;
    }
}