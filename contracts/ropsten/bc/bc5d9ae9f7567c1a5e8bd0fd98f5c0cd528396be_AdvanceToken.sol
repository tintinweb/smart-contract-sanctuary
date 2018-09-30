pragma solidity ^0.4.20;

//ERC-20代币接口
contract ERC20Interface {
    
    string public name;//代币全称
    string public symbol;//代币简称
    uint8 public decimals;//代币最少交易单位，0表示最少交易为1
    uint public totalSupply;//发行总量
    
    //从合约创建者地址转账到_to地址_value个代币
    function transfer(address _to, uint256 _value) returns (bool success);
    //从_from地址账到_to地址_value个代币
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
     //授权_spender地址_value个代币
    function approve(address _spender, uint256 _value) returns (bool success);
    //返回合约创建者授权给_spender地址的额度
    function allowance(address _owner, address _spender) returns (uint256 remaining);
    
    //转账日志 _from 转出地址  _to 转入地址  _value 代币数
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //授权日志 _owner 合约创建者地址 _spender 被授权人地址  _value 代币数 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

//ERC-20代币接口
contract ERC20 is ERC20Interface {
    
    // 对自动生成对应的balanceOf方法
    mapping(address => uint256) public balanceOf;
    // allowed保存每个地址（第一个address） 授权给其他地址(第二个address)的额度（uint256）
    mapping(address => mapping(address => uint256)) allowed;
    
    //构造函数传参 代币全称 代币简称 交易单位 发行总量
    constructor(string _name, string _symbol, uint8 _decimals, uint _totalSupply) public {
       name =  _name;
       symbol = _symbol;
       decimals = _decimals;
       totalSupply = _totalSupply;
       balanceOf[msg.sender] = totalSupply;
    }

    //从合约创建者地址转账到_to地址_value个代币
    function transfer(address _to, uint256 _value) returns (bool success){
        require(_to != address(0));//判断转入地址是否有效
        require(balanceOf[msg.sender] >= _value);//判断转出账号是否有足够余额
        require(balanceOf[ _to] + _value >= balanceOf[ _to]);   // 防止溢出

        balanceOf[msg.sender] -= _value;//转出地址余额减
        balanceOf[_to] += _value;//转入地址加

        //发送事件
        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
    //从_from地址账到_to地址_value个代币
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        require(_to != address(0));//判断转入地址是否有效
        require(allowed[msg.sender][_from] >= _value);//判断转出账号是否有足够授权额度
        require(balanceOf[_from] >= _value);//判断转出账号是否有足够余额
        require(balanceOf[ _to] + _value >= balanceOf[ _to]);// 防止溢出

        balanceOf[_from] -= _value;//转出地址余额减
        balanceOf[_to] += _value;//转入地址加

        allowed[msg.sender][_from] -= _value;//授权额度减

        //发送事件
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     //授权_spender地址_value个代币
    function approve(address _spender, uint256 _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;

        //发送事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    //返回合约创建者授权给_spender地址的额度
    function allowance(address _owner, address _spender) returns (uint256 remaining){
         return allowed[_owner][_spender];
    }

}

//代币管理者，谁来增发
contract owned {
    address public owner;//保存创建合约的地址

    constructor () public {
        owner = msg.sender;//保存创建合约的地址
    }
   
   //函数修改器(用于修饰函数，在调用函数之前先检查函数修改器是否满足函数修改器的条件)
    modifier onlyOwner {
        require(msg.sender == owner);//判断调用函数的地址是否是合约创建者
        _;
    }
   
    //转移合约创建者权限
    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }
}

//代币高级功能的智能合约
contract AdvanceToken is ERC20, owned {

    mapping (address => bool) public frozenAccount;//存储地址冻结状态

    //增发代币日志
    event AddSupply(uint amount);
    //地址冻结日志
    event FrozenFunds(address target, bool frozen);
    //销毁日志事件
    event Burn(address target, uint amount);

    //构造函数传参 代币全称 代币简称 交易单位 发行总量
    constructor (string _name, string _symbol, uint8 _decimals, uint _totalSupply) 
        ERC20(_name, _symbol, _decimals, _totalSupply) public {
        
    }
   
    //增发(挖矿) target 挖矿人(合约管理者)  amount 挖矿数量
    function mine(address target, uint amount) public onlyOwner {
        totalSupply += amount;//增加总发行量
        balanceOf[target] += amount;//增加合约管理人余额

        //发送增发日志事件
        emit AddSupply(amount);
        //发送转账日志事件
        emit Transfer(0, target, amount);
    }
    
    //地址冻结和解冻
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;//改变地址冻结状态
        //发送地址冻结日志事件
        emit FrozenFunds(target, freeze);
    }

    //从合约创建者地址转账到_to地址_value个代币
    function transfer(address _to, uint256 _value) public returns (bool success) {
        success = _transfer(msg.sender, _to, _value);//转账
    }

    //从_from地址账到_to地址_value个代币
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowed[_from][msg.sender] >= _value);//判断调用者是否有足够_from地址的授权额度
        success =  _transfer(_from, _to, _value);//转账
        allowed[_from][msg.sender]  -= _value;//授权额度做减法
    }

    //从_from地址账到_to地址_value个代币
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
      require(_to != address(0));//判断转入地址是否有效
      require(!frozenAccount[_from]);//判断转出地址是否被冻结

      require(balanceOf[_from] >= _value);//判断转出地址余额是否充足
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);// 防止溢出

      balanceOf[_from] -= _value;//转出地址做减法
      balanceOf[_to] += _value;//转入地址做加法

      //发送转账日志事件
      emit Transfer(_from, _to, _value);
      return true;
    }

    //销毁调用者的代币  _value 代币数量
    function burn(uint256 _value) public returns (bool success) {
       require(balanceOf[msg.sender] >= _value);//判断调用者余额是否满足当前要销毁的代币数量

       totalSupply -= _value; //总供应量做减法
       balanceOf[msg.sender] -= _value;//调用者余额做减法

        //发送销毁日志事件
       emit Burn(msg.sender, _value);
       return true;
    }

    //销毁某个地址的代币  _from 地址  _value 代币数量
    function burnFrom(address _from, uint256 _value)  public returns (bool success) {
        require(balanceOf[_from] >= _value);//判断_from余额是否满足当前要销毁的代币数量
        require(allowed[_from][msg.sender] >= _value);//判断调用者是否有足够_from地址的授权额度

        totalSupply -= _value; //总供应量做减法
        balanceOf[msg.sender] -= _value;//调用者余额做减法
        allowed[_from][msg.sender] -= _value;//调用者授权个_from的额度做减法

        //发送销毁日志事件
        emit Burn(msg.sender, _value);
        return true;
    }
}