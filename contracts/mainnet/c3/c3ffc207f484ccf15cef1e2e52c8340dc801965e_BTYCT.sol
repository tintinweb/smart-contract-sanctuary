pragma solidity ^ 0.4 .16;
/* 创建一个父类，账户管理员 */
contract owned {

	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	/* 修改标志 */
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	/* 修改管理员账户， onlyOwner代表只能是用户管理员来修改 */
	function transferOwnership(address newOwner) onlyOwner public {
		owner = newOwner;
	}
}

/* receiveApproval服务合约指示代币合约将代币从发送者的账户转移到服务合约的账户（通过调用服务合约的 */
contract tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract TokenERC20 {
	// 公共变量
	string public name; //代币名字
	string public symbol; //代币符号
	uint8 public decimals = 18; //代币小数点位数， 18是默认， 尽量不要更改

	uint256 public totalSupply; //代币总量

	// 记录各个账户的代币数目
	mapping(address => uint256) public balanceOf;

	// A账户存在B账户资金
	mapping(address => mapping(address => uint256)) public allowance;

	// 转账通知事件
	event Transfer(address indexed from, address indexed to, uint256 value);

	// 销毁金额通知事件
	event Burn(address indexed from, uint256 value);

	/* 构造函数 */
	constructor(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) public {
		totalSupply = initialSupply * 10 ** uint256(decimals); // 根据decimals计算代币的数量
		balanceOf[msg.sender] = totalSupply; // 给生成者所有的代币数量
		name = tokenName; // 设置代币的名字
		symbol = tokenSymbol; // 设置代币的符号
	}

	/* 私有的交易函数 */
	function _transfer(address _from, address _to, uint _value) internal {
		// 防止转移到0x0， 用burn代替这个功能
		require(_to != 0x0);
		// 检测发送者是否有足够的资金
		//require(canOf[_from] >= _value);

		require(balanceOf[_from] >= _value);

		// 检查是否溢出（数据类型的溢出）
		require(balanceOf[_to] + _value > balanceOf[_to]);
		// 将此保存为将来的断言， 函数最后会有一个检验
		uint previousBalances = balanceOf[_from] + balanceOf[_to];

		// 减少发送者资产
		balanceOf[_from] -= _value;

		// 增加接收者的资产
		balanceOf[_to] += _value;

		emit Transfer(_from, _to, _value);
		// 断言检测， 不应该为错
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

	}

	/* 传递tokens */
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}

	/* 从其他账户转移资产 */
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
		require(_value <= allowance[_from][msg.sender]); // Check allowance
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	/*  授权第三方从发送者账户转移代币，然后通过transferFrom()函数来执行第三方的转移操作 */
	function approve(address _spender, uint256 _value) public
	returns(bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}

	/*
	为其他地址设置津贴， 并通知
	发送者通知代币合约, 代币合约通知服务合约receiveApproval, 服务合约指示代币合约将代币从发送者的账户转移到服务合约的账户（通过调用服务合约的transferFrom)
	*/

	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	public
	returns(bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if(approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	/**
	 * 销毁代币
	 */
	function burn(uint256 _value) public returns(bool success) {
		require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
		balanceOf[msg.sender] -= _value; // Subtract from the sender
		totalSupply -= _value; // Updates totalSupply
		emit Burn(msg.sender, _value);
		return true;
	}

	/**
	 * 从其他账户销毁代币
	 */
	function burnFrom(address _from, uint256 _value) public returns(bool success) {
		require(balanceOf[_from] >= _value); // Check if the targeted balance is enough
		require(_value <= allowance[_from][msg.sender]); // Check allowance
		balanceOf[_from] -= _value; // Subtract from the targeted balance
		allowance[_from][msg.sender] -= _value; // Subtract from the sender&#39;s allowance
		totalSupply -= _value; // Update totalSupply
		emit Burn(_from, _value);
		return true;
	}
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract BTYCT is owned, TokenERC20 {

	uint256 public totalSupply; //代币总量
	uint256 public decimals = 18; //代币小数点位数
	uint256 public sellPrice = 510; //出售价格 1枚代币换多少以太 /1000
	uint256 public buyPrice =  526; //购买价格 多少以太可购买1枚代币 /1000
	uint256 public sysPrice = 766 * 10 ** uint256(decimals); //挖矿的衡量值
	uint256 public sysPer = 225; //挖矿的增量百分比 /100
	
	//uint256 public onceOuttime = 86400; //增量的时间 正式 
	//uint256 public onceAddTime = 864000; //挖矿的时间 正式
	//uint256 public onceoutTimePer = 8640000; //增量的百分比 正式
	
	uint256 public onceOuttime = 600; //增量的时间 测试  
	uint256 public onceAddTime = 1800; //挖矿的时间 测试
	uint256 public onceoutTimePer = 60000; //增量的百分比 测试

	/* 冻结账户 */
	mapping(address => bool) public frozenAccount;
	// 记录各个账户的冻结数目
	mapping(address => uint256) public freezeOf;
	// 记录各个账户的可用数目
	mapping(address => uint256) public canOf;
	// 记录各个账户的释放时间
	mapping(address => uint) public cronoutOf;
	// 记录各个账户的增量时间
	mapping(address => uint) public cronaddOf;

	/* 通知 */
	event FrozenFunds(address target, bool frozen);
	//event Logs (string);
	/* 构造函数 */

	function BTYCT(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

	/* 转账， 比父类加入了账户冻结 */
	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0); // Prevent transfer to 0x0 address. Use burn() instead
		require(canOf[_from] >= _value);
		require(balanceOf[_from] >= _value); // Check if the sender has enough

		require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
		require(!frozenAccount[_from]); // Check if sender is frozen
		require(!frozenAccount[_to]); // Check if recipient is frozen

		//挖矿 
		if(cronaddOf[_from] < 1) {
			cronaddOf[_from] = now + onceAddTime;
		}
		if(cronaddOf[_to] < 1) {
			cronaddOf[_to] = now + onceAddTime;
		}
		//释放 
		if(cronoutOf[_to] < 1) {
			cronoutOf[_to] = now + onceOuttime;
		}
		if(cronoutOf[_to] < 1) {
			cronoutOf[_to] = now + onceOuttime;
		}
		//if(freezeOf[_from] > 0) {
		uint lefttime = now - cronoutOf[_from];
		if(lefttime > onceOuttime) {
			uint leftper = lefttime / onceoutTimePer;
			if(leftper > 1) {
				leftper = 1;
			}
			canOf[_from] = balanceOf[_from] * leftper;
			freezeOf[_from] = balanceOf[_from] - canOf[_from];
			cronoutOf[_from] = now + onceOuttime;
		}

		
		uint lefttimes = now - cronoutOf[_to];
		if(lefttimes >= onceOuttime) {
			uint leftpers = lefttime / onceoutTimePer;
			if(leftpers > 1) {
				leftpers = 1;
			}
			canOf[_to] = balanceOf[_to] * leftpers;
			freezeOf[_to] = balanceOf[_to] - canOf[_to];
			cronoutOf[_to] = now + onceOuttime;
		}
	
        require(canOf[_from] >= _value);
		balanceOf[_from] -= _value; // Subtract from the sender
		balanceOf[_to] += _value;
		//减少可用
		canOf[_from] -= _value;
		//增加冻结 
		freezeOf[_to] += _value;

		emit Transfer(_from, _to, _value);
	}

	//获取可用数目
	function getcan(address target) public returns (uint256 _value) {
	    if(cronoutOf[target] < 1) {
	        _value = 0;
	    }else{
	        uint lefttime = now - cronoutOf[target];
	        uint leftnum = lefttime/onceoutTimePer;
	        if(leftnum > 1){
	            leftnum = 1;
	        }
	        _value = balanceOf[target]*leftnum;
	    }
	}
	
	/// 向指定账户拨发资金
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		require(!frozenAccount[target]);
		require(balanceOf[target] >= freezeOf[target]);
		if(cronoutOf[target] < 1) {
		    cronoutOf[target] = now + onceOuttime;
		}
		if(cronaddOf[target] < 1) {
		    cronaddOf[target] = now + onceAddTime;
		}
		
		//unit aount = unit(mintedAmount);
		uint256 amounts = mintedAmount * 99 / 100;
		freezeOf[target] = freezeOf[target] + amounts;
		balanceOf[target] += mintedAmount;
		//require(balanceOf[target] >= freezeOf[target]);
		canOf[target] = balanceOf[target] - freezeOf[target];
		require(canOf[target] >= 0);
		
		balanceOf[this] -= mintedAmount;
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);

	}
	//用户每隔10天挖矿一次
	function mint() public {
		require(!frozenAccount[msg.sender]);
		require(cronaddOf[msg.sender] > 0 && now > cronaddOf[msg.sender] && balanceOf[msg.sender] >= sysPrice);
		uint256 mintAmount = balanceOf[msg.sender] * sysPer / 10000;
		balanceOf[msg.sender] += mintAmount;
		balanceOf[this] -= mintAmount;
		
		freezeOf[msg.sender] = freezeOf[msg.sender] + mintAmount;
		require(balanceOf[msg.sender] >= freezeOf[msg.sender]);
		cronaddOf[msg.sender] = now + onceAddTime;
		
		emit Transfer(0, this, mintAmount);
		emit Transfer(this, msg.sender, mintAmount);

	}

	/// 冻结 or 解冻账户
	function freezeAccount(address target, bool freeze) onlyOwner public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	// 设置销售购买价格
	function setPrices( uint256 newBuyPrice, uint256 newSellPrice, uint256 systyPrice, uint256 sysPermit) onlyOwner public {
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
		sysPrice = systyPrice * 10 ** uint256(decimals);
		sysPer = sysPermit;
	}
	function getprice() constant public returns (uint256 bprice,uint256 spice,uint256 sprice,uint256 sper) {
          bprice = buyPrice * 10 ** uint256(decimals);
          spice = sellPrice * 10 ** uint256(decimals);
          sprice = sysPrice;
          sper = sysPer * 10 ** uint256(decimals);
   }
	// 购买
	function buy(uint256 amountbuy) payable public returns(uint256 amount) {
	    require(!frozenAccount[msg.sender]);
		require(buyPrice > 0 && amountbuy > buyPrice); // Avoid dividing 0, sending small amounts and spam
		amount = amountbuy / (buyPrice/1000); // Calculate the amount of Dentacoins
		require(balanceOf[this] >= amount); // checks if it has enough to sell
		balanceOf[msg.sender] += amount; // adds the amount to buyer&#39;s balance
		balanceOf[this] -= amount; // subtracts amount from seller&#39;s balance
		emit Transfer(this, msg.sender, amount); // execute an event reflecting the change
		return amount; // ends function and returns
	}
	

	// 出售
	function sell(uint256 amount) public returns(uint revenue) {
	    require(!frozenAccount[msg.sender]);
		require(sellPrice > 0); // Avoid selling and spam
		require(balanceOf[msg.sender] >= amount); // checks if the sender has enough to sell
		if(cronoutOf[msg.sender] < 1) {
			cronoutOf[msg.sender] = now + onceOuttime;
		}
		
		uint lefttime = now - cronoutOf[msg.sender];
		if(lefttime > onceOuttime) {
			uint leftper = lefttime / onceoutTimePer;
			if(leftper > 1) {
				leftper = 1;
			}
			canOf[msg.sender] = balanceOf[msg.sender] * leftper;
			freezeOf[msg.sender] = balanceOf[msg.sender] - canOf[msg.sender];
			cronoutOf[msg.sender] = now + onceOuttime;
		}
		require(canOf[msg.sender] >= amount);
		canOf[msg.sender] -= amount;
		balanceOf[this] += amount; // adds the amount to owner&#39;s balance
		balanceOf[msg.sender] -= amount; // subtracts the amount from seller&#39;s balance
		revenue = amount * sellPrice/1000;
		require(msg.sender.send(revenue)); // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
		emit Transfer(msg.sender, this, amount); // executes an event reflecting on the change
		return revenue;

	}

}