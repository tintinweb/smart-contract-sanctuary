pragma solidity 0.4.24;

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

contract ERC20Extended is ERC20 {
    uint256 public decimals;
    string public name;
    string public symbol;

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

contract ComponentContainerInterface {
    mapping (string => address) components;

    event ComponentUpdated (string _name, address _componentAddress);

    function setComponent(string _name, address _providerAddress) internal returns (bool success);
    function getComponentByName(string name) public view returns (address);

}

contract DerivativeInterface is ERC20Extended, Ownable, ComponentContainerInterface {

    enum DerivativeStatus { New, Active, Paused, Closed }
    enum DerivativeType { Index, Fund }

    string public description;
    string public category;
    string public version;
    DerivativeType public fundType;

    address[] public tokens;
    DerivativeStatus public status;

    // invest, withdraw is done in transfer.
    function invest() public payable returns(bool success);
    function changeStatus(DerivativeStatus _status) public returns(bool);
    function getPrice() public view returns(uint);

    function initialize (address _componentList) internal;
    function updateComponent(string _name) public returns (address);
    function approveComponent(string _name) internal;
}

contract ComponentContainer is ComponentContainerInterface {

    function setComponent(string _name, address _componentAddress) internal returns (bool success) {
        require(_componentAddress != address(0));
        components[_name] = _componentAddress;
        return true;
    }

    function getComponentByName(string _name) public view returns (address) {
        return components[_name];
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

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract ComponentListInterface {
    event ComponentUpdated (string _name, string _version, address _componentAddress);
    function setComponent(string _name, address _componentAddress) public returns (bool);
    function getComponent(string _name, string _version) public view returns (address);
    function getLatestComponent(string _name) public view returns(address);
}

contract ERC20NoReturn {
    uint256 public decimals;
    string public name;
    string public symbol;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public;
    function approve(address spender, uint tokens) public;
    function transferFrom(address from, address to, uint tokens) public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract FeeChargerInterface {
    // TODO: change this to mainnet MOT address before deployment.
    // solhint-disable-next-line
    ERC20Extended public MOT = ERC20Extended(0x263c618480DBe35C300D8d5EcDA19bbB986AcaeD);
    // kovan MOT: 0x41Dee9F481a1d2AA74a3f1d0958C1dB6107c686A
    function setMotAddress(address _motAddress) external returns (bool success);
}

// Abstract class that implements the common functions to all our derivatives
contract Derivative is DerivativeInterface, ComponentContainer, PausableToken {

    ERC20Extended internal constant ETH = ERC20Extended(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ComponentListInterface internal componentList;
    string public constant MARKET = "MarketProvider";
    string public constant EXCHANGE = "ExchangeProvider";
    string public constant WITHDRAW = "WithdrawProvider";
    string public constant RISK = "RiskProvider";
    string public constant WHITELIST = "WhitelistProvider";
    string public constant FEE = "FeeProvider";
    string public constant REIMBURSABLE = "Reimbursable";
    string public constant REBALANCE = "RebalanceProvider";

    function initialize (address _componentList) internal {
        require(_componentList != 0x0);
        componentList = ComponentListInterface(_componentList);
    }

    function updateComponent(string _name) public onlyOwner returns (address) {
        // still latest.
        if (super.getComponentByName(_name) == componentList.getLatestComponent(_name)) {
            return super.getComponentByName(_name);
        }

        // changed.
        require(super.setComponent(_name, componentList.getLatestComponent(_name)));
        // approve if it&#39;s not Marketplace.
        if (keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(MARKET))) {
            approveComponent(_name);
        }

        // return latest address.
        return componentList.getLatestComponent(_name);
    }



    function approveComponent(string _name) internal {
        address componentAddress = getComponentByName(_name);
        ERC20NoReturn(FeeChargerInterface(componentAddress).MOT()).approve(componentAddress, 0);
        ERC20NoReturn(FeeChargerInterface(componentAddress).MOT()).approve(componentAddress, 2 ** 256 - 1);
    }

    function () public payable {

    }
}

contract IndexInterface is DerivativeInterface {
    uint[] public weights;
    bool public supportRebalance;

    // this should be called until it returns true.
    function rebalance() public returns (bool success);
    function getTokens() public view returns (address[] _tokens, uint[] _weights);
}

contract ComponentInterface {
    string public name;
    string public description;
    string public category;
    string public version;
}

contract ExchangeInterface is ComponentInterface {
    /*
     * @dev Checks if a trading pair is available
     * For ETH, use 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
     * @param address _sourceAddress The token to sell for the destAddress.
     * @param address _destAddress The token to buy with the source token.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @return boolean whether or not the trading pair is supported by this exchange provider
     */
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId)
        external view returns(bool supported);

    /*
     * @dev Buy a single token with ETH.
     * @param ERC20Extended _token The token to buy, should be an ERC20Extended address.
     * @param uint _amount Amount of ETH used to buy this token. Make sure the value sent to this function is the same as the _amount.
     * @param uint _minimumRate The minimum amount of tokens to receive for 1 ETH.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here.
     * @return boolean whether or not the trade succeeded.
     */
    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external payable returns(bool success);

    /*
     * @dev Sell a single token for ETH. Make sure the token is approved beforehand.
     * @param ERC20Extended _token The token to sell, should be an ERC20Extended address.
     * @param uint _amount Amount of tokens to sell.
     * @param uint _minimumRate The minimum amount of ETH to receive for 1 ERC20Extended token.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external returns(bool success);
}

contract PriceProviderInterface is ComponentInterface {
    /*
     * @dev Returns the expected price for 1 of sourceAddress.
     * For ETH, use 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
     * @param address _sourceAddress The token to sell for the destAddress.
     * @param address _destAddress The token to buy with the source token.
     * @param uint _amount The amount of tokens which is wanted to buy.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @return returns the expected and slippage rate for the specified conversion
     */
    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate);
}

contract OlympusExchangeInterface is ExchangeInterface, PriceProviderInterface, Ownable {
    /*
     * @dev Buy multiple tokens at once with ETH.
     * @param ERC20Extended[] _tokens The tokens to buy, should be an array of ERC20Extended addresses.
     * @param uint[] _amounts Amount of ETH used to buy this token. Make sure the value sent to this function is the same as the sum of this array.
     * @param uint[] _minimumRates The minimum amount of tokens to receive for 1 ETH.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function buyTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external payable returns(bool success);

    /*
     * @dev Sell multiple tokens at once with ETH, make sure all of the tokens are approved to be transferred beforehand with the Olympus Exchange address.
     * @param ERC20Extended[] _tokens The tokens to sell, should be an array of ERC20Extended addresses.
     * @param uint[] _amounts Amount of tokens to sell this token. Make sure the value sent to this function is the same as the sum of this array.
     * @param uint[] _minimumRates The minimum amount of ETH to receive for 1 specified ERC20Extended token.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function sellTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external returns(bool success);
}

contract RebalanceInterface is ComponentInterface {
    // this should be called until it returns true.
    function recalculateTokensToBuyAfterSale(uint _receivedETHFromSale, uint[] _amountsToBuy) external pure
        returns(uint[] _recalculatedAmountsToBuy);
    function rebalanceGetTokensToSellAndBuy() external returns
        (address[] _tokensToSell, uint[] _amountsToSell, address[] _tokensToBuy, uint[] _amountsToBuy, address[] _tokensWithPriceIssues);
}

contract WithdrawInterface is ComponentInterface {

    function request(address _requester, uint amount) external returns(bool);
    function withdraw(address _requester) external returns(uint eth, uint tokens);
    function start() external;
    function isInProgress() external view returns(bool);
    function unlock() external;
    function getUserRequests() external view returns(address[]);
    function getTotalWithdrawAmount() external view returns(uint);

    event WithdrawRequest(address _requester, uint amountOfToken);
    event Withdrawed(address _requester,  uint amountOfToken , uint amountOfEther);
}

contract WhitelistInterface is ComponentInterface {

    // sender -> category -> user -> allowed
    mapping (address => mapping(uint8 => mapping(address => bool))) public whitelist;
    // sender -> category -> enabled
    mapping (address => mapping(uint8 => bool)) public enabled;

    function enable(uint8 _key) external;
    function disable(uint8 _key) external;
    function isAllowed(uint8 _key, address _account) external view returns(bool);
    function setAllowed(address[] accounts, uint8 _key, bool allowed) external returns(bool);
}

contract MarketplaceInterface is Ownable {

    address[] public products;
    mapping(address => address[]) public productMappings;

    function getAllProducts() external view returns (address[] allProducts);
    function registerProduct() external returns(bool success);
    function getOwnProducts() external view returns (address[] addresses);

    event Registered(address product, address owner);
}

contract ChargeableInterface is ComponentInterface {

    uint public DENOMINATOR;
    function calculateFee(address _caller, uint _amount) external returns(uint totalFeeAmount);
    function setFeePercentage(uint _fee) external returns (bool succes);
    function getFeePercentage() external view returns (uint feePercentage);

 }

contract ReimbursableInterface is ComponentInterface {

    // this should be called at the beginning of a function.
    // such as rebalance and withdraw.
    function startGasCalculation() external;
    // this should be called at the last moment of the function.
    function reimburse() external returns (uint);

}

contract RiskControlInterface is ComponentInterface {
    function hasRisk(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate)
        external returns(bool isRisky);
}

contract OlympusIndex is IndexInterface, Derivative {
    using SafeMath for uint256;

    enum WhitelistKeys { Investment, Maintenance }

    event ChangeStatus(DerivativeStatus status);
    event Invested(address user, uint amount);
    event Reimbursed(uint amount);
    event  RiskEvent(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate, bool risky);

    uint public constant DENOMINATOR = 100000;
    uint public constant INITIAL_VALUE =  10**18;
    uint[] public weights;
    uint public accumulatedFee = 0;
    uint public maxTransfers = 10;

    // If whitelist is disabled, that will become onlyOwner
    modifier onlyOwnerOrWhitelisted(WhitelistKeys _key) {
        WhitelistInterface whitelist = WhitelistInterface(getComponentByName(WHITELIST));
        require(
            msg.sender == owner ||
            (whitelist.enabled(address(this), uint8(_key)) && whitelist.isAllowed(uint8(_key), msg.sender) )
        );
        _;
    }

    // If whitelist is disabled, anyone can do this
    modifier whitelisted(WhitelistKeys _key) {
        require(WhitelistInterface(getComponentByName(WHITELIST)).isAllowed(uint8(_key), msg.sender));
        _;
    }

    modifier withoutRisk(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate) {
        require(!hasRisk(_sender, _receiver, _tokenAddress, _amount, _rate));
        _;
    }

    modifier checkLength(address[] _tokens, uint[] _weights) {
        require(_tokens.length == _weights.length);
        _;
    }

    modifier checkWeights(uint[] _weights){
        uint totalWeight;
        for(uint i = 0; i < _weights.length; i++){
            totalWeight += _weights[i];
        }
        require(totalWeight == 100);
        _;
    }

    constructor (
      string _name,
      string _symbol,
      string _description,
      string _category,
      uint _decimals,
      address[] _tokens,
      uint[] _weights)
      checkLength(_tokens, _weights) checkWeights(_weights) public {
        name = _name;
        symbol = _symbol;
        totalSupply_ = 0;
        decimals = _decimals;
        description = _description;
        category = _category;
        version = "1.0";
        fundType = DerivativeType.Index;
        tokens = _tokens;
        weights = _weights;
        status = DerivativeStatus.New;
    }

    // ----------------------------- CONFIG -----------------------------
    function initialize(address _componentList, uint _initialFundFee) onlyOwner external payable {
        require(status == DerivativeStatus.New);
        require(msg.value > 0); // Require some balance for internal opeations as reimbursable
        require(_componentList != 0x0);

        super.initialize(_componentList);

        setComponent(MARKET, componentList.getLatestComponent(MARKET));
        setComponent(EXCHANGE, componentList.getLatestComponent(EXCHANGE));
        setComponent(REBALANCE, componentList.getLatestComponent(REBALANCE));
        setComponent(RISK, componentList.getLatestComponent(RISK));
        setComponent(WHITELIST, componentList.getLatestComponent(WHITELIST));
        setComponent(FEE, componentList.getLatestComponent(FEE));
        setComponent(REIMBURSABLE, componentList.getLatestComponent(REIMBURSABLE));
        setComponent(WITHDRAW, componentList.getLatestComponent(WITHDRAW));

        // approve component for charging fees.
        approveComponents();

        MarketplaceInterface(componentList.getLatestComponent(MARKET)).registerProduct();
        ChargeableInterface(componentList.getLatestComponent(FEE)).setFeePercentage(_initialFundFee);

        status = DerivativeStatus.Active;

        emit ChangeStatus(status);

        accumulatedFee += msg.value;
    }

    // Call after you have updated the MARKET provider, not required after initialize
    function registerInNewMarketplace() external onlyOwner returns(bool) {
        require(MarketplaceInterface(getComponentByName(MARKET)).registerProduct());
        return true;
    }

    // Return tokens and weights
    function getTokens() public view returns (address[] _tokens, uint[] _weights) {
        return (tokens, weights);
    }
    // Return tokens and amounts
    function getTokensAndAmounts() external view returns(address[], uint[]) {
        uint[] memory _amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _amounts[i] = ERC20Extended(tokens[i]).balanceOf(address(this));
        }
        return (tokens, _amounts);
    }

    function changeStatus(DerivativeStatus _status) public onlyOwner returns(bool) {
        require(_status != DerivativeStatus.New && status != DerivativeStatus.New && _status != DerivativeStatus.Closed);
        require(status != DerivativeStatus.Closed && _status != DerivativeStatus.Closed);

        status = _status;
        emit ChangeStatus(status);
        return true;
    }

    function close() public onlyOwner returns(bool success){
        require(status != DerivativeStatus.New);
        getETHFromTokens(DENOMINATOR); // 100% all the tokens
        status = DerivativeStatus.Closed;
        emit ChangeStatus(status);
        return true;
    }

    // ----------------------------- DERIVATIVE -----------------------------

    function invest() public payable
     whenNotPaused
     whitelisted(WhitelistKeys.Investment)
     withoutRisk(msg.sender, address(this), ETH, msg.value, 1)
     returns(bool) {
        require(status == DerivativeStatus.Active, "The Fund is not active");
        require(msg.value >= 10**15, "Minimum value to invest is 0.001 ETH");
         // Current value is already added in the balance, reduce it
        uint _sharePrice;

        if(totalSupply_ > 0) {
            _sharePrice = getPrice() - ( (msg.value * 10 ** decimals ) / totalSupply_);
         } else {
            _sharePrice = INITIAL_VALUE;
        }

        ChargeableInterface feeManager = ChargeableInterface(getComponentByName(FEE));
        uint fee = feeManager.calculateFee(msg.sender, msg.value);

        uint _investorShare = ( ( (msg.value-fee) * DENOMINATOR) / _sharePrice) * 10 ** decimals;
        _investorShare = _investorShare / DENOMINATOR;

        accumulatedFee += fee;
        balances[msg.sender] += _investorShare;
        totalSupply_ += _investorShare;

        emit Invested(msg.sender, _investorShare);
        return true;
    }

    function getPrice() public view returns(uint)  {
        if(totalSupply_ == 0) {
            return INITIAL_VALUE;
        }

        // Total Value in ETH among its tokens + ETH new added value
        return (
          ((getAssetsValue() + getETHBalance() ) * 10 ** decimals ) / (totalSupply_),
        );
    }

    function getETHBalance() public view returns(uint){
        return address(this).balance - accumulatedFee;
    }

    function getAssetsValue() public view returns (uint) {
        // TODO cast to OlympusExchangeInterface
        OlympusExchangeInterface exchangeProvider = OlympusExchangeInterface(getComponentByName(EXCHANGE));
        uint _totalTokensValue = 0;
        // Iterator
        uint _expectedRate;
        uint _balance;

        for (uint16 i = 0; i < tokens.length; i++) {

            _balance = ERC20(tokens[i]).balanceOf(address(this));

            if(_balance == 0){continue;}

            (_expectedRate, ) = exchangeProvider.getPrice(ETH, ERC20Extended(tokens[i]), _balance, 0x0);

            if(_expectedRate == 0){continue;}
            _totalTokensValue += (_balance * 10**18) / _expectedRate;

        }
        return _totalTokensValue;
    }

    // ----------------------------- FEES  -----------------------------
    // Owner can send ETH to the Index, to perform some task, this eth belongs to him
    function addOwnerBalance() external payable onlyOwner {
        accumulatedFee += msg.value;
    }

    function withdrawFee(uint amount) external onlyOwner whenNotPaused returns(bool) {
        require(accumulatedFee >= amount);
        accumulatedFee -= amount;
        msg.sender.transfer(amount);
        return true;
    }

    function setManagementFee(uint _fee) external onlyOwner {
        ChargeableInterface(getComponentByName(FEE)).setFeePercentage(_fee);
    }

    function getManagementFee() external view returns(uint) {
        return ChargeableInterface(getComponentByName(FEE)).getFeePercentage();
    }

    // ----------------------------- WITHDRAW -----------------------------
    function requestWithdraw(uint amount) external
     whitelisted(WhitelistKeys.Investment)
     withoutRisk(msg.sender, address(this), address(this), amount, getPrice())
    {
        WithdrawInterface(getComponentByName(WITHDRAW)).request(msg.sender, amount);
    }

    function setMaxTransfers(uint _maxTransfers) external onlyOwner {
        maxTransfers = _maxTransfers;
    }

    function withdraw() external onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) whenNotPaused returns(bool) {

        ReimbursableInterface(getComponentByName(REIMBURSABLE)).startGasCalculation();
        WithdrawInterface withdrawProvider = WithdrawInterface(getComponentByName(WITHDRAW));
        // Check if there is request
        address[] memory _requests = withdrawProvider.getUserRequests();
        if(_requests.length == 0) {
            reimburse();
            return true;
        }

        uint _transfers = 0;
        uint _eth;
        uint tokens;

        if (!withdrawProvider.isInProgress()) {
            withdrawProvider.start();
        }
        uint _totalETHToReturn = ( withdrawProvider.getTotalWithdrawAmount() * getPrice()) / 10 ** decimals;

        if(_totalETHToReturn > getETHBalance()) {
            uint _tokenPercentToSell = (( _totalETHToReturn - getETHBalance()) * DENOMINATOR) / getAssetsValue();
            getETHFromTokens(_tokenPercentToSell);
        }

        for(uint8 i = 0; i < _requests.length && _transfers < maxTransfers ; i++) {


            (_eth, tokens) = withdrawProvider.withdraw(_requests[i]);
            if(tokens == 0) {continue;}

            balances[_requests[i]] -= tokens;
            totalSupply_ -= tokens;
            address(_requests[i]).transfer(_eth);
            _transfers++;
        }

        if(!withdrawProvider.isInProgress()) {
            withdrawProvider.unlock();
        }
        reimburse();
        return !withdrawProvider.isInProgress(); // True if completed
    }

    function withdrawInProgress() external view returns(bool) {
        return  WithdrawInterface(getComponentByName(WITHDRAW)).isInProgress();
    }

    function reimburse() internal {
        uint reimbursedAmount = ReimbursableInterface(getComponentByName(REIMBURSABLE)).reimburse();
        accumulatedFee -= reimbursedAmount;
        emit Reimbursed(reimbursedAmount);
        msg.sender.transfer(reimbursedAmount);
    }

    function tokensWithAmount() public view returns( ERC20Extended[] memory) {
        // First check the length
        uint8 length = 0;
        uint[] memory _amounts = new uint[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            _amounts[i] = ERC20Extended(tokens[i]).balanceOf(address(this));
            if(_amounts[i] > 0) {length++;}
        }

        ERC20Extended[] memory _tokensWithAmount = new ERC20Extended[](length);
        // Then create they array
        uint8 index = 0;
        for (uint8 j = 0; j < tokens.length; j++) {
            if(_amounts[j] > 0) {
                _tokensWithAmount[index] = ERC20Extended(tokens[j]);
                index++;
            }
        }
        return _tokensWithAmount;
    }

    function getETHFromTokens(uint _tokenPercentage ) internal {
        ERC20Extended[] memory _tokensToSell = tokensWithAmount();
        uint[] memory _amounts = new uint[](  _tokensToSell.length);
        uint[] memory _sellRates = new uint[]( _tokensToSell.length);
        OlympusExchangeInterface exchange = OlympusExchangeInterface(getComponentByName(EXCHANGE));

        for (uint8 i = 0; i < _tokensToSell.length; i++) {

            _amounts[i] = (_tokenPercentage * _tokensToSell[i].balanceOf(address(this)) )/DENOMINATOR;
            ( , _sellRates[i] ) = exchange.getPrice(_tokensToSell[i], ETH, _amounts[i], 0x0);
            require(!hasRisk(address(this), exchange, address( _tokensToSell[i]), _amounts[i] , 0));
            _tokensToSell[i].approve(exchange,  0);
            _tokensToSell[i].approve(exchange,  _amounts[i]);
        }
        require(exchange.sellTokens(_tokensToSell, _amounts, _sellRates, address(this), 0x0, 0x0));

    }

    // ----------------------------- REBALANCE -----------------------------

    function buyTokens() external onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) whenNotPaused returns(bool) {

        ReimbursableInterface(getComponentByName(REIMBURSABLE)).startGasCalculation();
        OlympusExchangeInterface exchange = OlympusExchangeInterface(getComponentByName(EXCHANGE));


        if(getETHBalance() == 0) {
            reimburse();
            return true;
        }
        uint[] memory _amounts = new uint[](tokens.length);
        uint[] memory _rates = new uint[](tokens.length); // Initialize to 0, making sure any rate is fine
        ERC20Extended[] memory _tokensErc20 = new ERC20Extended[](tokens.length); // Initialize to 0, making sure any rate is fine
        uint ethBalance = getETHBalance();
        uint totalAmount = 0;

        for(uint8 i = 0; i < tokens.length; i++) {
            _amounts[i] = ethBalance * weights[i] / 100;
            _tokensErc20[i] = ERC20Extended(tokens[i]);
            (, _rates[i] ) = exchange.getPrice(ETH,  _tokensErc20[i],  _amounts[i], 0x0);
            totalAmount += _amounts[i];
        }

        require(exchange.buyTokens.value(totalAmount)(_tokensErc20, _amounts, _rates, address(this), 0x0, 0x0));

        reimburse();
        return true;
    }

    function rebalance() public onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) whenNotPaused returns (bool success) {
        ReimbursableInterface(getComponentByName(REIMBURSABLE)).startGasCalculation();
        RebalanceInterface rebalanceProvider = RebalanceInterface(getComponentByName(REBALANCE));
        OlympusExchangeInterface exchangeProvider = OlympusExchangeInterface(getComponentByName(EXCHANGE));
        address[] memory tokensToSell;
        uint[] memory amountsToSell;
        address[] memory tokensToBuy;
        uint[] memory amountsToBuy;
        uint8 i;
        uint ETHBalanceBefore = address(this).balance;

        (tokensToSell, amountsToSell, tokensToBuy, amountsToBuy,) = rebalanceProvider.rebalanceGetTokensToSellAndBuy();
        // Sell Tokens
        for (i = 0; i < tokensToSell.length; i++) {
            ERC20Extended(tokensToSell[i]).approve(address(exchangeProvider), 0);
            ERC20Extended(tokensToSell[i]).approve(address(exchangeProvider), amountsToSell[i]);
            require(exchangeProvider.sellToken(ERC20Extended(tokensToSell[i]), amountsToSell[i], 0, address(this), 0x0, 0x0));

        }

        // Buy Tokens
        amountsToBuy = rebalanceProvider.recalculateTokensToBuyAfterSale(address(this).balance - ETHBalanceBefore, amountsToBuy);
        for (i = 0; i < tokensToBuy.length; i++) {
            require(
                exchangeProvider.buyToken.value(amountsToBuy[i])(ERC20Extended(tokensToBuy[i]), amountsToBuy[i], 0, address(this), 0x0, 0x0)
            );
        }

        reimburse();
        return true;
    }

    // ----------------------------- WHITELIST -----------------------------

    function enableWhitelist(WhitelistKeys _key) external onlyOwner returns(bool) {
        WhitelistInterface(getComponentByName(WHITELIST)).enable(uint8(_key));
        return true;
    }

    function disableWhitelist(WhitelistKeys _key) external onlyOwner returns(bool) {
        WhitelistInterface(getComponentByName(WHITELIST)).disable(uint8(_key));
        return true;
    }

    function setAllowed(address[] accounts, WhitelistKeys _key,  bool allowed) onlyOwner public returns(bool){
        WhitelistInterface(getComponentByName(WHITELIST)).setAllowed(accounts,uint8(_key), allowed);
        return true;
    }

    function approveComponents() private {
        approveComponent(EXCHANGE);
        approveComponent(WITHDRAW);
        approveComponent(RISK);
        approveComponent(WHITELIST);
        approveComponent(FEE);
        approveComponent(REIMBURSABLE);
        approveComponent(REBALANCE);
    }

    function updateAllComponents() public onlyOwner {
        updateComponent(MARKET);
        updateComponent(EXCHANGE);
        updateComponent(WITHDRAW);
        updateComponent(RISK);
        updateComponent(WHITELIST);
        updateComponent(FEE);
        updateComponent(REBALANCE);
        updateComponent(REIMBURSABLE);
    }

    function hasRisk(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate) public returns(bool) {
        RiskControlInterface riskControl = RiskControlInterface(getComponentByName(RISK));
        bool risk = riskControl.hasRisk(_sender, _receiver, _tokenAddress, _amount, _rate);
        emit RiskEvent (_sender, _receiver, _tokenAddress, _amount, _rate, risk);
        return risk;
    }
}