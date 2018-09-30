pragma solidity ^0.4.20;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
    
}

contract owned {
    address public owner;
   
    constructor () public{
        owner = msg.sender;
    }
   
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
  
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
}

contract token {
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
  
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件

    constructor () public{
      
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
      //避免转帐的地址是0x0
      require(_to != 0x0);
      //检查发送者是否拥有足够余额
      require(balanceOf[_from] >= _value);
      //检查是否溢出
      require(balanceOf[_to] + _value > balanceOf[_to]);
      //保存数据用于后面的判断
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      //从发送者减掉发送额
      balanceOf[_from] -= _value;
      //给接收者加上相同的量
      balanceOf[_to] += _value;
      //通知任何监听该交易的客户端
      emit Transfer(_from, _to, _value);
      //判断买、卖双方的数据是否和转换前一致
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
  
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);   // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
  
    
}

contract XMX is owned, token {
    string public name = &#39;China dragon&#39;; //代币名称
    string public symbol = &#39;CYT3&#39;; //代币符号比如&#39;$&#39;
    uint8 public decimals = 18;  //代币单位，展示的小数点后面多少个0,和以太币一样后面是是18个0
    uint256 public totalSupply; //代币总量
    uint256 initialSupply =0;
  
    //是否冻结帐户的列表
    mapping (address => bool) public frozenAccount;
    //定义一个事件，当有资产被冻结的时候，通知正在监听事件的客户端
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);  //减去用户余额事件
   
    constructor () token () public {
        //初始化总量
        totalSupply = initialSupply * 10 ** uint256(decimals);    //以太币是10^18，后面18个0，所以默认decimals是18
        //给指定帐户初始化代币总量，初始化用于奖励合约创建者
        //balanceOf[msg.sender] = totalSupply;
        balanceOf[this] = totalSupply;
        //设置合约的管理者
        //if(centralMinter != 0 ) owner = centralMinter;
      
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        //避免转帐的地址是0x0
        require (_to != 0x0);
        //检查发送者是否拥有足够余额
        require (balanceOf[_from] > _value);
        //检查是否溢出
        require (balanceOf[_to] + _value > balanceOf[_to]);
        //检查 冻结帐户
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        //从发送者减掉发送额
        balanceOf[_from] -= _value;
        //给接收者加上相同的量
        balanceOf[_to] += _value;
        //通知任何监听该交易的客户端
        emit Transfer(_from, _to, _value);
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        //给指定地址增加代币，同时总量也相加
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function burn(uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        //给指定帐户减去余额
        balanceOf[msg.sender] -= _value;
        //代币问题做相应扣除
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
  
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[_from] >= _value);
        //检查 其他帐户 的余额是否够使用
        require(_value <= allowance[_from][msg.sender]);
        //减掉代币
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        //更新总量
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    
   
}