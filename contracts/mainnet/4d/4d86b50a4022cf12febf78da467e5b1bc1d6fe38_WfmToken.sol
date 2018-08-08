pragma solidity ^0.4.13;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract WfmToken is StandardToken {
    string public constant name = "WFM Token";
    string public constant symbol = "WFM";
    uint8 public constant decimals = 18;
    uint256 constant denomination = 10 ** uint(decimals);
    uint256 constant totalTokens = 100000000 * denomination;  // 100&#39;000&#39;000 tokens total
    uint256 constant ownerPart = 35000000 * denomination;     // marketing + team parts
    uint256 constant crowdsaleRate = 16000;
    uint256 constant icoRate = 11250;
    uint256 constant crowdsaleBeginTime = 1532476800;  // 07/25/2018 @ 12:00am (UTC)
    uint256 constant icoBeginTime =  1535760000;       // 09/01/2018 @ 12:00am (UTC)
    uint256 constant icoFinishTime = 1539648000;       // 10/16/2018 @ 12:00am (UTC)
    uint256 constant softCapEther = 300 ether;
    uint256 constant hardCapEther = 5000 ether;
    address constant public initialOwner = 0xf62acdc7c42a0e1874f099A9f49204E08305bC88;

    address public owner = initialOwner;
    uint256 public raisedEther;
    mapping(address => uint256) public investment;

    constructor() public {
        totalSupply_ = totalTokens;
        balances[this] = totalTokens - ownerPart;
        balances[owner] = ownerPart;
        emit Transfer(address(0), this, totalTokens - ownerPart);
        emit Transfer(address(0), owner, ownerPart);
    }

    function rate() public view returns (uint256) {
        return icoStarted()? icoRate : crowdsaleRate;
    }

    function softCapReached() public view returns (bool) {
        return raisedEther >= softCapEther;
    }

    function hardCapReached() public view returns (bool) {
        return raisedEther >= hardCapEther;
    }

    function saleStarted() public view returns (bool) {
        return now >= crowdsaleBeginTime;
    }

    function icoStarted() public view returns (bool) {
        return now >= icoBeginTime;
    }

    function icoFinished() public view returns (bool) {
        return now >= icoFinishTime;
    }

    function () public payable {
        require(saleStarted() && !icoFinished() && !hardCapReached());
        uint tokens = msg.value.mul(rate());
        investment[msg.sender] = investment[msg.sender].add(msg.value);
        raisedEther = raisedEther.add(msg.value);
        balances[this] = balances[this].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        emit Transfer(this, msg.sender, tokens);
    }

    function withdraw() public {
        if (!softCapReached()) {
            require(icoStarted());
            uint256 amount = investment[msg.sender];
            if (amount > 0) {
                investment[msg.sender] = 0;
                emit Transfer(msg.sender, address(0), balances[msg.sender]);
                balances[msg.sender] = 0;
                msg.sender.transfer(amount);
            }
        } else {
            require(msg.sender == owner);
            owner.transfer(address(this).balance);
        }
    }

    function withdrawUnsoldTokens() public {
        require(msg.sender == owner);
        require(icoFinished());
        uint value = balances[this];
        balances[this] = 0;
        balances[owner] = balances[msg.sender].add(value);
        emit Transfer(this, owner, value);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner);
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}