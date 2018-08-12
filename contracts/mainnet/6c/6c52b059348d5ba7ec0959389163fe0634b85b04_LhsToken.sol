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
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);  
}  
  
contract LhsToken is Token {  
  
    string public name;                   //名称，例如"My test token"  
    uint8 public decimals;               //返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.  
    string public symbol;               //token简称,like MTT  
    
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    
    function LhsToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {  
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);         // 设置初始总量  
        balances[msg.sender] = totalSupply; // 初始token数量给予消息发送者，因为是构造函数，所以这里也是合约的创建者  
  
        name = _tokenName;                     
        decimals = _decimalUnits;            
        symbol = _tokenSymbol;  
    }  



    // token的发送函数
    function _transferFunc(address _from, address _to, uint _value) internal {

        require(_to != 0x0);    // 不是零地址
        require(balances[_from] >= _value);        // 有足够的余额来发送
        require(balances[_to] + _value > balances[_to]);  // 这里也有意思, 不能发送负数的值(hhhh)

        uint previousBalances = balances[_from] + balances[_to];  // 这个是为了校验, 避免过程出错, 总量不变对吧?
        balances[_from] -= _value; //发钱 不多说
        balances[_to] += _value;
        Transfer(_from, _to, _value);   // 这里触发了转账的事件 , 见上event
        assert(balances[_from] + balances[_to] == previousBalances);  // 判断总额是否一致, 避免过程出错
    }
  
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        _transferFunc(msg.sender, _to, _value); // 这里已经储存了 合约创建者的信息, 这个函数是只能被合约创建者使用
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // 这句很重要, 地址对应的合约地址(也就是token余额)
        allowed[_from][msg.sender] -= _value;
        _transferFunc(_from, _to, _value);
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
}