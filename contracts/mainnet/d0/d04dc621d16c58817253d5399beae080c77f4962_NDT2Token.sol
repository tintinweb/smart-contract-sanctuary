pragma solidity ^0.4.21;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) 
        {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title 项目管理员基类
 * @dev 可持有合同具有所有者地址，并提供基本的授权控制
*      函数，这简化了“用户权限”的实现。
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



// @dev Ownable构造函数将合约的原始“所有者”设置为发件人帐户。

    function Ownable() public {
        owner = msg.sender;
    }

//@dev如果由所有者以外的任何帐户调用，则抛出异常。
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

//@dev允许当前所有者将合同的控制权转移给新的用户。
//@param newOwner将所有权转让给的地址。
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

//@title可用
//@dev基地合同允许实施紧急停止机制。

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


//@dev修饰符仅在合约未暂停时才可调用函数。
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

//@dev修饰符只有在合约被暂停时才可以调用函数。
    modifier whenPaused() {
        require(paused);
        _;
    }

//@dev由所有者调用暂停，触发器停止状态
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

//@dev被所有者调用以取消暂停，恢复到正常状态
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

//@title基本令牌
//@dev StandardToken的基本版本，没有限制。

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 totalSupply_;

//@dev token总数
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }


//指定地址的@dev转移令牌
//@param _to要转移到的地址。
//@param _value要转移的金额。
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

//
//@dev获取指定地址的余额。
//@param _owner查询余额的地址。
//@return uint256表示通过地址所拥有的金额。
    function balanceOf(address _owner) public view returns (uint256) 
    {
        return balances[_owner];
    }

}

// @title ERC20 interface
// @dev see https://github.com/ethereum/EIPs/issues/20

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);


//@dev 销毁特定数量的令牌。
//@param _value要销毁的令牌数量。

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);  
    //不需要value <= totalSupply，因为这意味着
    //发件人的余额大于totalSupply，这应该是断言失败

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

//@title Standard ERC20 token
//@dev Implementation of the basic standard token.
//@dev https://github.com/ethereum/EIPs/issues/20
//@dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol

contract StandardToken is ERC20, BasicToken,Ownable{

    mapping (address => mapping (address => uint256)) internal allowed;



//@dev将令牌从一个地址转移到另一个地址
//@param _to地址您想要转移到的地址
//@param _value uint256要传输的令牌数量
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

//@dev批准传递的地址以代表msg.sender花费指定数量的令牌。
//请注意，使用此方法更改津贴会带来有人可能同时使用旧版本的风险
//以及由不幸交易订购的新补贴。 一种可能的解决方案来减轻这一点
//比赛条件是首先将分配者的津贴减至0，然后设定所需的值：
// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
// @param _spender将花费资金的地址。
// @param _value花费的令牌数量。

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

//@dev函数来检查所有者允许购买的代币数量。
// @param _owner地址拥有资金的地址。
//@param _spender地址将花费资金的地址。
// @return一个uint256，指定仍可用于该支付者的令牌数量。

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


// @dev增加所有者允许购买的代币数量。
//批准时应允许调用[_spender] == 0.要增加
//允许值最好使用这个函数来避免2次调用（并等待
//第一笔交易是开采的）
//来自MonolithDAO Token.sol
// @param _spender将花费资金的地址。
// @param _addedValue用于增加津贴的令牌数量。

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


// @dev减少所有者允许购买的代币数量。
//允许时调用批准[_spender] == 0.递减
//允许值最好使用这个函数来避免2次调用（并等待
//第一笔交易是开采的）
//来自MonolithDAO Token.sol
// @param _spender将花费资金的地址。
// @param _subtractedValue用于减少津贴的令牌数量。

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) 
        {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/*  自定义的最终Token代码 */
contract NDT2Token is BurnableToken, StandardToken,Pausable {
    /*这会在区块链上产生一个公共事件，通知客户端*/
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    function NDT2Token() public 
    {
        totalSupply_ = 10000000000 ether;//代币总量,单位eth
        balances[msg.sender] = totalSupply_;               //为创建者提供所有初始令牌
        name = "NDT2Token";             //为显示目的设置交易名称
        symbol = "NDT2";                               //为显示目的设置交易符号简称
    }

//@dev从目标地址和减量津贴中焚烧特定数量的标记
//@param _from地址您想从中发送令牌的地址
//@param _value uint256要被刻录的令牌数量

    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender]);
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        //此功能需要发布具有更新批准的事件。
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
    //锁定一个账号,只有管理员才能执行
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);               //检查发送人是否被冻结
        return super.transfer(_to, _value);
    }
    //发送代币到某个账号并且马上锁定这个账号,只有管理员才能执行
    function transferAndFrozen(address _to, uint256 _value) onlyOwner public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);               //检查发送人是否被冻结
        bool Result = transfer(_to,_value);
        freezeAccount(_to,true);
        return Result;
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozenAccount[_from]);                     //检查发送人是否被冻结
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}