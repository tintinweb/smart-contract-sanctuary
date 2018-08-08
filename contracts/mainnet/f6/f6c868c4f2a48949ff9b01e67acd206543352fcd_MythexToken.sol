pragma solidity ^0.4.21;

/**
 * @title Maths
 * A library to make working with numbers in Solidity hurt your brain less.
 */
library Maths {
  /**
   * @dev Adds two addends together, returns the sum
   * @param addendA the first addend
   * @param addendB the second addend
   * @return sum the sum of the equation (e.g. addendA + addendB)
   */
  function plus(
    uint256 addendA,
    uint256 addendB
  ) public pure returns (uint256 sum) {
    sum = addendA + addendB;
  }

  /**
   * @dev Subtracts the minuend from the subtrahend, returns the difference
   * @param minuend the minuend
   * @param subtrahend the subtrahend
   * @return difference the difference (e.g. minuend - subtrahend)
   */
  function minus(
    uint256 minuend,
    uint256 subtrahend
  ) public pure returns (uint256 difference) {
    assert(minuend >= subtrahend);
    difference = minuend - subtrahend;
  }

  /**
   * @dev Multiplies two factors, returns the product
   * @param factorA the first factor
   * @param factorB the second factor
   * @return product the product of the equation (e.g. factorA * factorB)
   */
  function mul(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    if (factorA == 0 || factorB == 0) return 0;
    product = factorA * factorB;
    assert(product / factorA == factorB);
  }

  /**
   * @dev Multiplies two factors, returns the product
   * @param factorA the first factor
   * @param factorB the second factor
   * @return product the product of the equation (e.g. factorA * factorB)
   */
  function times(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    return mul(factorA, factorB);
  }

  /**
   * @dev Divides the dividend by divisor, returns the truncated quotient
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   */
  function div(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    quotient = dividend / divisor;
    assert(quotient * divisor == dividend);
  }

  /**
   * @dev Divides the dividend by divisor, returns the truncated quotient
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   */
  function dividedBy(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    return div(dividend, divisor);
  }

  /**
   * @dev Divides the dividend by divisor, returns the quotient and remainder
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   * @return remainder the remainder of the equation (e.g. dividend % divisor)
   */
  function divideSafely(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient, uint256 remainder) {
    quotient = div(dividend, divisor);
    remainder = dividend % divisor;
  }

  /**
   * @dev Returns the lesser of two values.
   * @param a the first value
   * @param b the second value
   * @return result the lesser of the two values
   */
  function min(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a <= b ? a : b;
  }

  /**
   * @dev Returns the greater of two values.
   * @param a the first value
   * @param b the second value
   * @return result the greater of the two values
   */
  function max(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a >= b ? a : b;
  }

  /**
   * @dev Determines whether a value is less than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than b
   */
  function isLessThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a < b;
  }

  /**
   * @dev Determines whether a value is equal to or less than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than or equal to b
   */
  function isAtMost(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a <= b;
  }

  /**
   * @dev Determines whether a value is greater than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is greater than b
   */
  function isGreaterThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a > b;
  }

  /**
   * @dev Determines whether a value is equal to or greater than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than b
   */
  function isAtLeast(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a >= b;
  }
}

/**
 * @title Manageable
 */
contract Manageable {
  address public owner;
  address public manager;

  event OwnershipChanged(address indexed previousOwner, address indexed newOwner);
  event ManagementChanged(address indexed previousManager, address indexed newManager);

  /**
   * @dev The Manageable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Manageable() public {
    owner = msg.sender;
    manager = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner or manager.
   */
  modifier onlyManagement() {
    require(msg.sender == owner || msg.sender == manager);
    _;
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the owner or manager to replace the current manager
   * @param newManager The address to give contract management rights.
   */
  function replaceManager(address newManager) public onlyManagement {
    require(newManager != address(0));
    emit ManagementChanged(manager, newManager);
    manager = newManager;
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
  using Maths for uint256;

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

    balances[msg.sender] = balances[msg.sender].minus(_value);
    balances[_to] = balances[_to].plus(_value);
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
  using Maths for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].minus(_value);
    balances[_to] = balances[_to].plus(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].minus(_value);
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].plus(_addedValue);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.minus(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Manageable {
  using Maths for uint256;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyManagement canMint public returns (bool) {
    totalSupply_ = totalSupply_.plus(_amount);
    balances[_to] = balances[_to].plus(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyManagement canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract MythexToken is MintableToken {
  using Maths for uint256;

  string public constant name     = "Mythex";
  string public constant symbol   = "MX";
  uint8  public constant decimals = 0;

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens assigned to a given address
   * @param _burner The owner of the tokens to be burned
   * @param _value The amount of token to be burned
   * @return True if the operation was successful.
   */
  function burn(address _burner, uint256 _value) public onlyManagement returns (bool) {
    require(_value <= balances[_burner]);
    balances[_burner] = balances[_burner].minus(_value);
    totalSupply_ = totalSupply_.minus(_value);
    emit Burn(_burner, _value);
    return true;
  }
}