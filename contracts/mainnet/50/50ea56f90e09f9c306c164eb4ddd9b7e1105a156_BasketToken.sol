pragma solidity ^0.4.18;

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

// File: contracts/BasketToken.sol

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


/// @title A decentralized Basket-like ERC20 which gives the owner a claim to the
/// underlying assets
/// @notice Basket Tokens are transferable, and can be created and redeemed by
/// anyone. To create, a user must approve the contract to move the underlying
/// tokens, then call `create()`.
/// @author Daniel Que and Quan Pham
contract BasketToken is StandardToken, Pausable {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    string constant public name = "ERC20 TWENTY";
    string constant public symbol = "ETW";
    uint8 constant public decimals = 18;
    struct TokenInfo {
        address addr;
        uint256 tokenUnits;
    }
    uint256 private creationQuantity_;
    TokenInfo[] public tokens;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    /// @notice Requires value to be divisible by creationQuantity
    /// @param value Number to be checked
    modifier requireMultiple(uint256 value) {
        require((value % creationQuantity_) == 0);
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
    /// @param tokenUnits Number of token base units required per creation unit
    /// @param _creationQuantity Number of base units per creation unit
    function BasketToken(
        address[] addresses,
        uint256[] tokenUnits,
        uint256 _creationQuantity
    ) public {
        require(0 < addresses.length && addresses.length < 256);
        require(addresses.length == tokenUnits.length);
        require(_creationQuantity >= 1);

        creationQuantity_ = _creationQuantity;

        for (uint8 i = 0; i < addresses.length; i++) { // Using uint8 because we expect maximum of 256 underlying tokens
            tokens.push(TokenInfo({
                addr: addresses[i],
                tokenUnits: tokenUnits[i]
            }));
        }
    }

    /// @notice Returns the creationQuantity
    /// @dev Creation quantity concept is similar but not identical to the one
    /// described by EIP777
    /// @return creationQuantity_ Creation quantity of the Basket token
    function creationQuantity() external view returns(uint256) {
        return creationQuantity_;
    }

    /// @notice Creates Basket tokens in exchange for underlying tokens. Before
    /// calling, underlying tokens must be approved to be moved by the Basket Token
    /// contract. The number of approved tokens required depends on
    /// baseUnits.
    /// @dev If any underlying tokens&#39; `transferFrom` fails (eg. the token is
    /// frozen), create will no longer work. At this point a token upgrade will
    /// be necessary.
    /// @param baseUnits Number of base units to create. Must be a multiple of
    /// creationQuantity.
    function create(uint256 baseUnits)
        external
        whenNotPaused()
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
        // Check overflow
        require((totalSupply_ + baseUnits) > totalSupply_);

        for (uint8 i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            ERC20 erc20 = ERC20(tokenInfo.addr);
            uint256 amount = baseUnits.div(creationQuantity_).mul(tokenInfo.tokenUnits);
            require(erc20.transferFrom(msg.sender, address(this), amount));
        }

        mint(msg.sender, baseUnits);
    }

    /// @notice Redeems Basket Token in return for underlying tokens
    /// @param baseUnits Number of base units to redeem. Must be a multiple of
    /// creationQuantity.
    /// @param tokensToSkip Underlying token addresses to skip redemption for.
    /// Intended to be used to skip frozen or broken tokens which would prevent
    /// all underlying tokens from being withdrawn due to a revert. Skipped
    /// tokens will be left in the Basket Token contract and will be unclaimable.
    function redeem(uint256 baseUnits, address[] tokensToSkip)
        external
        whenNotPaused()
        requireNonZero(baseUnits)
        requireMultiple(baseUnits)
    {
        require((totalSupply_ >= baseUnits));
        require((balances[msg.sender] >= baseUnits));
        require(tokensToSkip.length <= tokens.length);

        // Burn before to prevent re-entrancy
        burn(msg.sender, baseUnits);

        for (uint8 i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            ERC20 erc20 = ERC20(tokenInfo.addr);
            uint256 index;
            bool ok;
            (index, ok) = tokensToSkip.index(tokenInfo.addr);
            if (ok) {
                continue;
            }
            uint256 amount = baseUnits.div(creationQuantity_).mul(tokenInfo.tokenUnits);
            require(erc20.transfer(msg.sender, amount));
        }
    }

    /// @return tokenAddresses Underlying token addresses
    function tokenAddresses() external view returns (address[]){
        address[] memory tokenAddresses = new address[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            tokenAddresses[i] = tokens[i].addr;
        }
        return tokenAddresses;
    }

    /// @return tokenUnits Number of token base units required per creation unit
    function tokenUnits() external view returns (uint256[]){
        uint256[] memory tokenUnits = new uint256[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            tokenUnits[i] = tokens[i].tokenUnits;
        }
        return tokenUnits;
    }

    // @dev Mints new Basket tokens
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

    // @dev Burns Basket tokens
    // @param from
    // @param amount
    // @return ok
    function burn(address from, uint256 amount) internal returns (bool) {
        totalSupply_ = totalSupply_.sub(amount);
        balances[from] = balances[from].sub(amount);
        Burn(from, amount);
        Transfer(from, address(0), amount);
        return true;
    }

    // @notice Look up token info
    // @param token Token address to look up
    // @return (tokenUnits, ok) Units of underlying token, and whether the
    // operation was successful
    function getTokenUnits(address token) internal view returns (uint256, bool) {
        for (uint8 i = 0; i < tokens.length; i++) {
            if (tokens[i].addr == token) {
                return (tokens[i].tokenUnits, true);
            }
        }
        return (0, false);
    }

    /// @notice Owner: Withdraw excess funds which don&#39;t belong to Basket Token
    /// holders
    /// @param token ERC20 token address to withdraw
    function withdrawExcessToken(address token)
        external
        onlyOwner
    {
        ERC20 erc20 = ERC20(token);
        uint256 withdrawAmount;
        uint256 amountOwned = erc20.balanceOf(address(this));
        uint256 tokenUnits;
        bool ok;
        (tokenUnits, ok) = getTokenUnits(token);
        if (ok) {
            withdrawAmount = amountOwned.sub(totalSupply_.div(creationQuantity_).mul(tokenUnits));
        } else {
            withdrawAmount = amountOwned;
        }
        require(erc20.transfer(owner, withdrawAmount));
    }

    /// @notice Owner: Withdraw Ether
    function withdrawEther()
        external
        onlyOwner
    {
        owner.transfer(this.balance);
    }

    /// @notice Fallback function
    function() external payable {
    }

}