/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// File: contracts/ERC20Basic.sol

pragma solidity ^0.5.16;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/Ownable.sol

pragma solidity ^0.5.16;


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor (address _owner) public {
    owner = _owner;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/SafeMath.sol

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/BasicToken.sol

pragma solidity ^0.5.16;





contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => uint256) public stakedAmount;

    uint256 public _totalSupply;

 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */ 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(balances[msg.sender].sub(stakedAmount[msg.sender])>= _value,"Some portion has been staked!");

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: contracts/ERC20.sol

pragma solidity ^0.5.16;


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/StandardToken.sol

pragma solidity ^0.5.16;



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0),"Invalid Address");
    require(_value <= balances[_from],"Amount greater than balance");
    require(_value <= allowed[_from][msg.sender],"Amount greater than allowance");

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    emit Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public returns (bool) {
    
    require(_spender != address(0));
    require(balances[msg.sender].sub(stakedAmount[msg.sender])>= _value,"Some portion has been staked!");
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(balances[msg.sender].sub(stakedAmount[msg.sender])>= allowance(msg.sender,_spender).add(_addedValue),"Some portion has been staked!");

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


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

// File: contracts/DUNKToken.sol

pragma solidity ^0.5.16;



contract DUNKToken is StandardToken, Ownable
{
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    address public platform;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyPlatform() {
    require(msg.sender == platform,"Not Platform Contract");
    _;
    }
    
    constructor(string memory _name, string memory _symbol) public Ownable(msg.sender){ 
        
        name = _name;
        symbol = _symbol;
        _totalSupply = 0;

    }
    
    function mint(uint256 _value, address _beneficiary)  public onlyOwner{

        require(_value > 0,"invalid value entered");
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        _totalSupply = _totalSupply.add(_value);
        
        emit Transfer(address(0),_beneficiary, _value);
        
    }
    
    function burn(uint256 _value, address _beneficiary)  public onlyOwner {
        require(_value > 0,"Invalid value!");
        
        _totalSupply = _totalSupply.sub(_value);
        balances[_beneficiary] = balances[_beneficiary].sub(_value);
        
        emit Transfer(_beneficiary, address(0), _value);
    }
    
    function stakeToken(uint256 _value, address _beneficiary) external onlyPlatform{
        require(_value > 0,"Invalid value!");
        
        require(_value < balances[_beneficiary],"Invalid value! Greater than the owned tokens.");
        
        require(_beneficiary != address(0),"Invalid address!");
        
        stakedAmount[_beneficiary] = stakedAmount[_beneficiary].add(_value);
    }
    
    function unStakeToken(uint256 _value, address _beneficiary) external onlyPlatform{
        require(_value > 0,"Invalid value!");
        
        require(_value <= stakedAmount[_beneficiary],"Invalid value! value greater than staked amount.");
        
        require(_beneficiary != address(0),"Invalid address!");
        
        stakedAmount[_beneficiary] = stakedAmount[_beneficiary].sub(_value);
    }
    
    function mintReward(uint256 _value, address _beneficiary)  external onlyPlatform{

        require(_value > 0,"invalid value entered");
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        _totalSupply = _totalSupply.add(_value);
        
        emit Transfer(address(0),_beneficiary, _value);
        
    }
    
    function setPlatformAddress(address _platform) public onlyOwner{
        require (_platform != address(0),"Invalid address");
        
        platform = _platform;
    }
    
    function getStakedAmount(address _beneficiary) public view returns(uint256){
        return stakedAmount[_beneficiary];
    }
    
}