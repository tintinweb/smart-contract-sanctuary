pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  /*@CTK SafeMath_mul
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a * b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  /*@CTK SafeMath_div
    @tag spec
    @pre b != 0
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a / b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  /*@CTK SafeMath_sub
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a - b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  /*@CTK SafeMath_add
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a + b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  /*@CTK owner_set_on_success
    @pre __reverted == false -> __post.owner == owner
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  /*@CTK transferOwnership
    @post __reverted == false -> (msg.sender == owner -> __post.owner == newOwner)
    @post (owner != msg.sender) -> (__reverted == true)
    @post (newOwner == address(0)) -> (__reverted == true)
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  /*@CTK transfer_success
    @pre _to != address(0)
    @pre balances[msg.sender] >= _value
    @pre __reverted == false
    @post __reverted == false
    @post __return == true
   */
  /*@CTK transfer_same_address
    @tag no_overflow
    @pre _to == msg.sender
    @post this == __post
   */
  /*@CTK transfer_conditions
    @tag assume_completion
    @pre _to != msg.sender
    @post __post.balances[_to] == balances[_to] + _value
    @post __post.balances[msg.sender] == balances[msg.sender] - _value
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
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
  /*@CTK balanceOf
    @post __reverted == false
    @post __return == balances[_owner]
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
  /*@CTK transferFrom
    @tag assume_completion
    @pre _from != _to
    @post __return == true
    @post __post.balances[_to] == balances[_to] + _value
    @post __post.balances[_from] == balances[_from] - _value
    @post __has_overflow == false
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
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
  /*@CTK approve_success
    @post _value == 0 -> __reverted == false
    @post allowed[msg.sender][_spender] == 0 -> __reverted == false
   */
  /*@CTK approve
    @tag assume_completion
    @post __post.allowed[msg.sender][_spender] == _value
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  /*@CTK CtkIncreaseApprovalEffect
    @tag assume_completion
    @post __post.allowed[msg.sender][_spender] == allowed[msg.sender][_spender] + _addedValue
    @post __has_overflow == false
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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
  /*@CTK CtkDecreaseApprovalEffect_1
    @pre allowed[msg.sender][_spender] >= _subtractedValue
    @tag assume_completion
    @post __post.allowed[msg.sender][_spender] == allowed[msg.sender][_spender] - _subtractedValue
    @post __has_overflow == false
   */
   /*@CTK CtkDecreaseApprovalEffect_2
    @pre allowed[msg.sender][_spender] < _subtractedValue
    @tag assume_completion
    @post __post.allowed[msg.sender][_spender] == 0
    @post __has_overflow == false
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract IoTeXNetwork is StandardToken, Pausable {
    string public constant name = "IoTeX Network";
    string public constant symbol = "IOTX";
    uint8 public constant decimals = 18;

    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    function IoTeXNetwork(uint tokenTotalAmount) {
        totalSupply_ = tokenTotalAmount;
        balances[msg.sender] = tokenTotalAmount;
        emit Transfer(address(0x0), msg.sender, tokenTotalAmount);
    }

    /*@CTK CtkTransferNoEffect
      @post (_to == address(0)) \/ (paused == true) -> __reverted == true
     */
    /*@CTK CtkTransferEffect
      @pre __reverted == false
      @pre balances[msg.sender] >= _value
      @pre paused == false
      @pre __return == true
      @pre msg.sender != _to
      @post __post.balances[_to] == balances[_to] + _value
      @post __has_overflow == false
     */
    /* CertiK Smart Labelling, for more details visit: https://certik.org */
    function transfer(address _to, uint _value) whenNotPaused
        validDestination(_to)
        returns (bool) {
        return super.transfer(_to, _value);
    }

    /*@CTK CtkTransferFromNoEffect
      @post (_to == address(0)) \/ (paused == true) -> __reverted == true
     */
    /*@CTK CtkTransferFromEffect
      @tag assume_completion
      @pre _from != _to
      @post __post.balances[_to] == balances[_to] + _value
      @post __post.balances[_from] == balances[_from] - _value
      @post __has_overflow == false
     */
    /* CertiK Smart Labelling, for more details visit: https://certik.org */
    function transferFrom(address _from, address _to, uint _value) whenNotPaused
        validDestination(_to)
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /*@CTK CtkApproveNoEffect
      @post (paused == true) -> __post == this
     */
    /*@CTK CtkApprove
      @tag assume_completion
      @post __post.allowed[msg.sender][_spender] == _value
     */
    /* CertiK Smart Labelling, for more details visit: https://certik.org */
    function approve(address _spender, uint256 _value) public whenNotPaused
      returns (bool) {
      return super.approve(_spender, _value);
    }

    /*@CTK CtkIncreaseApprovalNoEffect
      @post (paused == true) -> __reverted == true
     */
    /*@CTK CtkIncreaseApprovalEffect
      @pre paused == false
      @tag assume_completion
      @post __post.allowed[msg.sender][_spender] == allowed[msg.sender][_spender] + _addedValue
      @post __has_overflow == false
     */
    /* CertiK Smart Labelling, for more details visit: https://certik.org */
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused
      returns (bool success) {
      return super.increaseApproval(_spender, _addedValue);
    }

    /*@CTK CtkDecreaseApprovalNoEffect
      @post (paused == true) -> __reverted == true
     */
    /*@CTK CtkDecreaseApprovalEffect
      @pre allowed[msg.sender][_spender] >= _subtractedValue
      @tag assume_completion
      @post __post.allowed[msg.sender][_spender] == allowed[msg.sender][_spender] - _subtractedValue
      @post __has_overflow == false
     */
    /* CertiK Smart Labelling, for more details visit: https://certik.org */
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused
      returns (bool success) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }
}