pragma solidity ^0.4.8;
contract Token
{
    // token總量，默認會為public變量生成一個getter函數接口，名稱為totalSupply().
    uint256 public totalSupply;

    /// 獲取賬戶_owner擁有token的數量 
    function balanceOf(address _owner) constant returns (uint256 balance);

    //從消息發送者賬戶中往_to賬戶轉數量為_value的token
    function transfer(address _to, uint256 _value) returns (bool success);

    //從賬戶_from中往賬戶_to轉數量為_value的token，與approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

    //消息發送帳户設置帳户_spender能從發送賬戶中轉出數量為_value的token
    function approve(address _spender, uint256 _value) returns (bool success);

    //獲取賬戶_spender可以從帳户_owner中轉出token的數量
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

    //發生轉賬時必須要觸發的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //當函数approve(address _spender, uint256 _value)成功執行時必須觸發的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token 
{
    function transfer(address _to, uint256 _value) returns (bool success) 
    {
        //默認totalSupply 不會超操超最大值 (2^256 - 1).
        //如果隨著時間的推移將會有新的token生成，則可以用下面這句避免溢出的異常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        //require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//從消息發送者賬戶中減去token數量_value
        balances[_to] += _value;//往接收帳户增加token數量_value
        Transfer(msg.sender, _to, _value);//觸發轉幣交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) 
    {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value 
        && balances[_to] + _value > balances[_to]);
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收帳户增加token數量_value
        balances[_from] -= _value; //支出帳户_from减去token數量_value
        allowed[_from][msg.sender] -= _value;//消息發送者可以從賬戶_from中轉出的數量減少_value
        Transfer(_from, _to, _value);//觸發轉幣交易事件
        return true;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) 
    {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];//允許_spender從_owner中轉出的token數
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract EZStandardToken is StandardToken 
{ 

    /* Public variables of the token */
    string public name;                   //名稱
    uint8 public decimals;               //最多的小數位數
    string public symbol;               //token簡稱
    string public version = &#39;H0.1&#39;;    //版本
    address owner;
    
    function EZStandardToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) 
    {
        balances[msg.sender] = _initialAmount; // 初始token數量给予消息發送者
        totalSupply = _initialAmount;         // 設置初始總量
        name = _tokenName;                   // token名稱
        decimals = _decimalUnits;           // 小數位數
        symbol = _tokenSymbol;             // token簡稱
    }

    /* Approves and then calls the receiving contract */
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) 
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
    
    modifier onlyowner()
    {
        require(msg.sender == owner);
        _;
    }
    
    function kill() onlyowner
    {
       selfdestruct(owner); //銷毀合約
    }

}