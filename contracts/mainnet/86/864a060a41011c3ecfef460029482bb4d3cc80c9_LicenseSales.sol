pragma solidity 0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e286839487a283898d8f8083cc818d8f">[email&#160;protected]</a>
// released under Apache 2.0 licence
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract DeconetToken is StandardToken, Ownable, Pausable {
    // token naming etc
    string public constant symbol = "DCO";
    string public constant name = "Deconet Token";
    uint8 public constant decimals = 18;

    // contract version
    uint public constant version = 4;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        // 1 billion tokens (1,000,000,000)
        totalSupply_ = 1000000000 * 10**uint(decimals);

        // transfer initial supply to msg.sender who is also contract owner
        balances[msg.sender] = totalSupply_;
        Transfer(address(0), msg.sender, totalSupply_);

        // pause contract until we&#39;re ready to allow transfers
        paused = true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Modifier to make a function callable only when called by the contract owner
    // or if the contract is not paused.
    // ------------------------------------------------------------------------
    modifier whenOwnerOrNotPaused() {
        require(msg.sender == owner || !paused);
        _;
    }

    // ------------------------------------------------------------------------
    // overloaded openzepplin method to add whenOwnerOrNotPaused modifier
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    // ------------------------------------------------------------------------
    // overloaded openzepplin method to add whenOwnerOrNotPaused modifier
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    // ------------------------------------------------------------------------
    // overloaded openzepplin method to add whenOwnerOrNotPaused modifier
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    // ------------------------------------------------------------------------
    // overloaded openzepplin method to add whenOwnerOrNotPaused modifier
    // ------------------------------------------------------------------------
    function increaseApproval(address _spender, uint _addedValue) public whenOwnerOrNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    // ------------------------------------------------------------------------
    // overloaded openzepplin method to add whenOwnerOrNotPaused modifier
    // ------------------------------------------------------------------------
    function decreaseApproval(address _spender, uint _subtractedValue) public whenOwnerOrNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract Relay is Ownable {
    address public licenseSalesContractAddress;
    address public registryContractAddress;
    address public apiRegistryContractAddress;
    address public apiCallsContractAddress;
    uint public version;

    // ------------------------------------------------------------------------
    // Constructor, establishes ownership because contract is owned
    // ------------------------------------------------------------------------
    constructor() public {
        version = 4;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Sets the license sales contract address
    // ------------------------------------------------------------------------
    function setLicenseSalesContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        licenseSalesContractAddress = newAddress;
    }

    // ------------------------------------------------------------------------
    // Sets the registry contract address
    // ------------------------------------------------------------------------
    function setRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        registryContractAddress = newAddress;
    }

    // ------------------------------------------------------------------------
    // Sets the api registry contract address
    // ------------------------------------------------------------------------
    function setApiRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiRegistryContractAddress = newAddress;
    }

    // ------------------------------------------------------------------------
    // Sets the api calls contract address
    // ------------------------------------------------------------------------
    function setApiCallsContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiCallsContractAddress = newAddress;
    }
}
contract Registry is Ownable {

    struct ModuleForSale {
        uint price;
        bytes32 sellerUsername;
        bytes32 moduleName;
        address sellerAddress;
        bytes4 licenseId;
    }

    mapping(string => uint) internal moduleIds;
    mapping(uint => ModuleForSale) public modules;

    uint public numModules;
    uint public version;

    // ------------------------------------------------------------------------
    // Constructor, establishes ownership because contract is owned
    // ------------------------------------------------------------------------
    constructor() public {
        numModules = 0;
        version = 1;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Lets a user list a software module for sale in this registry
    // ------------------------------------------------------------------------
    function listModule(uint price, bytes32 sellerUsername, bytes32 moduleName, string usernameAndProjectName, bytes4 licenseId) public {
        // make sure input params are valid
        require(price != 0 && sellerUsername != "" && moduleName != "" && bytes(usernameAndProjectName).length != 0 && licenseId != 0);

        // make sure the name isn&#39;t already taken
        require(moduleIds[usernameAndProjectName] == 0);

        numModules += 1;
        moduleIds[usernameAndProjectName] = numModules;

        ModuleForSale storage module = modules[numModules];

        module.price = price;
        module.sellerUsername = sellerUsername;
        module.moduleName = moduleName;
        module.sellerAddress = msg.sender;
        module.licenseId = licenseId;
    }

    // ------------------------------------------------------------------------
    // Get the ID number of a module given the username and project name of that module
    // ------------------------------------------------------------------------
    function getModuleId(string usernameAndProjectName) public view returns (uint) {
        return moduleIds[usernameAndProjectName];
    }

    // ------------------------------------------------------------------------
    // Get info stored for a module by id
    // ------------------------------------------------------------------------
    function getModuleById(
        uint moduleId
    ) 
        public 
        view 
        returns (
            uint price, 
            bytes32 sellerUsername, 
            bytes32 moduleName, 
            address sellerAddress, 
            bytes4 licenseId
        ) 
    {
        ModuleForSale storage module = modules[moduleId];
        

        if (module.sellerAddress == address(0)) {
            return;
        }

        price = module.price;
        sellerUsername = module.sellerUsername;
        moduleName = module.moduleName;
        sellerAddress = module.sellerAddress;
        licenseId = module.licenseId;
    }

    // ------------------------------------------------------------------------
    // get info stored for a module by name
    // ------------------------------------------------------------------------
    function getModuleByName(
        string usernameAndProjectName
    ) 
        public 
        view
        returns (
            uint price, 
            bytes32 sellerUsername, 
            bytes32 moduleName, 
            address sellerAddress, 
            bytes4 licenseId
        ) 
    {
        uint moduleId = moduleIds[usernameAndProjectName];
        if (moduleId == 0) {
            return;
        }
        ModuleForSale storage module = modules[moduleId];

        price = module.price;
        sellerUsername = module.sellerUsername;
        moduleName = module.moduleName;
        sellerAddress = module.sellerAddress;
        licenseId = module.licenseId;
    }

    // ------------------------------------------------------------------------
    // Edit a module listing
    // ------------------------------------------------------------------------
    function editModule(uint moduleId, uint price, address sellerAddress, bytes4 licenseId) public {
        // Make sure input params are valid
        require(moduleId != 0 && price != 0 && sellerAddress != address(0) && licenseId != 0);

        ModuleForSale storage module = modules[moduleId];

        // prevent editing an empty module (effectively listing a module)
        require(
            module.price != 0 && module.sellerUsername != "" && module.moduleName != "" && module.licenseId != 0 && module.sellerAddress != address(0)
        );

        // require that sender is the original module lister, or the contract owner
        // the contract owner clause lets us recover a module listing if a dev loses access to their privkey
        require(msg.sender == module.sellerAddress || msg.sender == owner);

        module.price = price;
        module.sellerAddress = sellerAddress;
        module.licenseId = licenseId;
    }
}
contract LicenseSales is Ownable {
    using SafeMath for uint;

    // the amount rewarded to a seller for selling a license
    uint public tokenReward;

    // the fee this contract takes from every sale.  expressed as percent.  so a value of 3 indicates a 3% txn fee
    uint public saleFee;

    // address of the relay contract which holds the address of the registry contract.
    address public relayContractAddress;

    // the token address
    address public tokenContractAddress;

    // this contract version
    uint public version;

    // the address that is authorized to withdraw eth
    address private withdrawAddress;

    event LicenseSale(
        bytes32 moduleName,
        bytes32 sellerUsername,
        address indexed sellerAddress,
        address indexed buyerAddress,
        uint price,
        uint soldAt,
        uint rewardedTokens,
        uint networkFee,
        bytes4 licenseId
    );

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        version = 1;

        // default token reward of 100 tokens.  
        // token has 18 decimal places so that&#39;s why 100 * 10^18
        tokenReward = 100 * 10**18;

        // default saleFee of 10%
        saleFee = 10;

        // default withdrawAddress is owner
        withdrawAddress = msg.sender;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any ETH
    // ------------------------------------------------------------------------
    function withdrawEther() public {
        require(msg.sender == withdrawAddress);
        withdrawAddress.transfer(this.balance);
    }

    // ------------------------------------------------------------------------
    // Owner can set address of who can withdraw
    // ------------------------------------------------------------------------
    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        require(_withdrawAddress != address(0));
        withdrawAddress = _withdrawAddress;
    }

    // ------------------------------------------------------------------------
    // Owner can set address of relay contract
    // ------------------------------------------------------------------------
    function setRelayContractAddress(address _relayContractAddress) public onlyOwner {
        require(_relayContractAddress != address(0));
        relayContractAddress = _relayContractAddress;
    }

    // ------------------------------------------------------------------------
    // Owner can set address of token contract
    // ------------------------------------------------------------------------
    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner {
        require(_tokenContractAddress != address(0));
        tokenContractAddress = _tokenContractAddress;
    }

    // ------------------------------------------------------------------------
    // Owner can set token reward
    // ------------------------------------------------------------------------
    function setTokenReward(uint _tokenReward) public onlyOwner {
        tokenReward = _tokenReward;
    }

    // ------------------------------------------------------------------------
    // Owner can set the sale fee
    // ------------------------------------------------------------------------
    function setSaleFee(uint _saleFee) public onlyOwner {
        saleFee = _saleFee;
    }

    // ------------------------------------------------------------------------
    // Anyone can make a sale if they provide a moduleId
    // ------------------------------------------------------------------------
    function makeSale(uint moduleId) public payable {
        require(moduleId != 0);

        // look up the registry address from relay token
        Relay relay = Relay(relayContractAddress);
        address registryAddress = relay.registryContractAddress();

        // get the module info from registry
        Registry registry = Registry(registryAddress);

        uint price;
        bytes32 sellerUsername;
        bytes32 moduleName;
        address sellerAddress;
        bytes4 licenseId;

        (price, sellerUsername, moduleName, sellerAddress, licenseId) = registry.getModuleById(moduleId);

        // make sure the customer has sent enough eth
        require(msg.value >= price);

        // make sure the module is actually valid
        require(sellerUsername != "" && moduleName != "" && sellerAddress != address(0) && licenseId != "");

        // calculate fee and payout
        uint fee = msg.value.mul(saleFee).div(100); 
        uint payout = msg.value.sub(fee);

        // log the sale
        emit LicenseSale(
            moduleName,
            sellerUsername,
            sellerAddress,
            msg.sender,
            price,
            block.timestamp,
            tokenReward,
            fee,
            licenseId
        );

        // give seller some tokens for the sale
        rewardTokens(sellerAddress);
        
        // pay seller the ETH
        sellerAddress.transfer(payout);
    }

    // ------------------------------------------------------------------------
    // Reward user with tokens IF the contract has them in it&#39;s allowance
    // ------------------------------------------------------------------------
    function rewardTokens(address toReward) private {
        DeconetToken token = DeconetToken(tokenContractAddress);
        address tokenOwner = token.owner();

        // check balance of tokenOwner
        uint tokenOwnerBalance = token.balanceOf(tokenOwner);
        uint tokenOwnerAllowance = token.allowance(tokenOwner, address(this));
        if (tokenOwnerBalance >= tokenReward && tokenOwnerAllowance >= tokenReward) {
            token.transferFrom(tokenOwner, toReward, tokenReward);
        }
    }
}