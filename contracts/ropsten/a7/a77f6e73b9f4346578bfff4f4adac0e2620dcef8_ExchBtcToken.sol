pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/* 父类:账户管理员 */
contract owned {

    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    /* modifier是修改标志 */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* 修改管理员账户， onlyOwner代表只能是用户管理员来修改 */
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }   
}

/* 子类:代币发行 */
contract ExchBtcToken is owned, StandardToken {

    string public name = &quot;ExchBtc Token&quot;;
    
    string public symbol = &quot;QQQQ&quot;;

    uint8 public decimals = 3;
    
    //冻结额度
    mapping(address => uint256) freezes;
    //资金解冻事件
    event FreeFunds(address target, uint256 _amount);
    event FreezeFunds(address _owner, uint256 _amount);
    
    //RD 研发运维部分：19%
    address public constant INITIAL_DEV_ADDRESS = 0x52E2Afc54D18567348Da79189dDFe1F4EB42AcA;
    uint256 public constant INITIAL_DEV_AMOUNT = 950 * 10000 * 10000 * 1000;
    //Angle 早期投资人部分：10%
    address public constant INITIAL_INV_ADDRESS = 0x111879A3968c4a49c26E810f6EDD6B286aDfE610;
    uint256 public constant INITIAL_INV_AMOUNT = 500 * 10000 * 10000 * 1000;
    //Business 运营推广:10%
    address public constant INITIAL_MKT_ADDRESS = 0xC7f503dF06DFfF77d7300a1f53c27Fdfd74D4FEC;
    uint256 public constant INITIAL_MKT_AMOUNT = 500 * 10000 * 10000 * 1000;
    //exchBtcfund 新项目孵化:10%
    address public constant INITIAL_NOV_ADDRESS = 0x0c65D7279927c022A53d58c1AADd1D115Cd1Db42;
    uint256 public constant INITIAL_NOV_AMOUNT = 500 * 10000 * 10000 * 1000;
    
    //初期锁定份额 交易即挖矿51%部分
    uint256 public constant INITIAL_MINING_AMOUNT = 2550 * 10000 * 10000 * 1000;

    /* 构造函数 */
    function ExchBtcToken() public {
        //发行量：5000亿（小数位：3）
        totalSupply_ = 5000 * 10000 * 10000 * 1000;
	    balances[msg.sender] = totalSupply_;
	    
	    //初期分配给管理团队及其他团队
	    //19%研发运维
	    transfer(INITIAL_DEV_ADDRESS, INITIAL_DEV_AMOUNT);
	    //10%早期投资人
	    transfer(INITIAL_INV_ADDRESS, INITIAL_INV_AMOUNT);
	    //10%运营推广
	    transfer(INITIAL_MKT_ADDRESS, INITIAL_MKT_AMOUNT);
	    //10%新项目孵化
	    transfer(INITIAL_NOV_ADDRESS, INITIAL_NOV_AMOUNT);
	    
	    //创建合约时锁定交易即挖矿的51%部分，即锁定2550亿
	    freezeTokens(msg.sender, INITIAL_MINING_AMOUNT);
         
    }
    
    /* 查看余额 */
    function balanceOf(address _owner) public view returns (uint256) {
        //return balances[_owner].add(freezes[_owner]);
        //冻结部分不作为余额展示出来， 可通过freezeof查看被冻结部分金额
        return balances[_owner];
    }
    
    /* 查看被冻结部分金额 */
    function freezeof(address _owner) public view returns (uint256) {
        return freezes[_owner];
    }
    
    /* 从给定地址上解冻代币， 释放给定代币数量到给定的目标地址 */
	function freeTokens(address _owner, address _target, uint256 amount) onlyOwner public returns (bool){
	    require(_owner != address(0));
	    require(_target != address(0));
    
		require(amount <= freezes[_owner]); //确保要释放的数量少于或等于被锁定的数量
		require(amount >=0); 
		
		freezes[_owner] = freezes[_owner].sub(amount);
		balances[_target] = balances[_target].add(amount);
		
		emit FreeFunds(_target, amount);
		return true;
	}
	
	//锁定指定数量的代币
	function freezeTokens(address _owner, uint256 amount) onlyOwner public returns (bool){
	    require(_owner != address(0));
    
		require(amount <= balances[_owner]); //确保要锁定的数量大于或等于余额
		require(amount >= 0); 
	
		balances[_owner] = balances[_owner].sub(amount);
		freezes[_owner] = freezes[_owner].add(amount);
		
		emit FreezeFunds(_owner, amount);
		return true;
	}
    
    //收回以太币
	function withdrawEther(uint256 amount) onlyOwner public{
		msg.sender.transfer(amount);
	}
	
	//可以接受以太币
	function() payable public {
    }
}