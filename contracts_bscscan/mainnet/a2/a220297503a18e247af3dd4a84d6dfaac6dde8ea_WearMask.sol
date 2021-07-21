/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/*    For the sake of your health and the health of others,
     please wear a mask                                  */ 

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    Wear mask coins
M         MMMMM                 MMMMMM             M         WM                                           
W                                                  W
M         M M M                  M M M             M   
W        M      M              M       M           M   
M       M        M            M         M          M    
M       M        M            M         M          M  
M        M      M              M       M           M   
M          MMMM                  MMMMM             M    
M                                                  M
WWW                                              WWM
W   WWW                                     WWW    M 
W       WWW                             WWW        M
W           WWMMMMMMMMMMMMMMMMMMMMMMMMM            M
M           M                         M            M
M           W                         W            M
M           W                         M            M
M           W                         W            M
M           M                         W            M
M           WWWWWWWWWWWWWWWWWWWWMMMMMMM            M
M         M                             M          M
M      M                                   M       M
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      */

/*  The WearmaskCoins project calls on people to wear masks.
 Stop the spread of the new coronavirus.
 And distribute masks to people on the road.
 Overcoming the new crown pneumonia is the voice of this era.
 The new coronavirus is a global pandemic with the widest impact that humans have encountered in the past 100 years. 
It spreads quickly, and the infected people die because of breathing difficulties.
 The new coronavirus is a single-stranded RNA virus.
 Prone to mutation. This poses a huge challenge to the development of vaccines.
 Currently. There were more than 4 million deaths and more than 189,350,424 infections. And it's still spreading. At present, there is no medical institution,
 scientific research unit, medical expert or government at home and abroad claiming that they can completely solve this plague.
 Make people survive this catastrophe. Mankind has reached the most dangerous time.
 This needs to rely on ourselves. This is the business of all of us. Today in history also gives each of us the responsibility to contain the virus and stop the spread.
 This is closely related to the health and life safety of each of us. Our family, relatives, and friends all hope that we can survive the plague safely.
 Everyone should be called on to let them wear masks. In the future,
 we will distribute masks on the streets. Popularize epidemic prevention knowledge.
 This is what we want to do. As long as everyone gives a little love, the world will become a better place with a little effort.     */

pragma solidity ^0.4.16;
contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract WearMask is Token {
    
    string public name;                   //名称，例如"My test token"
    uint8 public decimals;               //返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.
    string public symbol;               //token简称,
    
    function WearMask(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);         // 设置初始总量
        balances[msg.sender] = totalSupply; // 初始token数量给予消息发送者，因为是构造函数，所以这里也是合约的创建者
        
        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);//触发转币交易事件
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
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}