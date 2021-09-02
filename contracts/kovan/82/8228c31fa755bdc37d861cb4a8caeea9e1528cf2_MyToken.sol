/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity >=0.7.0 <0.9.0;
contract MyToken { 
    /* 设置一个数组存储每个账户的代币信息 */
	mapping(address => uint256) public balanceOf; 
    /* 设置变量 */ 
    /* name 代币名称 */ 
    /* symbol 代币图标 */ 
    /* decimals 代币小数点位数 */
	string public name;
	string public symbol;
	uint8 public decimals; 
	uint256 public totalSupply;
    /* event事件，它的作用是提醒客户端发生了这个事件，你会注意到钱包有时候会在右下角弹出信息 */
	event Transfer(address indexed from, address indexed to, uint256 value); 
	/* 接收用户输入，实现代币的初始化 */
	constructor (uint256 initialSupply, string memory tokenName, 
	             uint8 decimalUnits, string memory tokenSymbol){
		balanceOf[msg.sender] = initialSupply*10**18; // Give the creator all initial 
		totalSupply = balanceOf[msg.sender];
		name = tokenName; // Set the name for display 
		decimals = decimalUnits; // Amount of decimals for display purposes
		symbol = tokenSymbol; // Set the symbol for display
	}
	
	/* 代币交易的函数 */
	function transfer(address _to, uint256 _value) public{
		/* 检查发送方有没有足够的代币 */
		require (balanceOf[msg.sender] > _value && balanceOf[_to] + _value > balanceOf[_to],"balance not enough"); 
        /* 交易过程，发送方减去代币，接收方增加代币 */
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
        /* 提醒客户端发生了交易事件 */
		emit Transfer(msg.sender, _to, _value);
	}
	
	function balance(address _address) external view returns (uint256) {
	    return balanceOf[_address];
	}
}