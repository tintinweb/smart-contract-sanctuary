pragma solidity ^0.4.18;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;
  string public name;
  string public symbol;
  uint8 public decimals;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract HybridBlock is ERC20 {
  using SafeMath for uint256;
  
  // The owner of this token
  address public owner;

  // The balance in HybridBlock token that every address has
  mapping (address => uint256) balances;

  // Keeps track of allowances for particular address
  mapping (address => mapping (address => uint256)) public allowed;

  /**
   * The constructor for the HybridBlock token
   */
  function HybridBlock() public {
    owner = 0x35118ba64fD141F43958cF9EB493F13aca976e6a;
    name = "Hybrid Block";
    symbol = "HYB";
    decimals = 18;
    totalSupply = 1e9 * 10 ** uint256(decimals);

    // Initially allocate all minted tokens to the owner
    balances[owner] = totalSupply;
  }

  /**
   * @dev Retrieves the balance of a specified address
   * @param _owner address The address to query the balance of.
   * @return A uint256 representing the amount owned by the _owner
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Transfers tokens to a specific address
   * @param _to address The address to transfer tokens to
   * @param _value unit256 The amount to be transferred
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
  
    // Subtract first
    balances[msg.sender] = balances[msg.sender].sub(_value);

    // Now add tokens
    balances[_to] = balances[_to].add(_value);

    // Notify that a transfer has occurred
    Transfer(msg.sender, _to, _value);

    return true;
  }

  /**
   * @dev Transfer on behalf of another address
   * @param _from address The address to send tokens from
   * @param _to address The address to send tokens to
   * @param _value uint256 The amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    // Decrease both the _from amount and the allowed transfer amount
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    // Give _to the tokens
    balances[_to] = balances[_to].add(_value);

    // Notify that a transfer has occurred
    Transfer(_from, _to, _value);

    return true;
  }

  /**
   * @dev Approve sent address to spend the specified amount of tokens on
   * behalf of msg.sender
   *
   * See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * for any potential security concerns
   *
   * @param _spender address The address that will spend funds
   * @param _value uint256 The number of tokens they are allowed to spend
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Returns the amount a spender is allowed to spend for a particular
   * address
   * @param _owner address The address which owns the funds
   * @param _spender address The address which will spend the funds.
   * @return uint256 The number of tokens still available for the spender
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increases the number of tokens a spender is allowed to spend for
   * `msg.sender`
   * @param _spender address The address of the spender
   * @param _addedValue uint256 The amount to increase the spenders approval by
   */
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decreases the number of tokens a spender is allowed to spend for
   * `msg.sender`
   * @param _spender address The address of the spender
   * @param _subtractedValue uint256 The amount to decrease the spenders approval by
   */
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint _value = allowed[msg.sender][_spender];
    if (_subtractedValue > _value) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = _value.sub(_subtractedValue);
    }

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}