/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @notice https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
  /**
   * SafeMath mul function
   * @dev function for safe multiply
   **/
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  /**
   * SafeMath div funciotn
   * @dev function for safe devide
   **/
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  
  /**
   * SafeMath sub function
   * @dev function for safe subtraction
   **/
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  /**
   * SafeMath add fuction 
   * @dev function for safe addition
   **/
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simple version of ERC20 interface
 * @notice https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public  returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title BasicToken
 * @dev Basic version of Token, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;

  /**
   * BasicToken transfer function
   * @dev transfer token for a specified address
   * @param _to address to transfer to.
   * @param _value amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    //Safemath fnctions will throw if value is invalid
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * BasicToken balanceOf function 
   * @dev Gets the balance of the specified address.
   * @param _owner address to get balance of.
   * @return uint256 amount owned by the address.
   */
  function balanceOf(address _owner) public constant returns (uint256 bal) {
    return balances[_owner];
  }
}

/**
 *  @title ERC20 interface
 *  @notice https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Token
 * @dev Token to meet the ERC20 standard
 * @notice https://github.com/ethereum/EIPs/issues/20
 */
contract Token is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  
  /**
   * Token transferFrom function
   * @dev Transfer tokens from one address to another
   * @param _from address to send tokens from
   * @param _to address to transfer to
   * @param _value amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    // Safe math functions will throw if value invalid
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * Token approve function
   * @dev Aprove address to spend amount of tokens
   * @param _spender address to spend the funds.
   * @param _value amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    // allowance to zero by calling `approve(_spender, 0)` if it is not
    // already 0 to mitigate the race condition described here:
    // @notice https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * Token allowance method
   * @dev Ckeck that owners tokens is allowed to send to spender
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title Lavevel Token
 * @dev Simple ERC20 Token with standard token functions.
 */
contract LavevelToken is Token {
  string public constant NAME = "Lavevel Token";
  string public constant SYMBOL = "LVL";
  uint256 public constant DECIMALS = 18;

  uint256 public constant INITIAL_SUPPLY = 500000000 * 10**18;

  /**
   * Kimera Token Constructor
   * @dev Create and issue tokens to msg.sender.
   */
  function LavevelToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}