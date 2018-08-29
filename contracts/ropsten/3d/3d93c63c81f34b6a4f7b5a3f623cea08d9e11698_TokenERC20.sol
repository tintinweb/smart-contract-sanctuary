pragma solidity ^0.4.16;
interface tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract TokenERC20 {
	//代币名称
	string public name;
	//代币符号
	string public symbol;
	//代币小数点位数，代币的最小单位
	uint8 public decimals = 18;

	uint256 public totalSupply;
	// 用过mapping保存每个地址对应的余额
	mapping(address => uint256) public balanceOf;
	// 存储对账号的控制
	mapping(address => mapping(address => uint256)) public allowance;

	// 事件，用来通知客户端进行交易
	event Transfer(address indexed from, address indexed to, uint256 value);

	// 事件，用来通知客户端代币被消费
	event Burn(address indexed from, uint256 value);

	// 初始化构造
	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		// 份额 = 币数 * 10 ** decimals
		totalSupply = initialSupply * 10 ** uint256(decimals);
		// 创建者拥有所有的代币
		balanceOf[msg.sender] = totalSupply;
		// 代币的名称
		name = tokenName;
		// 代币的符号
		symbol = tokenSymbol;
	}

	// 代币交易转移的内部实现
	function _transfer(address _from, address _to, uint _value) internal {
		// 确保目标地址不为0x0，0x0代表销毁
		require(_to != 0x0);
		// 检查发送者余额
		require(balanceOf[_from] >= _value);
		// 溢出检查
		require(balanceOf[_to] + _value > balanceOf[_to]);


		// 以下用来检查交易
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		// 发送者账户里减去需要交易的值
		balanceOf[_from] -= _value;
		// 接收者账户里添加交易的值
		balanceOf[_to] += _value;
		// 进行交易
		Transfer(_from, _to, _value);
		// 用assert检查逻辑，验证数量恒定
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}
	/**
	 * 代币交易转移
	 * 从自己(创建交易者)账号发送_value个代币到_to账号
	 */
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}

	// 账号之间代币交易转移
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool succcess) {
		require (_value <= allowance[_from][msg.sender]);
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}


	// 设置某个地址可以创建交易者名义话费的代币树

	function approve(address _spender, uint256 _value) public returns (bool succcess) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}

	// 设置允许一个地址 以 创建交易者 的名义可最多花费的代币数量
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool succcess) {
		tokenRecipient spender = tokenRecipient(_spender);

		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	// 销毁 创建交易者 账户中指定个代币
	function burn(uint256 _value) public returns (bool succcess) {
		require(balanceOf[msg.sender] >= _value);
		balanceOf[msg.sender] -= _value;

		totalSupply -= _value;

		Burn(msg.sender, _value);
		return true;
	}

	// 销毁用户账户中制定个代币

	function burnFrom(address _from, uint256 _value) public returns (bool succcess) {
		require(balanceOf[_from] >= _value);
		require(_value <= allowance[_from][msg.sender]);

		balanceOf[_from] -= _value;

		allowance[_from][msg.sender] -= _value;

		totalSupply -= _value;
		Burn(_from, _value);
		return true;
	}
}