pragma solidity ^0.4.21;

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

contract owned {

    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is owned {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(false == paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(true == paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract CustomToken is Pausable{
    using SafeMath for uint256;
    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function CustomToken (
        string tokenName,
        string tokenSymbol
    ) public {
        decimals = 18;
        name = tokenName;                                           // Set the name for display purposes
        symbol = tokenSymbol;                                       // Set the symbol for display purposes
    }
    
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) whenNotPaused public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract GMCToken is CustomToken {
    string tokenName        = "GMCToken";        // Set the name for display purposes
    string tokenSymbol      = "GMC";             // Set the symbol for display purposes
        
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function GMCToken() CustomToken(tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
    
    /// @notice Create `mintedAmount` tokens and send it to `msg.sender`
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(uint256 mintedAmount) onlyOwner public {
        uint256 mintSupply = mintedAmount.mul(10 ** uint256(decimals));
        balanceOf[msg.sender] = balanceOf[msg.sender].add(mintSupply);
        totalSupply = totalSupply.add(mintSupply);
        emit Transfer(0, this, mintSupply);
        emit Transfer(this, msg.sender, mintSupply);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                       // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);      // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                          // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                    // Check if the targeted balance is enough
        balanceOf[_from] = balanceOf[_from].sub(_value);        // Subtract from the targeted balance
        totalSupply = totalSupply.sub(_value);                  // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}