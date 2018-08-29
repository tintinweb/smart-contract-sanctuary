pragma solidity 0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d3b7b2a5b693b2b8bcbeb1b2fdb0bcbe">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract APIRegistry is Ownable {

    struct APIForSale {
        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;
        string hostname;
        string docsUrl;
    }

    mapping(string => uint) internal apiIds;
    mapping(uint => APIForSale) public apis;

    uint public numApis;
    uint public version;

    // ------------------------------------------------------------------------
    // Constructor, establishes ownership because contract is owned
    // ------------------------------------------------------------------------
    constructor() public {
        numApis = 0;
        version = 1;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Lets a user list an API to sell
    // ------------------------------------------------------------------------
    function listApi(uint pricePerCall, bytes32 sellerUsername, bytes32 apiName, string hostname, string docsUrl) public {
        // make sure input params are valid
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && bytes(hostname).length != 0);
        
        // make sure the name isn&#39;t already taken
        require(apiIds[hostname] == 0);

        numApis += 1;
        apiIds[hostname] = numApis;

        APIForSale storage api = apis[numApis];

        api.pricePerCall = pricePerCall;
        api.sellerUsername = sellerUsername;
        api.apiName = apiName;
        api.sellerAddress = msg.sender;
        api.hostname = hostname;
        api.docsUrl = docsUrl;
    }

    // ------------------------------------------------------------------------
    // Get the ID number of an API given it&#39;s hostname
    // ------------------------------------------------------------------------
    function getApiId(string hostname) public view returns (uint) {
        return apiIds[hostname];
    }

    // ------------------------------------------------------------------------
    // Get info stored for the API but without the dynamic members, because solidity can&#39;t return dynamics to other smart contracts yet
    // ------------------------------------------------------------------------
    function getApiByIdWithoutDynamics(
        uint apiId
    ) 
        public
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername,
            bytes32 apiName, 
            address sellerAddress
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
    }

    // ------------------------------------------------------------------------
    // Get info stored for an API by id
    // ------------------------------------------------------------------------
    function getApiById(
        uint apiId
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

    // ------------------------------------------------------------------------
    // Get info stored for an API by hostname
    // ------------------------------------------------------------------------
    function getApiByName(
        string _hostname
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        uint apiId = apiIds[_hostname];
        if (apiId == 0) {
            return;
        }
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

    // ------------------------------------------------------------------------
    // Edit an API listing
    // ------------------------------------------------------------------------
    function editApi(uint apiId, uint pricePerCall, address sellerAddress, string docsUrl) public {
        require(apiId != 0 && pricePerCall != 0 && sellerAddress != address(0));

        APIForSale storage api = apis[apiId];

        // prevent editing an empty api (effectively listing an api)
        require(
            api.pricePerCall != 0 && api.sellerUsername != "" && api.apiName != "" &&  bytes(api.hostname).length != 0 && api.sellerAddress != address(0)
        );

        // require that sender is the original api lister, or the contract owner
        // the contract owner clause lets us recover a api listing if a dev loses access to their privkey
        require(msg.sender == api.sellerAddress || msg.sender == owner);

        api.pricePerCall = pricePerCall;
        api.sellerAddress = sellerAddress;
        api.docsUrl = docsUrl;
    }
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

contract APICalls is Ownable {
    using SafeMath for uint;

    // the amount rewarded to a seller for selling api calls per buyer
    uint public tokenReward;

    // the fee this contract takes from every sale.  expressed as percent.  so a value of 3 indicates a 3% txn fee
    uint public saleFee;

    // if the buyer has never paid, we need to pick a date for when they probably started using the API.  
    // This is in seconds and will be subtracted from "now"
    uint public defaultBuyerLastPaidAt;

    // address of the relay contract which holds the address of the registry contract.
    address public relayContractAddress;

    // the token address
    address public tokenContractAddress;

    // this contract version
    uint public version;

    // the amount that can be safely withdrawn from the contract
    uint public safeWithdrawAmount;

    // the address that is authorized to withdraw eth
    address private withdrawAddress;

    // the address that is authorized to report usage on behalf of deconet
    address private usageReportingAddress;

    // maps apiId to a APIBalance which stores how much each address owes
    mapping(uint => APIBalance) internal owed;

    // maps buyer addresses to whether or not accounts are overdrafted and more
    mapping(address => BuyerInfo) internal buyers;

    // Stores amounts owed and when buyers last paid on a per-api and per-user basis
    struct APIBalance {
        // maps address -> amount owed in wei
        mapping(address => uint) amounts;
        // basically a list of keys for the above map
        address[] nonzeroAddresses;
        // maps address -> tiemstamp of when buyer last paid
        mapping(address => uint) buyerLastPaidAt;
    }

    // Stores basic info about a buyer including their lifetime stats and reputation info
    struct BuyerInfo {
        // whether or not the account is overdrafted or not
        bool overdrafted;
        // total number of overdrafts, ever
        uint lifetimeOverdraftCount;
        // credits on file with this contract (wei)
        uint credits;
        // total amount of credits used / spent, ever (wei)
        uint lifetimeCreditsUsed;
        // maps apiId to approved spending balance for each API per second.
        mapping(uint => uint) approvedAmounts;
        // maps apiId to whether or not the user has exceeded their approved amount
        mapping(uint => bool) exceededApprovedAmount;
        // total number of times exceededApprovedAmount has happened
        uint lifetimeExceededApprovalAmountCount;
    }

    // Logged when API call usage is reported
    event LogAPICallsMade(
        uint apiId,
        address indexed sellerAddress,
        address indexed buyerAddress,
        uint pricePerCall,
        uint numCalls,
        uint totalPrice,
        address reportingAddress
    );

    // Logged when seller is paid for API calls
    event LogAPICallsPaid(
        uint apiId,
        address indexed sellerAddress,
        uint totalPrice,
        uint rewardedTokens,
        uint networkFee
    );

    // Logged when the credits from a specific buyer are spent on a specific api
    event LogSpendCredits(
        address indexed buyerAddress,
        uint apiId,
        uint amount,
        bool causedAnOverdraft
    );

    // Logged when a buyer deposits credits
    event LogDepositCredits(
        address indexed buyerAddress,
        uint amount
    );

    // Logged whena  buyer withdraws credits
    event LogWithdrawCredits(
        address indexed buyerAddress,
        uint amount
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

        // 604,800 seconds = 1 week.  this is the default for when a user started using an api (1 week ago)
        defaultBuyerLastPaidAt = 604800;

        // default withdrawAddress is owner
        withdrawAddress = msg.sender;
        usageReportingAddress = msg.sender;
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
    function withdrawEther(uint amount) public {
        require(msg.sender == withdrawAddress);
        require(amount <= this.balance);
        require(amount <= safeWithdrawAmount);
        safeWithdrawAmount = safeWithdrawAmount.sub(amount);
        withdrawAddress.transfer(amount);
    }

    // ------------------------------------------------------------------------
    // Owner can set address of who can withdraw
    // ------------------------------------------------------------------------
    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        require(_withdrawAddress != address(0));
        withdrawAddress = _withdrawAddress;
    }

    // ------------------------------------------------------------------------
    // Owner can set address of who can report usage
    // ------------------------------------------------------------------------
    function setUsageReportingAddress(address _usageReportingAddress) public onlyOwner {
        require(_usageReportingAddress != address(0));
        usageReportingAddress = _usageReportingAddress;
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
    // Owner can set the default buyer last paid at
    // ------------------------------------------------------------------------
    function setDefaultBuyerLastPaidAt(uint _defaultBuyerLastPaidAt) public onlyOwner {
        defaultBuyerLastPaidAt = _defaultBuyerLastPaidAt;
    }

    // ------------------------------------------------------------------------
    // The API owner or the authorized deconet usage reporting address may report usage
    // ------------------------------------------------------------------------
    function reportUsage(uint apiId, uint numCalls, address buyerAddress) public {
        // look up the registry address from relay contract
        Relay relay = Relay(relayContractAddress);
        address apiRegistryAddress = relay.apiRegistryContractAddress();

        // get the module info from registry
        APIRegistry apiRegistry = APIRegistry(apiRegistryAddress);

        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;

        (pricePerCall, sellerUsername, apiName, sellerAddress) = apiRegistry.getApiByIdWithoutDynamics(apiId);

        // make sure the caller is either the api owner or the deconet reporting address
        require(sellerAddress != address(0));
        require(msg.sender == sellerAddress || msg.sender == usageReportingAddress);

        // make sure the api is actually valid
        require(sellerUsername != "" && apiName != "");

        uint totalPrice = pricePerCall.mul(numCalls);

        require(totalPrice > 0);

        APIBalance storage apiBalance = owed[apiId];

        if (apiBalance.amounts[buyerAddress] == 0) {
            // add buyerAddress to list of addresses with nonzero balance for this api
            apiBalance.nonzeroAddresses.push(buyerAddress);
        }

        apiBalance.amounts[buyerAddress] = apiBalance.amounts[buyerAddress].add(totalPrice);

        emit LogAPICallsMade(
            apiId,
            sellerAddress,
            buyerAddress,
            pricePerCall,
            numCalls,
            totalPrice,
            msg.sender
        );
    }

    // ------------------------------------------------------------------------
    // Function to pay the seller for a single API buyer.  
    // Settles reported usage according to credits and approved amounts.
    // ------------------------------------------------------------------------
    function paySellerForBuyer(uint apiId, address buyerAddress) public {
        // look up the registry address from relay contract
        Relay relay = Relay(relayContractAddress);
        address apiRegistryAddress = relay.apiRegistryContractAddress();

        // get the module info from registry
        APIRegistry apiRegistry = APIRegistry(apiRegistryAddress);

        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;

        (pricePerCall, sellerUsername, apiName, sellerAddress) = apiRegistry.getApiByIdWithoutDynamics(apiId);

        // make sure it&#39;s a legit real api
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && sellerAddress != address(0));

        uint buyerPaid = processSalesForSingleBuyer(apiId, buyerAddress);

        if (buyerPaid == 0) {
            return; // buyer paid nothing, we are done.
        }

        // calculate fee and payout
        uint fee = buyerPaid.mul(saleFee).div(100);
        uint payout = buyerPaid.sub(fee);

        // log that we stored the fee so we know we can take it out later
        safeWithdrawAmount += fee;

        emit LogAPICallsPaid(
            apiId,
            sellerAddress,
            buyerPaid,
            tokenReward,
            fee
        );

        // give seller some tokens for the sale
        rewardTokens(sellerAddress, tokenReward);

        // transfer seller the eth
        sellerAddress.transfer(payout);
    }

    // ------------------------------------------------------------------------
    // Function to pay the seller for all buyers with nonzero balance.  
    // Settles reported usage according to credits and approved amounts.
    // ------------------------------------------------------------------------
    function paySeller(uint apiId) public {
        // look up the registry address from relay contract
        Relay relay = Relay(relayContractAddress);
        address apiRegistryAddress = relay.apiRegistryContractAddress();

        // get the module info from registry
        APIRegistry apiRegistry = APIRegistry(apiRegistryAddress);

        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;

        (pricePerCall, sellerUsername, apiName, sellerAddress) = apiRegistry.getApiByIdWithoutDynamics(apiId);

        // make sure it&#39;s a legit real api
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && sellerAddress != address(0));

        // calculate totalPayable for the api
        uint totalPayable = 0;
        uint totalBuyers = 0;
        (totalPayable, totalBuyers) = processSalesForAllBuyers(apiId);

        if (totalPayable == 0) {
            return; // if there&#39;s nothing to pay, we are done here.
        }

        // calculate fee and payout
        uint fee = totalPayable.mul(saleFee).div(100);
        uint payout = totalPayable.sub(fee);

        // log that we stored the fee so we know we can take it out later
        safeWithdrawAmount += fee;

        // we reward token reward on a "per buyer" basis.  so multiply the reward to give by the number of actual buyers
        uint totalTokenReward = tokenReward.mul(totalBuyers);

        emit LogAPICallsPaid(
            apiId,
            sellerAddress,
            totalPayable,
            totalTokenReward,
            fee
        );

        // give seller some tokens for the sale
        rewardTokens(sellerAddress, totalTokenReward);

        // transfer seller the eth
        sellerAddress.transfer(payout);
    } 

    // ------------------------------------------------------------------------
    // Let anyone see when the buyer last paid for a given API
    // ------------------------------------------------------------------------
    function buyerLastPaidAt(uint apiId, address buyerAddress) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.buyerLastPaidAt[buyerAddress];
    }   

    // ------------------------------------------------------------------------
    // Get buyer info struct for a specific buyer address
    // ------------------------------------------------------------------------
    function buyerInfoOf(address addr) 
        public 
        view 
        returns (
            bool overdrafted, 
            uint lifetimeOverdraftCount, 
            uint credits, 
            uint lifetimeCreditsUsed, 
            uint lifetimeExceededApprovalAmountCount
        ) 
    {
        BuyerInfo storage buyer = buyers[addr];
        overdrafted = buyer.overdrafted;
        lifetimeOverdraftCount = buyer.lifetimeOverdraftCount;
        credits = buyer.credits;
        lifetimeCreditsUsed = buyer.lifetimeCreditsUsed;
        lifetimeExceededApprovalAmountCount = buyer.lifetimeExceededApprovalAmountCount;
    }

    // ------------------------------------------------------------------------
    // Gets the credits balance of a buyer
    // ------------------------------------------------------------------------
    function creditsBalanceOf(address addr) public view returns (uint) {
        BuyerInfo storage buyer = buyers[addr];
        return buyer.credits;
    }

    // ------------------------------------------------------------------------
    // Lets a buyer add credits
    // ------------------------------------------------------------------------
    function addCredits(address to) public payable {
        BuyerInfo storage buyer = buyers[to];
        buyer.credits = buyer.credits.add(msg.value);
        emit LogDepositCredits(to, msg.value);
    }

    // ------------------------------------------------------------------------
    // Lets a buyer withdraw credits
    // ------------------------------------------------------------------------
    function withdrawCredits(uint amount) public {
        BuyerInfo storage buyer = buyers[msg.sender];
        require(buyer.credits >= amount);
        buyer.credits = buyer.credits.sub(amount);
        msg.sender.transfer(amount);
        emit LogWithdrawCredits(msg.sender, amount);
    }

    // ------------------------------------------------------------------------
    // Get the length of array of buyers who have a nonzero balance for a given API
    // ------------------------------------------------------------------------
    function nonzeroAddressesElementForApi(uint apiId, uint index) public view returns (address) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.nonzeroAddresses[index];
    }

    // ------------------------------------------------------------------------
    // Get an element from the array of buyers who have a nonzero balance for a given API
    // ------------------------------------------------------------------------
    function nonzeroAddressesLengthForApi(uint apiId) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.nonzeroAddresses.length;
    }

    // ------------------------------------------------------------------------
    // Get the amount owed for a specific api for a specific buyer
    // ------------------------------------------------------------------------
    function amountOwedForApiForBuyer(uint apiId, address buyerAddress) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.amounts[buyerAddress];
    }

    // ------------------------------------------------------------------------
    // Get the total owed for an entire api for all nonzero buyers
    // ------------------------------------------------------------------------
    function totalOwedForApi(uint apiId) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];

        uint totalOwed = 0;
        for (uint i = 0; i < apiBalance.nonzeroAddresses.length; i++) {
            address buyerAddress = apiBalance.nonzeroAddresses[i];
            uint buyerOwes = apiBalance.amounts[buyerAddress];
            totalOwed = totalOwed.add(buyerOwes);
        }

        return totalOwed;
    }

    // ------------------------------------------------------------------------
    // Gets the amount of wei per second a buyer has approved for a specific api
    // ------------------------------------------------------------------------
    function approvedAmount(uint apiId, address buyerAddress) public view returns (uint) {
        return buyers[buyerAddress].approvedAmounts[apiId];
    }

    // ------------------------------------------------------------------------
    // Let the buyer set an approved amount of wei per second for a specific api
    // ------------------------------------------------------------------------
    function approveAmount(uint apiId, address buyerAddress, uint newAmount) public {
        require(buyerAddress != address(0) && apiId != 0);

        // only the buyer or the usage reporing system can change the buyers approval amount
        require(msg.sender == buyerAddress || msg.sender == usageReportingAddress);

        BuyerInfo storage buyer = buyers[buyerAddress];
        buyer.approvedAmounts[apiId] = newAmount;
    }

    // ------------------------------------------------------------------------
    // function to let the buyer set their approved amount of wei per second for an api
    // this function also lets the buyer set the time they last paid for an API if they&#39;ve never paid that API before.  
    // this is important because the total amount approved for a given transaction is based on a wei per second spending limit
    // but the smart contract doesn&#39;t know when the buyer started using the API
    // so with this function, a buyer can et the time they first used the API and the approved amount calculations will be accurate when the seller requests payment.
    // ------------------------------------------------------------------------
    function approveAmountAndSetFirstUseTime(
        uint apiId, 
        address buyerAddress, 
        uint newAmount, 
        uint firstUseTime
    ) 
        public 
    {
        require(buyerAddress != address(0) && apiId != 0);

        // only the buyer or the usage reporing system can change the buyers approval amount
        require(msg.sender == buyerAddress || msg.sender == usageReportingAddress);

        APIBalance storage apiBalance = owed[apiId];
        require(apiBalance.buyerLastPaidAt[buyerAddress] == 0);

        apiBalance.buyerLastPaidAt[buyerAddress] = firstUseTime;
        
        BuyerInfo storage buyer = buyers[buyerAddress];
        buyer.approvedAmounts[apiId] = newAmount;

    }

    // ------------------------------------------------------------------------
    // Gets whether or not a buyer exceeded their approved amount in the last seller payout
    // ------------------------------------------------------------------------
    function buyerExceededApprovedAmount(uint apiId, address buyerAddress) public view returns (bool) {
        return buyers[buyerAddress].exceededApprovedAmount[apiId];
    }

    // ------------------------------------------------------------------------
    // Reward user with tokens IF the contract has them in it&#39;s allowance
    // ------------------------------------------------------------------------
    function rewardTokens(address toReward, uint amount) private {
        DeconetToken token = DeconetToken(tokenContractAddress);
        address tokenOwner = token.owner();

        // check balance of tokenOwner
        uint tokenOwnerBalance = token.balanceOf(tokenOwner);
        uint tokenOwnerAllowance = token.allowance(tokenOwner, address(this));
        if (tokenOwnerBalance >= amount && tokenOwnerAllowance >= amount) {
            token.transferFrom(tokenOwner, toReward, amount);
        }
    }

    // ------------------------------------------------------------------------
    // Process and settle balances for a single buyer for a specific api
    // ------------------------------------------------------------------------
    function processSalesForSingleBuyer(uint apiId, address buyerAddress) private returns (uint) {
        APIBalance storage apiBalance = owed[apiId];

        uint buyerOwes = apiBalance.amounts[buyerAddress];
        uint buyerLastPaidAtTime = apiBalance.buyerLastPaidAt[buyerAddress];
        if (buyerLastPaidAtTime == 0) {
            // if buyer has never paid, assume they paid a week ago.  or whatever now - defaultBuyerLastPaidAt is.
            buyerLastPaidAtTime = now - defaultBuyerLastPaidAt; // default is 604,800 = 7 days of seconds
        }
        uint elapsedSecondsSinceLastPayout = now - buyerLastPaidAtTime;
        uint buyerNowOwes = buyerOwes;
        uint buyerPaid = 0;
        bool overdrafted = false;

        (buyerPaid, overdrafted) = chargeBuyer(apiId, buyerAddress, elapsedSecondsSinceLastPayout, buyerOwes);

        buyerNowOwes = buyerOwes.sub(buyerPaid);
        apiBalance.amounts[buyerAddress] = buyerNowOwes;

        // if the buyer now owes zero, then remove them from nonzeroAddresses
        if (buyerNowOwes != 0) {
            removeAddressFromNonzeroBalancesArray(apiId, buyerAddress);
        }
        // if the buyer paid nothing, we are done here.
        if (buyerPaid == 0) {
            return 0;
        }

        // log the event
        emit LogSpendCredits(buyerAddress, apiId, buyerPaid, overdrafted);

        // log that they paid
        apiBalance.buyerLastPaidAt[buyerAddress] = now;
        
        return buyerPaid;
    }

    // ------------------------------------------------------------------------
    // Process and settle balances for all buyers with a nonzero balance for a specific api
    // ------------------------------------------------------------------------
    function processSalesForAllBuyers(uint apiId) private returns (uint totalPayable, uint totalBuyers) {
        APIBalance storage apiBalance = owed[apiId];

        uint currentTime = now;
        address[] memory oldNonzeroAddresses = apiBalance.nonzeroAddresses;
        apiBalance.nonzeroAddresses = new address[](0);

        for (uint i = 0; i < oldNonzeroAddresses.length; i++) {
            address buyerAddress = oldNonzeroAddresses[i];
            uint buyerOwes = apiBalance.amounts[buyerAddress];
            uint buyerLastPaidAtTime = apiBalance.buyerLastPaidAt[buyerAddress];
            if (buyerLastPaidAtTime == 0) {
                // if buyer has never paid, assume they paid a week ago.  or whatever now - defaultBuyerLastPaidAt is.
                buyerLastPaidAtTime = now - defaultBuyerLastPaidAt; // default is 604,800 = 7 days of seconds
            }
            uint elapsedSecondsSinceLastPayout = currentTime - buyerLastPaidAtTime;
            uint buyerNowOwes = buyerOwes;
            uint buyerPaid = 0;
            bool overdrafted = false;

            (buyerPaid, overdrafted) = chargeBuyer(apiId, buyerAddress, elapsedSecondsSinceLastPayout, buyerOwes);

            totalPayable = totalPayable.add(buyerPaid);
            buyerNowOwes = buyerOwes.sub(buyerPaid);
            apiBalance.amounts[buyerAddress] = buyerNowOwes;

            // if the buyer still owes something, make sure we keep them in the nonzeroAddresses array
            if (buyerNowOwes != 0) {
                apiBalance.nonzeroAddresses.push(buyerAddress);
            }
            // if the buyer paid more than 0, log the spend.
            if (buyerPaid != 0) {
                // log the event
                emit LogSpendCredits(buyerAddress, apiId, buyerPaid, overdrafted);

                // log that they paid
                apiBalance.buyerLastPaidAt[buyerAddress] = now;

                // add to total buyer count
                totalBuyers += 1;
            }
        }
    }

    // ------------------------------------------------------------------------
    // given a specific buyer, api, and the amount they owe, we need to figure out how much to pay
    // the final amount paid is based on the chart below:
    // if credits >= approved >= owed then pay owed
    // if credits >= owed > approved then pay approved and mark as exceeded approved amount
    // if owed > credits >= approved then pay approved and mark as overdrafted
    // if owed > approved > credits then pay credits and mark as overdrafted
    // ------------------------------------------------------------------------
    function chargeBuyer(
        uint apiId, 
        address buyerAddress, 
        uint elapsedSecondsSinceLastPayout, 
        uint buyerOwes
    ) 
        private 
        returns (
            uint paid, 
            bool overdrafted
        ) 
    {
        BuyerInfo storage buyer = buyers[buyerAddress];
        uint approvedAmountPerSecond = buyer.approvedAmounts[apiId];
        uint approvedAmountSinceLastPayout = approvedAmountPerSecond.mul(elapsedSecondsSinceLastPayout);
        
        // do we have the credits to pay owed?
        if (buyer.credits >= buyerOwes) {
            // yay, buyer can pay their debits
            overdrafted = false;
            buyer.overdrafted = false;

            // has buyer approved enough to pay what they owe?
            if (approvedAmountSinceLastPayout >= buyerOwes) {
                // approved is greater than owed.  
                // mark as not exceeded approved amount
                buyer.exceededApprovedAmount[apiId] = false;

                // we can pay the entire debt
                paid = buyerOwes;

            } else {
                // they have no approved enough
                // mark as exceeded
                buyer.exceededApprovedAmount[apiId] = true;
                buyer.lifetimeExceededApprovalAmountCount += 1;

                // we can only pay the approved portion of the debt
                paid = approvedAmountSinceLastPayout;
            }
        } else {
            // buyer spent more than they have.  mark as overdrafted
            overdrafted = true;
            buyer.overdrafted = true;
            buyer.lifetimeOverdraftCount += 1;

            // does buyer have more credits than the amount they&#39;ve approved?
            if (buyer.credits >= approvedAmountSinceLastPayout) {
                // they have enough credits to pay approvedAmountSinceLastPayout, so pay that
                paid = approvedAmountSinceLastPayout;

            } else {
                // the don&#39;t have enough credits to pay approvedAmountSinceLastPayout
                // so just pay whatever credits they have
                paid = buyer.credits;
            }
        }

        buyer.credits = buyer.credits.sub(paid);
        buyer.lifetimeCreditsUsed = buyer.lifetimeCreditsUsed.add(paid);
    }

    function removeAddressFromNonzeroBalancesArray(uint apiId, address toRemove) private {
        APIBalance storage apiBalance = owed[apiId];

        bool foundElement = false;

        for (uint i = 0; i < apiBalance.nonzeroAddresses.length-1; i++) {
            if (apiBalance.nonzeroAddresses[i] == toRemove) {
                foundElement = true;
            }
            if (foundElement == true) {
                apiBalance.nonzeroAddresses[i] = apiBalance.nonzeroAddresses[i+1];
            }
        }
        if (foundElement == true) {
            apiBalance.nonzeroAddresses.length--;
        }
    }
}