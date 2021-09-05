//SourceUnit: ddj.sol

pragma solidity 0.5.10;


interface TRC20 {
    

    function totalSupply() external   returns (uint);
    function balanceOf(address tokenOwner) external  returns (uint balance);
    function allowance(address tokenOwner, address spender) external  returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract TSOE is TRC20 {

 
    string public constant name  = "TSOE";
    string public constant symbol = "TSOE";
    uint8 public constant decimals = 18;
    uint256 private roughSupply = 5162000000000000000000;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;


    
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        // require(_to != 0x0);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
       emit Transfer(msg.sender, _to, _value);//触发转币交易事件

        return true;
    }

 function totalSupply() public  returns(uint256) {
        return roughSupply;
    }
    function transferFrom(address _from, address _to, uint256 _value)  public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
     emit   Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) public  returns (uint256 balance) {
        return balances[_owner];
    }
  function allowance(address _owner, address _spender) public  returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    
    

    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
     emit   Approval(msg.sender, _spender, _value);
        return true;
    }
     constructor() public {
      balances[msg.sender] += roughSupply;
    }
 
}