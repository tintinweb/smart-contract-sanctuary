/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity ^0.4.20;

contract ERC20Interface{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _form,address _to,uint256 _value) external returns (bool success);
    
    function approve(address _spender,uint256 _value) external returns (bool success);
    function allowance(address _owner,address _spender)  external returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract erc20 is ERC20Interface{
    
    mapping(address => uint) public balanceOf;  //定义每个账号的余额
    mapping(address => mapping(address => uint)) public allowed;    // 记录管理员授权地址和金额
    
    constructor () public {
        name = "GoChain";
        symbol = "GOT";
        decimals = 8;
        totalSupply = 100000;
        balanceOf[msg.sender] = totalSupply;
    }
    
    // 转账函数,转移_value的token数量到地址_to,必须触发Transfer事件.
    function transfer(address _to, uint256 _value) external returns (bool success){
        require(_to != address(0));     // 目标地址不能为空
        require(balanceOf[msg.sender] >= _value);   // 判断源地址的余额是否足够要转出的余额
        require(balanceOf[_to] + _value >= balanceOf[_to]); // 判断目标地址是否溢出
        
        
        balanceOf[msg.sender] -= _value;    // 管理者地址代币减掉_value
        balanceOf[_to] += _value;           // 接收方地址代币加上_value
        
        emit Transfer(msg.sender,_to,_value);   // 必须要触发Transfer事件
        
        return true;
    }
    
    // 从地址 _form发送数量为 _value的token到地址 _to,必须触发Transfer事件
    // 授权地址的转账
    function transferFrom(address _form,address _to,uint256 _value) external returns (bool success){
        require(_to != address(0));
        require(allowed[_form][msg.sender] >= _value);  // 
        require(balanceOf[_form] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[_form] -= _value;    // 被授权地址金额扣除
        balanceOf[_to] += _value;   // 目标地址金额增加
        allowed[_form][msg.sender] -= _value;   // 这句不理解
        //其实allowed[_form]是合约,授权了我[msg.sender]去减他的币.
        //那么我执行的时候是指定合约地址的币转到某个地址,我等于是代理人,而合约给了我动用的权限
        
        emit Transfer(_form,_to,_value);
        
        return true;
    }
    
    // 授权 _spender账号使用 _owner的代币,最高达 _value.如果再次调用此函数,它将以 _value覆盖当前的余量.
    function approve(address _spender,uint256 _value) external returns (bool success){
        allowed[msg.sender][_spender] = _value;     // 授权目标地址赋值金额
        // 这里的msg.sender是合约,或管理员,授权了_spender来动用限定数量代币
        
        emit Approval(msg.sender,_spender,_value);
        
        return true;
    }
    
    // 返回 _spender仍然被允许从 _owner提取的金额
    function allowance(address _owner,address _spender)  external returns (uint256 remaining){
        return allowed[_owner][_spender];
        // 返回的是主合约或主地址的授权地址的余额
    }
    
}