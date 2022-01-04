/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.4.26;

/**
 * 简易的Erc20代币
*/
contract ERC20 {
    
    /**属性
     * 代币名称
    */
    string public name;
    
    /**属性
     * 代币简称
    */
    string public symbol;
    
    /**属性
     * 小数位
    */
    uint256 public decimals;
    
    /**属性
     * 发行总量
    */
    uint256 public totalSupply;
    
    /**属性
     * 合约拥有者
    */
    address public founder;
    
    /**属性
     * 地址代币余额
    */
    mapping(address=>uint256) balances;
    
    /**属性
     * 地址授权数量
    */
    mapping(address=>mapping(address=>uint256)) allowed;
    
    /**属性
     * 不知道什么作用
    */
    address public owner;
  
    /**事件
     * 授权地址数量
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    /**事件
     * 交易
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    /**构造函数
     * 初始化方法
     * #parameter   _name           代币名称
     * #parameter   _symbol         代币简称
     * #parameter   _decimals       小数位
     * #parameter   _totalSupply    发行总量
    */
    constructor (string memory _name,string memory _symbol,uint256 _decimals,uint256 _totalSupply) public  payable{
        founder = msg.sender;          //设定合约拥有者
        name = _name;                  //初始化代币名称 
        symbol = _symbol;              //初始化代币简称
        decimals = _decimals;          //初始化小数位
        totalSupply = _totalSupply * 10**decimals;    //初始化发行量
        balances[address(msg.sender)] = totalSupply; //默认将发行的代币全部给了发布者
        // balances[address(this)] = totalSupply; //默认将发行的代币全部给了本合约
    }
    
    /**方法
     * 地址代币数量
     * #parameter   address     _owner      查询地址
     * &returns     uint256     balance     数量
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
  
    /**方法
     * 给地址授权数量
     * #parameter   address     _spender    授权地址
     * #parameter   uint256     _amount     授权数量
     * &returns     bool        success     成功或失败
    */
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**方法
     * 交易
     * #parameter   address     _to         接受地址
     * #parameter   uint256     _amount     接受数量
     * &returns     bool        success     成功或失败
    */
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if(balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
   
    /**方法
     * 授权交易
     * #parameter   address     _from       发送地址
     * #parameter   address     _to         接受地址
     * #parameter   uint256     _amount     接受数量
     * &returns     bool        success     成功或失败
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
  
    /**方法
     * 查询授权数量
     * #parameter   address     _owner      持币地址
     * #parameter   address     _spender    授权地址
     * &returns     uint256     remaining   授权数量
    */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

  
}