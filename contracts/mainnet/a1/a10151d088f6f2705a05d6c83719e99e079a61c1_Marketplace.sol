pragma solidity ^0.4.22;

// File: node_modules/zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/Marketplace.sol

// Note about numbers:
//   All prices and exchange rates are in "decimal fixed-point", that is, scaled by 10^18, like ETH vs wei.
//   Seconds are integers as usual.
contract Marketplace is Ownable {
    using SafeMath for uint256;

    // product events
    event ProductCreated(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductUpdated(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductDeleted(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductRedeployed(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds);
    event ProductOwnershipOffered(address indexed owner, bytes32 indexed id, address indexed to);
    event ProductOwnershipChanged(address indexed newOwner, bytes32 indexed id, address indexed oldOwner);

    // subscription events
    event Subscribed(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event NewSubscription(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionExtended(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionTransferred(bytes32 indexed productId, address indexed from, address indexed to, uint secondsTransferred);

    // currency events
    event ExchangeRatesUpdated(uint timestamp, uint dataInUsd);

    enum ProductState {
        NotDeployed,                // non-existent or deleted
        Deployed                    // created or redeployed
    }

    enum Currency {
        DATA,                       // "token wei" (10^-18 DATA)
        USD                         // attodollars (10^-18 USD)
    }

    struct Product {
        bytes32 id;
        string name;
        address owner;
        address beneficiary;        // account where revenue is directed to
        uint pricePerSecond;
        Currency priceCurrency;
        uint minimumSubscriptionSeconds;
        ProductState state;
        mapping(address => TimeBasedSubscription) subscriptions;
        address newOwnerCandidate;  // Two phase hand-over to minimize the chance that the product ownership is lost to a non-existent address.
    }

    struct TimeBasedSubscription {        
        uint endTimestamp;
    }

    /////////////// Marketplace lifecycle /////////////////

    ERC20 public datacoin;

    address public currencyUpdateAgent;

    function Marketplace(address datacoinAddress, address currencyUpdateAgentAddress) Ownable() public {        
        _initialize(datacoinAddress, currencyUpdateAgentAddress);
    }

    function _initialize(address datacoinAddress, address currencyUpdateAgentAddress) internal {
        currencyUpdateAgent = currencyUpdateAgentAddress;
        datacoin = ERC20(datacoinAddress);
    }

    ////////////////// Product management /////////////////

    mapping (bytes32 => Product) public products;
    function getProduct(bytes32 id) public view returns (string name, address owner, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds, ProductState state) {
        return (
            products[id].name,
            products[id].owner,
            products[id].beneficiary,
            products[id].pricePerSecond,
            products[id].priceCurrency,
            products[id].minimumSubscriptionSeconds,
            products[id].state
        );
    }

    // also checks that p exists: p.owner == 0 for non-existent products    
    modifier onlyProductOwner(bytes32 productId) {
        Product storage p = products[productId];
        require(p.id != 0x0, "error_notFound");
        require(p.owner == msg.sender || owner == msg.sender, "error_productOwnersOnly");
        _;
    }

    function createProduct(bytes32 id, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds) public whenNotHalted {
        require(id != 0x0, "error_nullProductId");
        require(pricePerSecond > 0, "error_freeProductsNotSupported");
        Product storage p = products[id];
        require(p.id == 0x0, "error_alreadyExists");
        products[id] = Product(id, name, msg.sender, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds, ProductState.Deployed, 0);
        emit ProductCreated(msg.sender, id, name, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds);
    }

    /**
    * Stop offering the product
    */
    function deleteProduct(bytes32 productId) public onlyProductOwner(productId) {        
        Product storage p = products[productId];
        require(p.state == ProductState.Deployed, "error_notDeployed");
        p.state = ProductState.NotDeployed;
        emit ProductDeleted(p.owner, productId, p.name, p.beneficiary, p.pricePerSecond, p.priceCurrency, p.minimumSubscriptionSeconds);
    }

    /**
    * Return product to market
    */
    function redeployProduct(bytes32 productId) public onlyProductOwner(productId) {        
        Product storage p = products[productId];
        require(p.state == ProductState.NotDeployed, "error_mustBeNotDeployed");
        p.state = ProductState.Deployed;
        emit ProductRedeployed(p.owner, productId, p.name, p.beneficiary, p.pricePerSecond, p.priceCurrency, p.minimumSubscriptionSeconds);
    }

    function updateProduct(bytes32 productId, string name, address beneficiary, uint pricePerSecond, Currency currency, uint minimumSubscriptionSeconds) public onlyProductOwner(productId) {
        require(pricePerSecond > 0, "error_freeProductsNotSupported");
        Product storage p = products[productId]; 
        p.name = name;
        p.beneficiary = beneficiary;
        p.pricePerSecond = pricePerSecond;
        p.priceCurrency = currency;
        p.minimumSubscriptionSeconds = minimumSubscriptionSeconds;        
        emit ProductUpdated(p.owner, p.id, name, beneficiary, pricePerSecond, currency, minimumSubscriptionSeconds);
    }

    /**
    * Changes ownership of the product. Two phase hand-over minimizes the chance that the product ownership is lost to a non-existent address.
    */
    function offerProductOwnership(bytes32 productId, address newOwnerCandidate) public onlyProductOwner(productId) {
        // that productId exists is already checked in onlyProductOwner
        products[productId].newOwnerCandidate = newOwnerCandidate;
        emit ProductOwnershipOffered(products[productId].owner, productId, newOwnerCandidate);
    }

    /**
    * Changes ownership of the product. Two phase hand-over minimizes the chance that the product ownership is lost to a non-existent address.
    */
    function claimProductOwnership(bytes32 productId) public whenNotHalted {
        // also checks that productId exists (newOwnerCandidate is zero for non-existent)
        Product storage p = products[productId]; 
        require(msg.sender == p.newOwnerCandidate, "error_notPermitted");
        emit ProductOwnershipChanged(msg.sender, productId, p.owner);
        p.owner = msg.sender;
        p.newOwnerCandidate = 0;
    }

    /////////////// Subscription management ///////////////

    function getSubscription(bytes32 productId, address subscriber) public view returns (bool isValid, uint endTimestamp) {
        TimeBasedSubscription storage sub;
        (isValid, , sub) = _getSubscription(productId, subscriber);
        endTimestamp = sub.endTimestamp;        
    }

    function getSubscriptionTo(bytes32 productId) public view returns (bool isValid, uint endTimestamp) {
        return getSubscription(productId, msg.sender);
    }

    /**
     * Purchases access to this stream for msg.sender.
     * If the address already has a valid subscription, extends the subscription by the given period.
     */
    function buy(bytes32 productId, uint subscriptionSeconds) public whenNotHalted {
        var (, product, sub) = _getSubscription(productId, msg.sender);
        require(product.state == ProductState.Deployed, "error_notDeployed");
        _addSubscription(product, msg.sender, subscriptionSeconds, sub);

        uint price = getPriceInData(subscriptionSeconds, product.pricePerSecond, product.priceCurrency);        
        require(datacoin.transferFrom(msg.sender, product.beneficiary, price), "error_paymentFailed");
    }

    /**
    * Checks if the given address currently has a valid subscription
    */
    function hasValidSubscription(bytes32 productId, address subscriber) public constant returns (bool isValid) {
        (isValid, ,) = _getSubscription(productId, subscriber);
    }

    /**
    * Transfer a valid subscription from msg.sender to a new address.
    * If the address already has a valid subscription, extends the subscription by the msg.sender&#39;s remaining period.
    */
    function transferSubscription(bytes32 productId, address newSubscriber) public whenNotHalted {
        var (isValid, product, sub) = _getSubscription(productId, msg.sender);
        require(isValid, "error_subscriptionNotValid");
        uint secondsLeft = sub.endTimestamp.sub(block.timestamp);        
        TimeBasedSubscription storage newSub = product.subscriptions[newSubscriber];
        _addSubscription(product, newSubscriber, secondsLeft, newSub);
        delete product.subscriptions[msg.sender];
        emit SubscriptionTransferred(productId, msg.sender, newSubscriber, secondsLeft);
    }

    function _getSubscription(bytes32 productId, address subscriber) internal constant returns (bool subIsValid, Product storage, TimeBasedSubscription storage) {
        Product storage p = products[productId];
        require(p.id != 0x0, "error_notFound");
        TimeBasedSubscription storage s = p.subscriptions[subscriber];
        return (s.endTimestamp >= block.timestamp, p, s);
    }
    
    function _addSubscription(Product storage p, address subscriber, uint addSeconds, TimeBasedSubscription storage oldSub) internal {
        uint endTimestamp;
        if (oldSub.endTimestamp > block.timestamp) {
            require(addSeconds > 0, "error_topUpTooSmall");
            endTimestamp = oldSub.endTimestamp.add(addSeconds);
            oldSub.endTimestamp = endTimestamp;  
            emit SubscriptionExtended(p.id, subscriber, endTimestamp);
        } else {
            require(addSeconds >= p.minimumSubscriptionSeconds, "error_newSubscriptionTooSmall");
            endTimestamp = block.timestamp.add(addSeconds);
            TimeBasedSubscription memory newSub = TimeBasedSubscription(endTimestamp);
            p.subscriptions[subscriber] = newSub;
            emit NewSubscription(p.id, subscriber, endTimestamp);
        }
        emit Subscribed(p.id, subscriber, endTimestamp);
    }

    // TODO: transfer allowance to another Marketplace contract
    // Mechanism basically is that this Marketplace draws from the allowance and credits
    //   the account on another Marketplace; OR that there is a central credit pool (say, an ERC20 token)
    // Creating another ERC20 token for this could be a simple fix: it would need the ability to transfer allowances

    /////////////// Currency management ///////////////    

    // Exchange rates are formatted as "decimal fixed-point", that is, scaled by 10^18, like ether.
    //        Exponent: 10^18 15 12  9  6  3  0
    //                      |  |  |  |  |  |  |
    uint public dataPerUsd = 100000000000000000;   // ~= 0.1 DATA/USD

    /**
    * Update currency exchange rates; all purchases are still billed in DATAcoin
    * @param timestamp in seconds when the exchange rates were last updated
    * @param dataUsd how many data atoms (10^-18 DATA) equal one USD dollar
    */
    function updateExchangeRates(uint timestamp, uint dataUsd) public {
        require(msg.sender == currencyUpdateAgent, "error_notPermitted");
        require(dataUsd > 0);
        dataPerUsd = dataUsd;
        emit ExchangeRatesUpdated(timestamp, dataUsd);
    }

    /**
    * Helper function to calculate (hypothetical) subscription cost for given seconds and price, using current exchange rates.
    * @param subscriptionSeconds length of hypothetical subscription, as a non-scaled integer
    * @param price nominal price scaled by 10^18 ("token wei" or "attodollars")
    * @param unit unit of the number price
    */    
    function getPriceInData(uint subscriptionSeconds, uint price, Currency unit) public view returns (uint datacoinAmount) {
        if (unit == Currency.DATA) {
            return price.mul(subscriptionSeconds);
        }
        return price.mul(dataPerUsd).div(10**18).mul(subscriptionSeconds);
    }

    /////////////// Admin functionality ///////////////
    
    event Halted();
    event Resumed();
    bool public halted = false;

    modifier whenNotHalted() {
        require(!halted || owner == msg.sender, "error_halted");
        _;
    }
    function halt() public onlyOwner {
        halted = true;
        emit Halted();
    }
    function resume() public onlyOwner {
        halted = false;
        emit Resumed();
    }

    function reInitialize(address datacoinAddress, address currencyUpdateAgentAddress) public onlyOwner {
        _initialize(datacoinAddress, currencyUpdateAgentAddress);
    }
}