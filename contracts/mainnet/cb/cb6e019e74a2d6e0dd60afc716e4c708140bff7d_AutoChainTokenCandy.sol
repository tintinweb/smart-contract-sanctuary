pragma solidity ^0.4.24;

contract AutoChainTokenCandyInface{

    function name() public constant returns (string );
    function  symbol() public constant returns (string );
    function  decimals()  public constant returns (uint8 );
    // 返回token总量，名称为totalSupply().
    function  totalSupply()  public constant returns (uint256 );

    /// 获取账户_owner拥有token的数量 
    function  balanceOf(address _owner)  public constant returns (uint256 );

    //从消息发送者账户中往_to账户转数量为_value的token
    function  transfer(address _to, uint256 _value) public returns (bool );

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function  transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool );

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function  approve(address _spender, uint256 _value) public returns (bool );

    //获取账户_spender可以从账户_owner中转出token的数量
    function  allowance(address _owner, address _spender) public constant returns 
    (uint256 );

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract AutoChainTokenCandy is AutoChainTokenCandyInface {

    /* private variables of the token */
    uint256 private _localtotalSupply;		//总量
    string private _localname;                   //名称: eg Simon Bucks
    uint8 private _localdecimals;               //最多的小数位数，How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string private _localsymbol;               //token简称: eg SBX
    string private _localversion = &#39;0.01&#39;;    //版本

    address private _localowner; //存储合约owner

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    function  AutoChainTokenCandy() public {
        _localowner=msg.sender;		//储存合约的owner
        balances[msg.sender] = 50000000000; // 初始token数量给予消息发送者,需要增加小数点后的位数
        _localtotalSupply = 50000000000;         // 设置初始总量,需要增加小数点后的位数
        _localname = &#39;AutoChainTokenCandy&#39;;                   // token名称
        _localdecimals = 4;           // 小数位数
        _localsymbol = &#39;ATCx&#39;;             // token简称
        
    }

    function getOwner() constant public returns (address ){
        return _localowner;
    }

    function  name() constant public returns (string ){
    	return _localname;
    }
    function  decimals() public constant returns (uint8 ){
    	return _localdecimals;
    }
    function  symbol() public constant returns (string ){
    	return _localsymbol;
    }
    function  version() public constant returns (string ){
    	return _localversion;
    }
    function  totalSupply() public constant returns (uint256 ){
    	return _localtotalSupply;
    }
    function  transfer(address _to, uint256 _value) public returns (bool ) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        emit Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }
    function  transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool ) {
        require(balances[_from] >= _value &&  balances[_to] + _value > balances[_to] && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        emit Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function  balanceOf(address _owner) public constant returns (uint256 ) {
        return balances[_owner];
    }
    function  approve(address _spender, uint256 _value) public returns (bool )   
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function  allowance(address _owner, address _spender) public constant returns (uint256 ) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
}