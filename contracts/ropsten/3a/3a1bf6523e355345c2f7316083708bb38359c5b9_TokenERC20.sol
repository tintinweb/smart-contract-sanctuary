pragma solidity ^0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract TokenERC20 {
    using SafeMath for uint256;
    
    // 代币名称 
    string public name;
    // 代币简称 
    string public symbol;
    // 小数点 
    uint256 public decimals = 18;
    // 发行代币总量 
    uint256 public totalSupply;
    // 用户的余额 
    mapping(address => uint256) public balanceOf;
    // 授权允许
    mapping(address => mapping(address => uint256)) public allowance;
    
    // 构造函数，初始化成员变量
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
        )public 
    {
        totalSupply = initialSupply * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    // 交易事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // 批准、授权事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // 交易内部函数
    function _transfer(address _from, address _to, uint256 _value) internal{
        require(_to != address(0));
        // 检查balanceOf[_from]数量
        require(balanceOf[_from] >= _value);
        // 减去balanceOf[_from]账户_value数量的代币
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // 增加balanceOf[_to]账户_value数量的代币
        balanceOf[_to] = balanceOf[_to].add(_value);
        // 触发Transfer事件
        emit Transfer(_from, _to, _value);
    }
    
    // 固定_transfer函数里，_from的入参为msg.sender
    function transfer(address _to, uint256 _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    // 被批准人发起， _from为批准人，_to为将token交易给谁， _value为交易数量
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success){
        // 数据检查
        require(allowance[_from][msg.sender] >= _value);
        // 减去allowance里_value数量的token
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        // 交易，这里才是真正从_from账户里面扣除了_value数量的token
        _transfer(_from, _to, _value);
        return true;
    }
    
    // 批注、授权_spender，数量为_value
    function approve(address _spender, uint256 _value) public returns (bool success){
        // 将批注人，被批注人，批准token数量记录
        allowance[msg.sender][_spender] = _value;
        // 出发Approval事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
}