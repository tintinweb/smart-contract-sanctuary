pragma solidity 0.4.24;
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
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner , "Unauthorized Access");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is owned {
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

interface ERC223Interface {
   
    function balanceOf(address who) constant external returns (uint);
    function transfer(address to, uint value)  external returns (bool success); //erc20 compatible
    function transfer(address to, uint value, bytes data) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //erc20 compatible
}
/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) external;
}
/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract ERC223Token is ERC223Interface, Pausable {
    using SafeMath for uint;
    uint256 public _CAP;
    mapping(address => uint256) balances; // List of user balances.
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) whenNotPaused external returns (bool success){
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        require(balances[msg.sender] >= _value && _value > 0);
        if(isContract(_to)){
           return transferToContract(_to, _value, _data);
        }
        else
        {
            return transferToAddress(_to, _value,  _data);
        }
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) whenNotPaused external returns (bool success){
        require(balances[msg.sender] >= _value && _value > 0);
        bytes memory empty;
        if(isContract(_to)){
           return transferToContract(_to, _value, empty);
        }
        else
        {
            return transferToAddress(_to, _value, empty);
        }
        //emit Transfer(msg.sender, _to, _value, empty);
    }
    
//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) internal view returns (bool is_contract) {
    // retrieve the size of the code on target address, this needs assembly
    uint length;
    assembly { length := extcodesize(_addr) }
    if (length > 0)
    return true;
    else
    return false;
  }
  // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private whenNotPaused returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private whenNotPaused returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) constant external returns (uint balance) {
        return balances[_owner];
    }
}
contract ERC20BackedERC223 is ERC223Token{
    
    
  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size.add(4));
     _;
   } 
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) whenNotPaused external returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

 
    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool success) {
        require((balances[msg.sender] >= _value) && ((_value == 0) || (allowed[msg.sender][_spender] == 0)));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function disApprove(address _spender) whenNotPaused public returns (bool success)
    {
        allowed[msg.sender][_spender] = 0;
        assert(allowed[msg.sender][_spender] == 0);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
   function increaseApproval(address _spender, uint _addedValue) whenNotPaused public returns (bool success) {
    require(balances[msg.sender] >= allowed[msg.sender][_spender].add(_addedValue), "Callers balance not enough");
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    require((_subtractedValue != 0) && (oldValue > _subtractedValue) , "The amount to be decreased is incorrect");
    allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
}

   
    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping (address => mapping (address => uint256)) allowed;
}
contract burnableERC223 is ERC20BackedERC223{
         // This notifies clients about the amount burnt
         uint256  public _totalBurnedTokens = 0;
         event Burn(address indexed from, uint256 value);
     /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balances[msg.sender] >= _value, "Sender doesn&#39;t have enough balance");   // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender].sub(_value);            // Subtract from the sender
        _CAP = _CAP.sub(_value);                      // Updates totalSupply
        _totalBurnedTokens = _totalBurnedTokens.add(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
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
        require(balances[_from] >= _value , "target balance is not enough");                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] = balances[_from].sub(_value);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
        _CAP = _CAP.sub(_value);                              // Update totalSupply
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
    
}
contract mintableERC223 is burnableERC223{
    
    uint256 public _totalMinedSupply;
    uint256 public _initialSupply;
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
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
      bytes memory empty;
      uint256 availableMinedSupply;
      availableMinedSupply =  (_totalMinedSupply.sub(_totalBurnedTokens)).add(_amount);
    require(_CAP >= availableMinedSupply , "All tokens minted, Cap reached");
    _totalMinedSupply = _totalMinedSupply.add(_amount);
    if(_CAP <= _totalMinedSupply.sub(_totalBurnedTokens))
    mintingFinished = true;
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    emit Transfer(address(0), _to, _amount, empty);
    return true;
  }
 /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
    /// @return total amount of tokens
    function maximumSupply() public view returns (uint256 supply){
        
        return _CAP;
    }
      /// @return total amount of tokens
    function totalMinedSupply() public view returns (uint256 supply){
        
        return _totalMinedSupply;
    }
      /// @return total amount of tokens
    function preMinedSupply() public view returns (uint256 supply){
        
        return _initialSupply;
    }
	function totalBurnedTokens() public view returns (uint256 supply){
        
        return _totalBurnedTokens;
    }
     function totalSupply() public view returns (uint256 supply){
        
        return _totalMinedSupply.sub(_totalBurnedTokens);
    }
}
contract CyBit is mintableERC223{
    
     /* Public variables of the token */

    /*
    NOTE:
    
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //Name Of Token
    uint256 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version;                 //An Arbitrary versioning scheme.

    uint256 private initialsupply;
    uint256 private totalsupply;

    
 constructor() public
 {
     decimals = 8;
     name = "CyBit";                                    // Set the name for display purposes
     symbol = "eCBT";                                   // Set the symbol for display purposes
     version = "V1.0";                                  //Version.
     initialsupply = 7000000000;                        //PreMined Tokens
     totalsupply = 10000000000;                         //Total Tokens
     _CAP = totalsupply.mul(10 ** decimals);
     _initialSupply = initialsupply.mul(10 ** decimals);
     _totalMinedSupply = _initialSupply;
     balances[msg.sender] = _initialSupply;
     
 }
 function() public {
         //not payable fallback function
          revert();
    }
    
    /* Get the contract constant _name */
      function version() public view returns (string _v) {
        return version;
    }
    function name() public view returns (string _name) {
        return name;
    }

    /* Get the contract constant _symbol */
    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    /* Get the contract constant _decimals */
    function decimals() public view returns (uint256 _decimals) {
        return decimals;
    }

 }