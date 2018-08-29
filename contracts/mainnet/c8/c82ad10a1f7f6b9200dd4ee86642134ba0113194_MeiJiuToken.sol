pragma solidity ^0.4.16;

contract Token{

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MeiJiuToken is Token {
    uint256 public totalSupply;
    string  public name;
    uint8   public decimals;
    string  public symbol;

    function MeiJiuToken(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol) public {
        totalSupply = initialAmount * 10 ** uint256(decimalUnits);
        balances[msg.sender] = totalSupply;

        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;			//从消息发送者账户中减去token数量_value
        balances[_to] += _value;				//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);		//触发转币交易事件
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;				//接收账户增加token数量_value
        balances[_from] -= _value; 				//支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;	//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);			//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];		
    }
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
}