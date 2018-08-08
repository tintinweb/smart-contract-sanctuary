pragma solidity ^0.4.23;

// File: contracts/interfaces/BurnableTokenInterface.sol

/**
 * @title Burnable Token Interface
 * @author Bram Hoven
 * @notice Interface for communicating with the burnable token
 */
interface BurnableTokenInterface {
  /**
   * @notice Triggered when tokens are burned
   * @param _triggerer Address which triggered the burning
   * @param _from Address from which the tokens are burned
   * @param _tokens Amount of tokens burned
   */
  event TokensBurned(address indexed _triggerer, address indexed _from, uint256 _tokens);

  /**
   * @notice Called when tokens have to be burned
   * @param _tokens Amount of tokens to be burned
   */
  function burnTokens(uint256 _tokens) external;
}

// File: contracts/interfaces/ContractManagerInterface.sol

/**
 * @title Contract Manager Interface
 * @author Bram Hoven
 * @notice Interface for communicating with the contract manager
 */
interface ContractManagerInterface {
  /**
   * @notice Triggered when contract is added
   * @param _address Address of the new contract
   * @param _contractName Name of the new contract
   */
  event ContractAdded(address indexed _address, string _contractName);

  /**
   * @notice Triggered when contract is removed
   * @param _contractName Name of the contract that is removed
   */
  event ContractRemoved(string _contractName);

  /**
   * @notice Triggered when contract is updated
   * @param _oldAddress Address where the contract used to be
   * @param _newAddress Address where the new contract is deployed
   * @param _contractName Name of the contract that has been updated
   */
  event ContractUpdated(address indexed _oldAddress, address indexed _newAddress, string _contractName);

  /**
   * @notice Triggered when authorization status changed
   * @param _address Address who will gain or lose authorization to _contractName
   * @param _authorized Boolean whether or not the address is authorized
   * @param _contractName Name of the contract
   */
  event AuthorizationChanged(address indexed _address, bool _authorized, string _contractName);

  /**
   * @notice Check whether the accessor is authorized to access that contract
   * @param _contractName Name of the contract that is being accessed
   * @param _accessor Address who wants to access that contract
   */
  function authorize(string _contractName, address _accessor) external view returns (bool);

  /**
   * @notice Add a new contract to the manager
   * @param _contractName Name of the new contract
   * @param _address Address of the new contract
   */
  function addContract(string _contractName, address _address) external;

  /**
   * @notice Get a contract by its name
   * @param _contractName Name of the contract
   */
  function getContract(string _contractName) external view returns (address _contractAddress);

  /**
   * @notice Remove an existing contract
   * @param _contractName Name of the contract that will be removed
   */
  function removeContract(string _contractName) external;

  /**
   * @notice Update an existing contract (changing the address)
   * @param _contractName Name of the existing contract
   * @param _newAddress Address where the new contract is deployed
   */
  function updateContract(string _contractName, address _newAddress) external;

  /**
   * @notice Change whether an address is authorized to use a specific contract or not
   * @param _contractName Name of the contract to which the accessor will gain authorization or not
   * @param _authorizedAddress Address which will have its authorisation status changed
   * @param _authorized Boolean whether the address will have access or not
   */
  function setAuthorizedContract(string _contractName, address _authorizedAddress, bool _authorized) external;
}

// File: contracts/interfaces/MintableTokenInterface.sol

/**
 * @title Mintable Token Interface
 * @author Bram Hoven
 * @notice Interface for communicating with the mintable token
 */
interface MintableTokenInterface {
  /**
   * @notice Triggered when tokens are minted
   * @param _from Address which triggered the minting
   * @param _to Address on which the tokens are deposited
   * @param _tokens Amount of tokens minted
   */
  event TokensMinted(address indexed _from, address indexed _to, uint256 _tokens);

  /**
   * @notice Triggered when the deposit address changes
   * @param _old Old deposit address
   * @param _new New deposit address
   */
  event DepositAddressChanged(address indexed _old, address indexed _new);

  /**
   * @notice Called when new tokens are needed in circulation
   * @param _tokens Amount of tokens to be created
   */
  function mintTokens(uint256 _tokens) external;

  /**
   * @notice Called when tokens are bought in token sale
   * @param _beneficiary Address on which tokens are deposited
   * @param _tokens Amount of tokens to be created
   */
  function sendBoughtTokens(address _beneficiary, uint256 _tokens) external;

  /**
   * @notice Called when deposit address needs to change
   * @param _depositAddress Address on which minted tokens are deposited
   */
  function changeDepositAddress(address _depositAddress) external;
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

// File: contracts/token/BasicToken.sol

contract BasicToken is ERC20Basic, ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  bool public locked = true;

  event TokensUnlocked();

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
    require(!locked);
    
    _transfer(msg.sender, _to, _value);
  }

  /**
  * @dev transfer token for a specified address internally
  * @param _from The address to transfer from.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
    require(_from != address(0));
    require(_to != address(0));
    require(_value <= balances[_from]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
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

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!locked);
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
    require(!locked);
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
    require(!locked);
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
    require(!locked);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(!locked);
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  } 

  /**
   * @notice Called to unlock tokens after sale has ended
   */
  function unlockTokens() public {
    require(locked);

    locked = false;

    emit TokensUnlocked();
  }
}

// File: contracts/token/MintableToken.sol

/**
 * @title Mintable Token
 * @author Bram Hoven
 * @notice Contract for a token which can be minted during the sale or after
 */
contract MintableToken is MintableTokenInterface, BasicToken {
  // Address on which minted coins will be deposited (and burned if needed)
  address public depositAddress;
  // Name of this contract
  string public contractName;
  // Contract Manager
  ContractManagerInterface internal contractManager;

  /**
   * @notice Constructor for creating mintable token
   * @param _depositAddress Address on which minted coins will be deposited
   * @param _contractName Name of this contract for lookup in contract manager
   * @param _contractManager Address where the contract manager is located
   */
  constructor(address _depositAddress, string _contractName, address _contractManager) public {
    depositAddress = _depositAddress;
    contractName = _contractName;
    contractManager = ContractManagerInterface(_contractManager);
  }

  /**
   * @notice Called when new tokens are needed in circulation
   * @param _tokens Amount for tokens to be created
   */
  function mintTokens(uint256 _tokens) external {
    require(!locked);
    require(contractManager.authorize(contractName, msg.sender));
    require(_tokens != 0);

    totalSupply_ = totalSupply_.add(_tokens);
    balances[depositAddress] = balances[depositAddress].add(_tokens);

    emit TokensMinted(msg.sender, depositAddress, _tokens);
  }
  
  /**
   * @notice Called when tokens are bought in token sale
   * @param _beneficiary Address on which tokens are deposited
   * @param _tokens Amount of tokens to be created
   */
  function sendBoughtTokens(address _beneficiary, uint256 _tokens) external {
    require(locked);
    require(contractManager.authorize(contractName, msg.sender));
    require(_beneficiary != address(0));
    require(_tokens != 0);

    totalSupply_ = totalSupply_.add(_tokens);
    balances[depositAddress] = balances[depositAddress].add(_tokens);

    emit TokensMinted(msg.sender, depositAddress, _tokens);

    _transfer(depositAddress, _beneficiary, _tokens);
  }

  /**
   * @notice Called when deposit address needs to change
   * @param _depositAddress Address on which minted tokens are deposited
   */
  function changeDepositAddress(address _depositAddress) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(_depositAddress != address(0));
    require(_depositAddress != depositAddress);

    address oldDepositAddress = depositAddress;
    depositAddress = _depositAddress;

    emit DepositAddressChanged(oldDepositAddress, _depositAddress);
  }
}

// File: contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @author Bram Hoven
 * @notice Contract for a token which can be burned during the sale or after
 */
contract BurnableToken is BurnableTokenInterface, MintableToken {

  /**
   * @notice Constructor for creating burnable token
   * @param _depositAddress Address on which minted coins will be deposited
   * @param _contractName Name of this contract for lookup in contract manager
   * @param _contractManager Address where the contract manager is located
   */
  constructor(address _depositAddress, string _contractName, address _contractManager) public MintableToken(_depositAddress, _contractName, _contractManager) {
  }

  /**
   * @notice Called when tokens have to be burned (only after sale)
   * @param _tokens Amount of tokens to be burned
   */
  function burnTokens(uint256 _tokens) external {
    require(!locked);
    require(contractManager.authorize(contractName, msg.sender));

    require(depositAddress != address(0));
    require(_tokens != 0);
    require(_tokens <= balances[depositAddress]);

    balances[depositAddress] = balances[depositAddress].sub(_tokens);
    totalSupply_ = totalSupply_.sub(_tokens);

    emit TokensBurned(msg.sender, depositAddress, _tokens);
  }
}

// File: contracts/token/FidaToken.sol

/**
 * @title Fida Token
 * @author Bram Hoven
 * @notice Token contract for the fida token
 */
contract FidaToken is BurnableToken {
  string public name = "fida";
  string public symbol = "fida";
  uint8 public decimals = 18;
  
  /**
   * @notice Constructor which creates the fida token
   * @param _depositAddress Address on which minted tokens are deposited
   * @param _contractName Name of this contract for lookup in contract manager
   * @param _contractManager Address where the contract manager is located
   */
  constructor(address _depositAddress, string _contractName, address _contractManager) public BurnableToken(_depositAddress, _contractName, _contractManager) {}

  /**
   * @notice Unlock tokens, hereafter they will be tradable
   */
  function unlockTokens() public {
    require(contractManager.authorize(contractName, msg.sender));

    BasicToken.unlockTokens();
  }
}