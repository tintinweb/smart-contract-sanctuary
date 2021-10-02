/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

pragma solidity ^0.4.16;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

//noinspection ALL 
contract TokenBEP20 {
    string public name;
    string public symbol;
    uint8 public decimals = 6;  // decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值
    uint256 public totalSupply;
    
    // 用mapping保存每个地址对应的余额
    mapping (address => uint256) public balanceOf;
    // 存储对账号的控制
    mapping (address => mapping (address => uint256)) public allowance;
    
    // 事件，用来通知客户端交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // 事件，用来通知客户端代币被消费
    event Burn(address indexed from, uint256 value);

/**
 * 初始化构造
 */
function TokenBEP20(uint256 initialSupply, string tokenName, string tokenSymbol) public {

	totalSupply = initialSupply * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
	balanceOf[msg.sender] = totalSupply;                // 创建者拥有所有的代币
	name = tokenName;                                   // 代币名称
	symbol = tokenSymbol;                               // 代币符号
}

/**
 * 代币交易转移的内部实现
 */
function _transfer(address _from, address _to, uint _value) internal {
	// 确保目标地址不为0x0，因为0x0地址代表销毁
	require(_to != 0x0);
	// 检查发送者余额
	require(balanceOf[_from] >= _value);
	// 溢出检查
	require(balanceOf[_to] + _value > balanceOf[_to]);

	// 以下用来检查交易，
	uint previousBalances = balanceOf[_from] + balanceOf[_to];
	// Subtract from the sender
	balanceOf[_from] -= _value;
	// Add the same to the recipient
	balanceOf[_to] += _value;
	Transfer(_from, _to, _value);

	// 用assert来检查代码逻辑。
	assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
}


function transfer(address _to, uint256 _value) public {
	_transfer(msg.sender, _to, _value);
}


function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	require(_value <= allowance[_from][msg.sender]);     // Check allowance
	allowance[_from][msg.sender] -= _value;
	_transfer(_from, _to, _value);
	return true;
}


function approve(address _spender, uint256 _value) public
returns (bool success) {
	allowance[msg.sender][_spender] = _value;
	return true;
}


function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	public
	returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			// 通知合约
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}


function burn(uint256 _value) public returns (bool success) {
	require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
	balanceOf[msg.sender] -= _value;            // Subtract from the sender
	totalSupply -= _value;                      // Updates totalSupply
	Burn(msg.sender, _value);
	return true;
}


function burnFrom(address _from, uint256 _value) public returns (bool success) {
	require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
	require(_value <= allowance[_from][msg.sender]);    // Check allowance
	balanceOf[_from] -= _value;                         // Subtract from the targeted balance
	allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
	totalSupply -= _value;                              // Update totalSupply
	Burn(_from, _value);
	return true;
}
}