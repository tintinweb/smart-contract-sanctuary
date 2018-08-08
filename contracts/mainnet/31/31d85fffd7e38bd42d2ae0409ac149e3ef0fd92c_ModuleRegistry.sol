pragma solidity ^0.4.24;

/**
 * @title Interface for the polymath module registry contract
 */
contract IModuleRegistry {

    /**
     * @notice Called by a security token to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external;

    /**
     * @notice Called by moduleFactory owner to register new modules for SecurityToken to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external returns(bool);

    /**
     * @notice Use to get all the tags releated to the functionality of the Module Factory.
     * @param _moduleType Type of module
     */
    function getTagByModuleType(uint8 _moduleType) public view returns(bytes32[]);

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

/**
 * @title Interface that any module factory contract should implement
 */
contract IModuleFactory is Ownable {

    ERC20 public polyToken;
    uint256 public setupCost;
    uint256 public usageCost;
    uint256 public monthlySubscriptionCost;

    event LogChangeFactorySetupFee(uint256 _oldSetupcost, uint256 _newSetupCost, address _moduleFactory);
    event LogChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactory);
    event LogChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactory);
    event LogGenerateModuleFromFactory(address _module, bytes32 indexed _moduleName, address indexed _moduleFactory, address _creator, uint256 _timestamp);

    /**
     * @notice Constructor
     * @param _polyAddress Address of the polytoken
     */
    constructor (address _polyAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public {
      polyToken = ERC20(_polyAddress);
      setupCost = _setupCost;
      usageCost = _usageCost;
      monthlySubscriptionCost = _subscriptionCost;
    }

    //Should create an instance of the Module, or throw
    function deploy(bytes _data) external returns(address);

    /**
     * @notice Type of the Module factory
     */
    function getType() public view returns(uint8);

    /**
     * @notice Get the name of the Module
     */
    function getName() public view returns(bytes32);

    /**
     * @notice Get the description of the Module
     */
    function getDescription() public view returns(string);

    /**
     * @notice Get the title of the Module
     */
    function getTitle() public view returns(string);

    /**
     * @notice Get the Instructions that helped to used the module
     */
    function getInstructions() public view returns (string);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() public view returns (bytes32[]);

    //Pull function sig from _data
    function getSig(bytes _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

    /**
     * @notice used to change the fee of the setup cost
     * @param _newSetupCost new setup cost
     */
    function changeFactorySetupFee(uint256 _newSetupCost) public onlyOwner {
        emit LogChangeFactorySetupFee(setupCost, _newSetupCost, address(this));
        setupCost = _newSetupCost;
    }

    /**
     * @notice used to change the fee of the usage cost
     * @param _newUsageCost new usage cost
     */
    function changeFactoryUsageFee(uint256 _newUsageCost) public onlyOwner {
        emit LogChangeFactoryUsageFee(usageCost, _newUsageCost, address(this));
        usageCost = _newUsageCost;
    }

    /**
     * @notice used to change the fee of the subscription cost
     * @param _newSubscriptionCost new subscription cost
     */
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) public onlyOwner {
        emit LogChangeFactorySubscriptionFee(monthlySubscriptionCost, _newSubscriptionCost, address(this));
        monthlySubscriptionCost = _newSubscriptionCost;
        
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * @title Interface for the ST20 token standard
 */
contract IST20 is StandardToken, DetailedERC20 {

    // off-chain hash
    string public tokenDetails;

    //transfer, transferFrom must respect use respect the result of verifyTransfer
    function verifyTransfer(address _from, address _to, uint256 _amount) public returns (bool success);

    /**
     * @notice mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there&#39;s no STO attached yet)
     */
    function mint(address _investor, uint256 _amount) public returns (bool success);

    /**
     * @notice Burn function used to burn the securityToken
     * @param _value No. of token that get burned
     */
    function burn(uint256 _value) public;

    event Minted(address indexed to, uint256 amount);
    event Burnt(address indexed _burner, uint256 _value);

}

/**
 * @title Interface for all security tokens
 */
contract ISecurityToken is IST20, Ownable {

    uint8 public constant PERMISSIONMANAGER_KEY = 1;
    uint8 public constant TRANSFERMANAGER_KEY = 2;
    uint8 public constant STO_KEY = 3;
    uint8 public constant CHECKPOINT_KEY = 4;
    uint256 public granularity;

    // Value of current checkpoint
    uint256 public currentCheckpointId;

    // Total number of non-zero token holders
    uint256 public investorCount;

    // List of token holders
    address[] public investors;

    // Permissions this to a Permission module, which has a key of 1
    // If no Permission return false - note that IModule withPerm will allow ST owner all permissions anyway
    // this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);

    /**
     * @notice returns module list for a module type
     * @param _moduleType is which type of module we are trying to remove
     * @param _moduleIndex is the index of the module within the chosen type
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address);

    /**
     * @notice returns module list for a module name - will return first match
     * @param _moduleType is which type of module we are trying to remove
     * @param _name is the name of the module within the chosen type
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address);

    /**
     * @notice Queries totalSupply as of a defined checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) public view returns(uint256);

    /**
     * @notice Queries balances as of a defined checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) public view returns(uint256);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() public returns(uint256);

    /**
     * @notice gets length of investors array
     * NB - this length may differ from investorCount if list has not been pruned of zero balance investors
     * @return length
     */
    function getInvestorsLength() public view returns(uint256);

}

/**
 * @title Interface for the polymath security token registry contract
 */
contract ISecurityTokenRegistry {

    bytes32 public protocolVersion = "0.0.1";
    mapping (bytes32 => address) public protocolVersionST;

    struct SecurityTokenData {
        string symbol;
        string tokenDetails;
    }

    mapping(address => SecurityTokenData) securityTokens;
    mapping(string => address) symbols;

    /**
     * @notice Creates a new Security Token and saves it to the registry
     * @param _name Name of the token
     * @param _symbol Ticker symbol of the security token
     * @param _tokenDetails off-chain details of the token
     */
    function generateSecurityToken(string _name, string _symbol, string _tokenDetails, bool _divisible) public;

    function setProtocolVersion(address _stVersionProxyAddress, bytes32 _version) public;

    /**
     * @notice Get security token address by ticker name
     * @param _symbol Symbol of the Scurity token
     * @return address _symbol
     */
    function getSecurityTokenAddress(string _symbol) public view returns (address);

     /**
     * @notice Get security token data by its address
     * @param _securityToken Address of the Scurity token
     * @return string, address, bytes32
     */
    function getSecurityTokenData(address _securityToken) public view returns (string, address, string);

    /**
    * @notice Check that Security Token is registered
    * @param _securityToken Address of the Scurity token
    * @return bool
    */
    function isSecurityToken(address _securityToken) public view returns (bool);
}

/**
 * @title Utility contract to allow pausing and unpausing of certain functions
 */
contract Pausable {

    event Pause(uint256 _timestammp);
    event Unpause(uint256 _timestamp);

    bool public paused = false;

    /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

   /**
    * @notice called by the owner to pause, triggers stopped state
    */
    function _pause() internal {
        require(!paused);
        paused = true;
        emit Pause(now);
    }

    /**
    * @notice called by the owner to unpause, returns to normal state
    */
    function _unpause() internal {
        require(paused);
        paused = false;
        emit Unpause(now);
    }

}

/**
 * @title Utility contract to allow owner to retreive any ERC20 sent to the contract
 */
contract ReclaimTokens is Ownable {

    /**
    * @notice Reclaim all ERC20Basic compatible tokens
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0));
        ERC20Basic token = ERC20Basic(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance));
    }
}

/**
 * @title Core functionality for registry upgradability
 */
contract PolymathRegistry is ReclaimTokens {

    mapping (bytes32 => address) public storedAddresses;

    event LogChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);

    /**
     * @notice Get the contract address
     * @param _nameKey is the key for the contract address mapping
     * @return address
     */
    function getAddress(string _nameKey) view public returns(address) {
        bytes32 key = keccak256(bytes(_nameKey));
        require(storedAddresses[key] != address(0), "Invalid address key");
        return storedAddresses[key];
    }

    /**
     * @notice change the contract address
     * @param _nameKey is the key for the contract address mapping
     * @param _newAddress is the new contract address
     */
    function changeAddress(string _nameKey, address _newAddress) public onlyOwner {
        bytes32 key = keccak256(bytes(_nameKey));
        emit LogChangeAddress(_nameKey, storedAddresses[key], _newAddress);
        storedAddresses[key] = _newAddress;
    }


}

contract RegistryUpdater is Ownable {

    address public polymathRegistry;
    address public moduleRegistry;
    address public securityTokenRegistry;
    address public tickerRegistry;
    address public polyToken;

    constructor (address _polymathRegistry) public {
        require(_polymathRegistry != address(0));
        polymathRegistry = _polymathRegistry;
    }

    function updateFromRegistry() onlyOwner public {
        moduleRegistry = PolymathRegistry(polymathRegistry).getAddress("ModuleRegistry");
        securityTokenRegistry = PolymathRegistry(polymathRegistry).getAddress("SecurityTokenRegistry");
        tickerRegistry = PolymathRegistry(polymathRegistry).getAddress("TickerRegistry");
        polyToken = PolymathRegistry(polymathRegistry).getAddress("PolyToken");
    }

}

/**
* @title Registry contract to store registered modules
* @notice Anyone can register modules, but only those "approved" by Polymath will be available for issuers to add
*/
contract ModuleRegistry is IModuleRegistry, Pausable, RegistryUpdater, ReclaimTokens {

    // Mapping used to hold the type of module factory corresponds to the address of the Module factory contract
    mapping (address => uint8) public registry;
    // Mapping used to hold the reputation of the factory
    mapping (address => address[]) public reputation;
    // Mapping contain the list of addresses of Module factory for a particular type
    mapping (uint8 => address[]) public moduleList;
    // contains the list of verified modules
    mapping (address => bool) public verified;
    // Contains the list of the available tags corresponds to the module type
    mapping (uint8 => bytes32[]) public availableTags;

    // Emit when Module been used by the securityToken
    event LogModuleUsed(address indexed _moduleFactory, address indexed _securityToken);
    // Emit when the Module Factory get registered with the ModuleRegistry contract
    event LogModuleRegistered(address indexed _moduleFactory, address indexed _owner);
    // Emit when the module get verified by the Polymath team
    event LogModuleVerified(address indexed _moduleFactory, bool _verified);

    constructor (address _polymathRegistry) public
        RegistryUpdater(_polymathRegistry)
    {
    }

   /**
    * @notice Called by a security token to notify the registry it is using a module
    * @param _moduleFactory is the address of the relevant module factory
    */
    function useModule(address _moduleFactory) external {
        //If caller is a registered security token, then register module usage
        if (ISecurityTokenRegistry(securityTokenRegistry).isSecurityToken(msg.sender)) {
            require(registry[_moduleFactory] != 0, "ModuleFactory type should not be 0");
            //To use a module, either it must be verified, or owned by the ST owner
            require(verified[_moduleFactory]||(IModuleFactory(_moduleFactory).owner() == ISecurityToken(msg.sender).owner()),
              "Module factory is not verified as well as not called by the owner");
            reputation[_moduleFactory].push(msg.sender);
            emit LogModuleUsed (_moduleFactory, msg.sender);
        }
    }

    /**
    * @notice Called by moduleFactory owner to register new modules for SecurityToken to use
    * @param _moduleFactory is the address of the module factory to be registered
    * @return bool
    */
    function registerModule(address _moduleFactory) external whenNotPaused returns(bool) {
        require(registry[_moduleFactory] == 0, "Module factory should not be pre-registered");
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        require(moduleFactory.getType() != 0, "Factory type should not equal to 0");
        registry[_moduleFactory] = moduleFactory.getType();
        moduleList[moduleFactory.getType()].push(_moduleFactory);
        reputation[_moduleFactory] = new address[](0);
        emit LogModuleRegistered (_moduleFactory, moduleFactory.owner());
        return true;
    }

    /**
    * @notice Called by Polymath to verify modules for SecurityToken to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST)
    * @param _moduleFactory is the address of the module factory to be registered
    * @return bool
    */
    function verifyModule(address _moduleFactory, bool _verified) external onlyOwner returns(bool) {
        //Must already have been registered
        require(registry[_moduleFactory] != 0, "Module factory should have been already registered");
        verified[_moduleFactory] = _verified;
        emit LogModuleVerified(_moduleFactory, _verified);
        return true;
    }

    /**
     * @notice Use to get all the tags releated to the functionality of the Module Factory.
     * @param _moduleType Type of module
     * @return bytes32 array
     */
    function getTagByModuleType(uint8 _moduleType) public view returns(bytes32[]) {
        return availableTags[_moduleType];
    }

    /**
     * @notice Add the tag for specified Module Factory
     * @param _moduleType Type of module.
     * @param _tag List of tags
     */
     function addTagByModuleType(uint8 _moduleType, bytes32[] _tag) public onlyOwner {
         for (uint8 i = 0; i < _tag.length; i++) {
             availableTags[_moduleType].push(_tag[i]);
         }
     }

    /**
     * @notice remove the tag for specified Module Factory
     * @param _moduleType Type of module.
     * @param _removedTags List of tags
     */
     function removeTagByModuleType(uint8 _moduleType, bytes32[] _removedTags) public onlyOwner {
         for (uint8 i = 0; i < availableTags[_moduleType].length; i++) {
            for (uint8 j = 0; j < _removedTags.length; j++) {
                if (availableTags[_moduleType][i] == _removedTags[j]) {
                    delete availableTags[_moduleType][i];
                }
            }
        }
     }

     /**
     * @notice pause registration function
     */
    function unpause() public onlyOwner  {
        _unpause();
    }

    /**
     * @notice unpause registration function
     */
    function pause() public onlyOwner {
        _pause();
    }


}