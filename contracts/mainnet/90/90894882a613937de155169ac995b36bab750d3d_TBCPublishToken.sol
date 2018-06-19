pragma solidity ^0.4.24;
 
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
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
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner,address indexed spender,uint256 value);
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

contract Ownable {
    
  address public owner;
  
   //这里是个事件，供前端监听
  event OwnerEvent(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.这是一个构造函数，在合约启动时只运行一次，将合约的地址赋给地址owner
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner。这里就是modifier onlyOwner的修饰符，用来判定是否是合约的发布者
   * 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   * 让合约拥有者修改指定新的合约拥有者，并调用事件来监听
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnerEvent(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
  /**
   * @title TongBi Coin
   * @dev http://www.tongbi.io
   * @dev WeChat:sixinwo
   */
contract TBCPublishToken is StandardToken,Ownable,Pausable{
    
    string public name ;
    string public symbol ;
    uint8 public decimals ;
    address public owner;
 
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokenDecimals)  public {
        owner = msg.sender;
        totalSupply_ = initialSupply * 10 ** uint256(tokenDecimals);
        balances[owner] = totalSupply_;
        name = tokenName;
        symbol = tokenSymbol;
        decimals=tokenDecimals;
    }
    
    event Mint(address indexed to, uint256 value);
    event TransferETH(address indexed from, address indexed to, uint256 value);
    
    mapping(address => bool) touched;
    mapping(address => bool) airDropPayabled;
    
    bool public airDropShadowTag = true;
    bool public airDropPayableTag = true;
    uint256 public airDropShadowMoney = 888;
    uint256 public airDropPayableMoney = 88;
    uint256 public airDropTotalSupply = 0;
    uint256 public buyPrice = 40000;

    function setName(string name_) onlyOwner public{
        name = name_;
    }
    function setSymbol(string symbol_) onlyOwner public{
        symbol = symbol_;
    }
    function setDecimals(uint8 decimals_) onlyOwner public{
        decimals = decimals_;
    }

    // public functions
    function mint(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_value > 0 );
        balances[_to]  = balances[_to].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function setAirDropShadowTag(bool airDropShadowTag_,uint airDropShadowMoney_) onlyOwner public{
        airDropShadowTag = airDropShadowTag_;
        airDropShadowMoney = airDropShadowMoney_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(msg.sender != address(0));
 
        if(airDropShadowTag  && balances[_owner] == 0)
            balances[_owner] += airDropShadowMoney * 10 ** uint256(decimals);
        return balances[_owner];
    }
    function setPrices(uint256 newBuyPrice) onlyOwner public{
        require(newBuyPrice > 0) ;
        require(buyPrice != newBuyPrice);
        buyPrice = newBuyPrice;
    }
    function setAirDropPayableTag(bool airDropPayableTag_,uint airDropPayableMoney_) onlyOwner public{
        airDropPayableTag = airDropPayableTag_;
        airDropPayableMoney = airDropPayableMoney_;
    }
    function () public payable {
        require(msg.value >= 0 );
        require(msg.sender != owner);
        uint256 amount = airDropPayableMoney * 10 ** uint256(decimals);
        if(msg.value == 0 && airDropShadowTag && !airDropPayabled[msg.sender] && airDropTotalSupply < totalSupply_){
            balances[msg.sender] = balances[msg.sender].add(amount);
            airDropPayabled[msg.sender] = true;
            airDropTotalSupply = airDropTotalSupply.add(amount);
            balances[owner] = balances[owner].sub(amount);
            emit Transfer(owner,msg.sender,amount);
        }else{
            amount = msg.value.mul(buyPrice);
            require(balances[owner]  >= amount);
            balances[msg.sender] = balances[msg.sender].add(amount);
            balances[owner] = balances[owner].sub(amount);
            owner.transfer(msg.value);
            emit TransferETH(msg.sender,owner,msg.value);
            emit Transfer(owner,msg.sender,amount);
        }
    }  
    // events
    event Burn(address indexed burner, uint256 value);

    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        require(_value > 0 );
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
        require(_value > 0 );
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
    
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _value uint256 The amount of token to be burned
    */
    function burnFrom(address _from, uint256 _value) public {
        require(_value > 0 );
        require(_value <= allowed[_from][msg.sender]);
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
    
    function transfer(address _to,uint256 _value) public whenNotPaused returns (bool){
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from,address _to, uint256 _value) public whenNotPaused returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender,uint256 _value) public whenNotPaused returns (bool){
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender,uint _addedValue) public  whenNotPaused returns (bool success){
     return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval( address _spender,uint _subtractedValue)  public whenNotPaused returns (bool success){
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
        uint length_ = _receivers.length;
        uint256 amount =  _value.mul(length_);
        require(length_ > 0 );
        require(_value > 0 && balances[msg.sender] >= amount);
    
        balances[msg.sender] = balances[msg.sender].sub(amount);
        for (uint i = 0; i < length_; i++) {
            require (balances[_receivers[i]].add(_value) < balances[_receivers[i]]) ; // Check for overflows
            balances[_receivers[i]] = balances[_receivers[i]].add(_value);
            emit Transfer(msg.sender, _receivers[i], _value);
        }
        return true;
    }
    /**    www.tongbi.io     */
}