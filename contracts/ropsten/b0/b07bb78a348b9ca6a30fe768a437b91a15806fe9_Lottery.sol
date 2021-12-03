/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-09-12
*/
pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
contract Token{
	mapping (address => uint256) balances;
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;

    //ERC20 Token Standard: https://eips.ethereum.org/EIPS/eip-20
    constructor() public { 
        name = "guiyang Token";                                         	// Set the name 
        symbol = "GYBB";                                              // Set the symbol 
        decimals = 18;                                              // Amount of decimals for display purposes
		totalSupply = 1000000;                       // Not set total supply	壹佰亿
		balances[msg.sender] = totalSupply * 10 ** uint256(decimals);
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
		balances[msg.sender] -= _value;                            // Subtract token from the sender
		balances[_to] += _value;                                   // Add the same amount to the receiver                      
		 
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
        balances[_from] -= _value;                          // Subtract from the sender
        balances[_to] += _value;                            // Add the same amount to the receiver
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
        lotteryBet = 1000 gwei;
        drawStartTime = now + 1 days;
        //允许开奖时间为 30 minutes
        drawEndTime = now +30 minutes;
    }

    //投注函数
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
    //开奖函数
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
}