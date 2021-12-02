/**
 *Submitted for verification at Etherscan.io on 2021-12-02
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
		totalSupply = 10000000000;                       // Not set total supply	壹佰亿
		// balances[msg.sender] = totalSupply * 10 ** uint256(decimals);
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

       
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

	//声明 用户-抵押ETH数量 mapping
	mapping (address => uint) pledgeETHAmount;
	
	//声明 抵押/赎回时的event
	event Pledge(address user, uint256 amount);
	event Redeem(address user, uint256 amount);
	

	//抵押功能
	function pledge() public payable returns(bool success){

		//ETH抵押金额必须大于0
		require(msg.value > 0, "Not enough ETH to pledge.");
		//抵押操作
		// 1. 1:1贷出ERC20 Token
		Token.balances[msg.sender] += msg.value;
		// 2. 写入抵押信息map，记录用户抵押ETH的数量：单位wei
		pledgeETHAmount[msg.sender] += msg.value;
		// 3. 更新Token总量
		Token.totalSupply += msg.value;
		//记录抵押事件
		emit Pledge(msg.sender,msg.value);

		return true;
	}

	//赎回功能
	function redeem(uint256 value) public returns(bool success){

		//要求赎回ETH的数量必须 <= Token余额
		require(value <= Token.balances[msg.sender],"Not enough ETH to redeem.");
		//赎回操作
		// 1. 在合约转出ETH到用户地址之前将待发金额清零，更新用户Token余额和Token总量，来防止重入（re-entrancy）攻击
		Token.balances[msg.sender] -= value;
		Token.totalSupply -=  value;
		// 2. 从合约里转ETH到对应用户
		msg.sender.transfer(value);
		//记录赎回事件
		emit Redeem(msg.sender,value);

		return true;
	}
}