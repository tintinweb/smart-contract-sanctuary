// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/BsktToken.sol

library AddressArrayUtils {

    /// @return Returns index and ok of the first occurrence starting from index 0
    function index(address[] addresses, address a) internal pure returns (uint, bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}


/// @title A decentralized Bskt-like ERC20 which gives the owner a claim to the
/// underlying assets
/// @notice Bskt Tokens are transferable, and can be created and redeemed by
/// anyone. To create, a user must approve the contract to move the underlying
/// tokens, then call `create()`.
/// @author Fariha Abbasi ContactDetails below:
/// Skype:  live:freelancer543210
/// Fiverr: https://www.fiverr.com/farihaabbasi
/// Upwork: https://www.upwork.com/o/profiles/users/_~01c3ba695060920ed3/

    contract BsktToken is StandardToken, Pausable {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    struct TokenInfo {
        address addr;
        uint256 quantity;
    }
    uint256 private creationUnit_;
    TokenInfo[] public tokens;

    event Mint(address indexed to, uint256 amount);

    /// @notice Requires value to be divisible by creationUnit
    /// @param value Number to be checked
    modifier requireMultiple(uint256 value) {
        require((value % creationUnit_) == 0);
        _;
    }

    /// @notice Requires value to be non-zero
    /// @param value Number to be checked
    modifier requireNonZero(uint256 value) {
        require(value > 0);
        _;
    }

    /// @notice Initializes contract with a list of ERC20 token addresses and
    /// corresponding minimum number of units required for a creation unit
    /// @param addresses Addresses of the underlying ERC20 token contracts
    /// @param quantities Number of token base units required per creation unit
    /// @param _creationUnit Number of base units per creation unit
    function BsktToken(
        address[] addresses,
        uint256[] quantities,
        uint256 _creationUnit,
        string _name,
        string _symbol
    ) public {
        require(0 < addresses.length && addresses.length < 256);
        require(addresses.length == quantities.length);
        require(_creationUnit >= 1);

        for (uint256 i = 0; i < addresses.length; i++) {
            tokens.push(TokenInfo({
                addr: addresses[i],
                quantity: quantities[i]
            }));
        }

        creationUnit_ = _creationUnit;
        name = _name;
        symbol = _symbol;
    }

    /// @notice Returns the creationUnit
    /// @dev Creation quantity concept is similar but not identical to the one
    /// described by EIP777
    /// @return creationUnit_ Creation quantity of the Bskt token
    function creationUnit() external view returns(uint256) {
        return creationUnit_;
    }
    
    /// @notice Creates Bskt tokens in exchange for underlying tokens. Before
    /// calling, underlying tokens must be approved to be moved by the Bskt Token
    /// contract. The number of approved tokens required depends on
    /// baseUnits.
    /// @dev If any underlying tokens&#39; `transferFrom` fails (eg. the token is
    /// frozen), create will no longer work. At this point a token upgrade will
    /// be necessary.
    /// @param baseUnits Number of base units to create. Must be a multiple of
    /// creationUnit.
    function create(uint256 baseUnits)
        external
        whenNotPaused()
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
        // Check overflow
        require((totalSupply_ + baseUnits) > totalSupply_);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenInfo memory token = tokens[i];
            ERC20 erc20 = ERC20(token.addr);
            uint256 amount = baseUnits.div(creationUnit_).mul(token.quantity);
            require(erc20.transferFrom(msg.sender, address(this), amount));
        }

        mint(msg.sender, baseUnits);
    }
    
    // @dev Mints new Bskt tokens
    // @param to
    // @param amount
    // @return ok
    function mint(address to, uint256 amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }
    
     /// @return addresses Underlying token addresses
    function tokenAddresses() external view returns (address[]){
        address[] memory addresses = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            addresses[i] = tokens[i].addr;
        }
        return addresses;
    }

    /// @return quantities Number of token base units required per creation unit
    function tokenQuantities() external view returns (uint256[]){
        uint256[] memory quantities = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            quantities[i] = tokens[i].quantity;
        }
        return quantities;
    }

    // @notice Look up token info
    // @param token Token address to look up
    // @return (quantity, ok) Units of underlying token, and whether the
    // operation was successful
    function getQuantities(address token) internal view returns (uint256, bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].addr == token) {
                return (tokens[i].quantity, true);
            }
        }
        return (0, false);
    }

   
   
}