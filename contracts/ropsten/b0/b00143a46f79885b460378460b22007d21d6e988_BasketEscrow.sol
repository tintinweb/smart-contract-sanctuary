pragma solidity 0.4.21;

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


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract IBasketRegistry {
  // Called by BasketFactory
  function registerBasket(address, address, string, string, address[], uint[]) public returns (uint) {}
  function checkBasketExists (address) public returns (bool) {}
  function getBasketArranger (address) public returns (address) {}

  // Called by Basket
  function incrementBasketsMinted (uint, address) public returns (bool) {}
  function incrementBasketsBurned (uint, address) public returns (bool) {}
}

contract BasketRegistry {
  using SafeMath for uint;

  // Constants set at contract inception
  address                           public admin;
  mapping(address => bool)          public basketFactoryMap;

  uint                              public basketIndex;           // Baskets index starting from index = 1
  address[]                         public basketList;
  mapping(address => BasketStruct)  public basketMap;
  mapping(address => uint)          public basketIndexFromAddress;

  uint                              public arrangerIndex;         // Arrangers register starting from index = 1
  address[]                         public arrangerList;
  mapping(address => uint)          public arrangerBasketCount;
  mapping(address => uint)          public arrangerIndexFromAddress;

  // Structs
  struct BasketStruct {
    address   basketAddress;
    address   arranger;
    string    name;
    string    symbol;
    address[] tokens;
    uint[]    weights;
    uint      totalMinted;
    uint      totalBurned;
  }

  // Modifiers
  modifier onlyBasket {
    require(basketIndexFromAddress[msg.sender] > 0); // Check: "Only a basket can call this function"
    _;
  }
  modifier onlyBasketFactory {
    require(basketFactoryMap[msg.sender] == true);   // Check: "Only a basket factory can call this function"
    _;
  }

  // Events
  event LogWhitelistBasketFactory(address basketFactory);
  event LogBasketRegistration(address basketAddress, uint basketIndex);
  event LogIncrementBasketsMinted(address basketAddress, uint quantity, address sender);
  event LogIncrementBasketsBurned(address basketAddress, uint quantity, address sender);

  /// @dev BasketRegistry constructor
  function BasketRegistry() public {
    basketIndex = 1;
    arrangerIndex = 1;
    admin = msg.sender;
  }

  /// @dev Set basket factory address after deployment
  /// @param  _basketFactory                       Basket factory address
  /// @return success                              Operation successful
  function whitelistBasketFactory(address _basketFactory) public returns (bool success) {
    require(msg.sender == admin);                  // Check: "Only an admin can call this function"
    basketFactoryMap[_basketFactory] = true;
    emit LogWhitelistBasketFactory(_basketFactory);
    return true;
  }

  /// @dev Add new basket to registry after being created in the basketFactory
  /// @param  _basketAddress                       Address of deployed basket
  /// @param  _arranger                            Address of basket admin
  /// @param  _name                                Basket name
  /// @param  _symbol                              Basket symbol
  /// @param  _tokens                              Token address array
  /// @param  _weights                             Weight ratio array
  /// @return basketIndex                          Index of basket in registry
  function registerBasket(
    address   _basketAddress,
    address   _arranger,
    string    _name,
    string    _symbol,
    address[] _tokens,
    uint[]    _weights
  )
    public
    onlyBasketFactory
    returns (uint index)
  {
    basketMap[_basketAddress] = BasketStruct(
      _basketAddress, _arranger, _name, _symbol, _tokens, _weights, 0, 0
    );
    basketList.push(_basketAddress);
    basketIndexFromAddress[_basketAddress] = basketIndex;

    if (arrangerBasketCount[_arranger] == 0) {
      arrangerList.push(_arranger);
      arrangerIndexFromAddress[_arranger] = arrangerIndex;
      arrangerIndex = arrangerIndex.add(1);
    }
    arrangerBasketCount[_arranger] = arrangerBasketCount[_arranger].add(1);

    emit LogBasketRegistration(_basketAddress, basketIndex);
    basketIndex = basketIndex.add(1);
    return basketIndex.sub(1);
  }

  /// @dev Check if basket exists in registry
  /// @param  _basketAddress                       Address of basket to check
  /// @return basketExists
  function checkBasketExists(address _basketAddress) public view returns (bool basketExists) {
    return basketIndexFromAddress[_basketAddress] > 0;
  }

  /// @dev Retrieve basket info from the registry
  /// @param  _basketAddress                       Address of basket to check
  /// @return basketDetails
  function getBasketDetails(address _basketAddress)
    public
    view
    returns (
      address   basketAddress,
      address   arranger,
      string    name,
      string    symbol,
      address[] tokens,
      uint[]    weights,
      uint      totalMinted,
      uint      totalBurned
    )
  {
    BasketStruct memory b = basketMap[_basketAddress];
    return (b.basketAddress, b.arranger, b.name, b.symbol, b.tokens, b.weights, b.totalMinted, b.totalBurned);
  }

  /// @dev Look up a basket&#39;s arranger
  /// @param  _basketAddress                       Address of basket to check
  /// @return arranger
  function getBasketArranger(address _basketAddress) public view returns (address) {
    return basketMap[_basketAddress].arranger;
  }

  /// @dev Increment totalMinted from BasketStruct
  /// @param  _quantity                            Quantity to increment
  /// @param  _sender                              Address that bundled tokens
  /// @return success                              Operation successful
  function incrementBasketsMinted(uint _quantity, address _sender) public onlyBasket returns (bool) {
    basketMap[msg.sender].totalMinted = basketMap[msg.sender].totalMinted.add(_quantity);
    emit LogIncrementBasketsMinted(msg.sender, _quantity, _sender);
    return true;
  }

  /// @dev Increment totalBurned from BasketStruct
  /// @param  _quantity                            Quantity to increment
  /// @param  _sender                              Address that debundled tokens
  /// @return success                              Operation successful
  function incrementBasketsBurned(uint _quantity, address _sender) public onlyBasket returns (bool) {
    basketMap[msg.sender].totalBurned = basketMap[msg.sender].totalBurned.add(_quantity);
    emit LogIncrementBasketsBurned(msg.sender, _quantity, _sender);
    return true;
  }

  /// @dev Fallback to reject any ether sent to contract
  //  CHeck: "BasketRegistry does not accept ETH transfers"
  function () public payable { revert(); }
}

/// @title BasketEscrow -- Escrow contract to facilitate trading
/// @author CoinAlpha, Inc. <contact@coinalpha.com>
contract BasketEscrow {
  using SafeMath for uint;

  // Constants set at contract inception
  address                 public admin;
  address                 public transactionFeeRecipient;
  uint                    public transactionFee;
  uint                    public FEE_DECIMALS;

  uint                    public orderIndex;
  address                 public basketRegistryAddress;
  address                 public ETH_ADDRESS;

  // mapping of token addresses to mapping of account balances (token=0 means Ether)
  // ADDRESS USER  || ADDRESS TOKEN || UINT BALANCE
  mapping(address => mapping(address => uint)) public balances;

  // mapping of user accounts to mapping of order hashes to orderIndex (equivalent to offchain signature)
  // ADDRESS USER  || ORDER HASH    || uint
  mapping(address => mapping(bytes32 => uint)) public orders;

  // mapping of user accounts to mapping of order hashes to booleans (true = order has been filled)
  // ADDRESS USER  || ORDER HASH    || BOOL
  mapping(address => mapping(bytes32 => bool)) public filledOrders;

  mapping(uint => Order) public orderMap;                // Used to lookup existing orders


  // Modules
  IBasketRegistry         public basketRegistry;

  // Structs
  struct Order {
    address   orderCreator;
    address   tokenGet;
    uint      amountGet;
    address   tokenGive;
    uint      amountGive;
    uint      expiration;
    uint      nonce;
  }

  // Modifiers
  modifier onlyAdmin {
    require(msg.sender == admin);                       // Check: "Only the admin can call this function"
    _;
  }

  // Events
  event LogBuyOrderCreated(uint newOrderIndex, address indexed buyer, address basket, uint amountEth, uint amountBasket, uint expiration, uint nonce);
  event LogSellOrderCreated(uint newOrderIndex, address indexed seller, address basket, uint amountEth, uint amountBasket, uint expiration, uint nonce);
  event LogBuyOrderCancelled(uint cancelledOrderIndex, address indexed buyer, address basket, uint amountEth, uint amountBasket);
  event LogSellOrderCancelled(uint cancelledOrderIndex, address indexed seller, address basket, uint amountEth, uint amountBasket);
  event LogBuyOrderFilled(uint filledOrderIndex, address indexed buyOrderFiller, address indexed orderCreator, address basket, uint amountEth, uint amountBasket);
  event LogSellOrderFilled(uint filledOrderIndex, address indexed sellOrderFiller, address indexed orderCreator, address basket, uint amountEth, uint amountBasket);
  event LogTransactionFeeRecipientChange(address oldRecipient, address newRecipient);
  event LogTransactionFeeChange(uint oldFee, uint newFee);

  /// @dev BasketEscrow constructor
  /// @param  _basketRegistryAddress                     Address of basket registry
  /// @param  _transactionFeeRecipient                   Address to send transactionFee
  /// @param  _transactionFee                            Transaction fee in ETH percentage
  function BasketEscrow(
    address   _basketRegistryAddress,
    address   _transactionFeeRecipient,
    uint      _transactionFee
  ) public {
    basketRegistryAddress = _basketRegistryAddress;
    basketRegistry = IBasketRegistry(_basketRegistryAddress);
    ETH_ADDRESS = 0;                                     // Use address 0 to indicate Eth
    orderIndex = 1;                                      // Initialize order index at 1

    admin = msg.sender;                                  // record admin
    transactionFeeRecipient = _transactionFeeRecipient;
    transactionFee = _transactionFee;
    FEE_DECIMALS = 18;
  }

  /// @dev Create an order to buy baskets with ETH
  /// @param  _basketAddress                             Address of basket to purchase
  /// @param  _amountBasket                              Amount of baskets to purchase
  /// @param  _expiration                                Unix timestamp
  /// @param  _nonce                                     Random number to generate unique order hash
  /// @return success                                    Operation successful
  function createBuyOrder(
    address   _basketAddress,
    uint      _amountBasket,
    uint      _expiration,
    uint      _nonce
  ) public payable returns (bool success) {
    uint index = _createOrder(msg.sender, _basketAddress, _amountBasket, ETH_ADDRESS, msg.value, _expiration, _nonce);

    emit LogBuyOrderCreated(index, msg.sender, _basketAddress, msg.value, _amountBasket, _expiration, _nonce);
    return true;
  }

  /// @dev Create an order to sell baskets for ETH       NOTE: REQUIRES TOKEN APPROVAL
  /// @param  _basketAddress                             Address of basket to sell
  /// @param  _amountBasket                              Amount of baskets to sell
  /// @param  _amountEth                                 Amount of ETH to receive in exchange
  /// @param  _expiration                                Unix timestamp
  /// @param  _nonce                                     Random number to generate unique order hash
  /// @return success                                    Operation successful
  function createSellOrder(
    address   _basketAddress,
    uint      _amountBasket,
    uint      _amountEth,
    uint      _expiration,
    uint      _nonce
  )
    public
    returns (bool success)
  {
    assert(ERC20(_basketAddress).transferFrom(msg.sender, this, _amountBasket));
    uint index = _createOrder(msg.sender, ETH_ADDRESS, _amountEth, _basketAddress, _amountBasket, _expiration, _nonce);

    emit LogSellOrderCreated(index, msg.sender, _basketAddress, _amountEth, _amountBasket, _expiration, _nonce);
    return true;
  }

  /// @dev Contract internal function to record submitted orders
  /// @param  _orderCreator                              Address of the order&#39;s creator
  /// @param  _tokenGet                                  Address of token/ETH to receive
  /// @param  _amountGet                                 Amount of token/ETH to receive
  /// @param  _tokenGive                                 Address of token/ETH to give
  /// @param  _amountGive                                Amount of token/ETH to give
  /// @param  _expiration                                Unix timestamp
  /// @param  _nonce                                     Random number to generate unique order hash
  /// @return newOrderIndex
  function _createOrder(
    address   _orderCreator,
    address   _tokenGet,
    uint      _amountGet,
    address   _tokenGive,
    uint      _amountGive,
    uint      _expiration,
    uint      _nonce
  )
    internal
    returns (uint newOrderIndex)
  {
    require(_expiration > now);
    require(_tokenGet == ETH_ADDRESS || basketRegistry.checkBasketExists(_tokenGet));   // Check: "Order not for ETH or invalid basket"
    require(_tokenGive == ETH_ADDRESS || basketRegistry.checkBasketExists(_tokenGive)); // Check: "Order not for ETH or invalid basket"

    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expiration, _nonce);
    require(orders[_orderCreator][hash] == 0);                                          // Check: "Duplicate order"

    orders[_orderCreator][hash] = orderIndex;
    balances[_orderCreator][_tokenGive] = balances[_orderCreator][_tokenGive].add(_amountGive);
    orderMap[orderIndex] = Order(_orderCreator, _tokenGet, _amountGet, _tokenGive, _amountGive, _expiration, _nonce);
    orderIndex = orderIndex.add(1);

    return orderIndex.sub(1);
  }

  /// @dev Cancel an existing buy order
  /// @param  _basketAddress                             Address of basket to purchase in original order
  /// @param  _amountBasket                              Amount of baskets to purchase in original order
  /// @param  _amountEth                                 Amount of ETH sent in original order
  /// @param  _expiration                                Unix timestamp in original order
  /// @param  _nonce                                     Random number in original order
  /// @return success                                    Operation successful
  function cancelBuyOrder(
    address   _basketAddress,
    uint      _amountBasket,
    uint      _amountEth,
    uint      _expiration,
    uint      _nonce
  ) public returns (bool success) {
    uint cancelledOrderIndex = _cancelOrder(msg.sender, _basketAddress, _amountBasket, ETH_ADDRESS, _amountEth, _expiration, _nonce);

    if (now >= _expiration) {
      msg.sender.transfer(_amountEth);                   // if order has expired, no transaction fee is charged
    } else {
      uint fee = _amountEth.mul(transactionFee).div(10 ** FEE_DECIMALS);
      msg.sender.transfer(_amountEth.sub(fee));
      transactionFeeRecipient.transfer(fee);
    }

    emit LogBuyOrderCancelled(cancelledOrderIndex, msg.sender, _basketAddress, _amountEth, _amountBasket);
    return true;
  }

  /// @dev Cancel an existing sell order
  /// @param  _basketAddress                             Address of basket to sell in original order
  /// @param  _amountBasket                              Amount of baskets to sell in original order
  /// @param  _amountEth                                 Amount of ETH to receive in original order
  /// @param  _expiration                                Unix timestamp in original order
  /// @param  _nonce                                     Random number in original order
  /// @return success                                    Operation successful
  function cancelSellOrder(
    address   _basketAddress,
    uint      _amountBasket,
    uint      _amountEth,
    uint      _expiration,
    uint      _nonce
  ) public returns (bool success) {
    uint cancelledOrderIndex = _cancelOrder(msg.sender, ETH_ADDRESS, _amountEth, _basketAddress, _amountBasket, _expiration, _nonce);

    assert(ERC20(_basketAddress).transfer(msg.sender, _amountBasket));

    emit LogSellOrderCancelled(cancelledOrderIndex, msg.sender, _basketAddress, _amountEth, _amountBasket);
    return true;
  }

  /// @dev Contract internal function to cancel an existing order
  /// @param  _orderCreator                              Address of the original order&#39;s creator
  /// @param  _tokenGet                                  Address of token/ETH to receive in original order
  /// @param  _amountGet                                 Amount of token/ETH to receive in original order
  /// @param  _tokenGive                                 Address of token/ETH to give in original order
  /// @param  _amountGive                                Amount of token/ETH to give in original order
  /// @param  _expiration                                Unix timestamp in original order
  /// @param  _nonce                                     Random number in original order
  /// @return cancelledOrderIndex                        Index of cancelled order
  function _cancelOrder(
    address   _orderCreator,
    address   _tokenGet,
    uint      _amountGet,
    address   _tokenGive,
    uint      _amountGive,
    uint      _expiration,
    uint      _nonce
  )
    internal
    returns (uint index)
  {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expiration, _nonce);
    uint cancelledOrderIndex = orders[_orderCreator][hash];
    require(cancelledOrderIndex > 0);                    // Check: "Order does not exist"
    require(filledOrders[_orderCreator][hash] != true);  // Check: "Order has been filled"

    orders[_orderCreator][hash] = 0;
    balances[_orderCreator][_tokenGive] = balances[_orderCreator][_tokenGive].sub(_amountGive);

    return cancelledOrderIndex;
  }

  /// @dev Fill an existing buy order                    NOTE: REQUIRES TOKEN APPROVAL
  /// @param  _orderCreator                              Address of order&#39;s creator
  /// @param  _basketAddress                             Address of basket to purchase in original order
  /// @param  _amountBasket                              Amount of baskets to purchase in original order
  /// @param  _amountEth                                 Amount of ETH to sent in original order
  /// @param  _expiration                                Unix timestamp in original order
  /// @param  _nonce                                     Random number in original order
  /// @return success                                    Operation successful
  function fillBuyOrder(
    address   _orderCreator,
    address   _basketAddress,
    uint      _amountBasket,
    uint      _amountEth,
    uint      _expiration,
    uint      _nonce
  ) public returns (bool success) {
    uint filledOrderIndex = _fillOrder(_orderCreator, _basketAddress, _amountBasket, ETH_ADDRESS, _amountEth, _expiration, _nonce);
    assert(ERC20(_basketAddress).transferFrom(msg.sender, _orderCreator, _amountBasket));

    uint fee = _amountEth.mul(transactionFee).div(10 ** FEE_DECIMALS);
    msg.sender.transfer(_amountEth.sub(fee));
    transactionFeeRecipient.transfer(fee);

    emit LogBuyOrderFilled(filledOrderIndex, msg.sender, _orderCreator, _basketAddress, _amountEth, _amountBasket);
    return true;
  }

  /// @dev Fill an existing sell order
  /// @param  _orderCreator                              Address of order&#39;s creator
  /// @param  _basketAddress                             Address of basket to sell in original order
  /// @param  _amountBasket                              Amount of baskets to sell in original order
  /// @param  _expiration                                Unix timestamp in original order
  /// @param  _nonce                                     Random number in original order
  /// @return success                                    Operation successful
  function fillSellOrder(
    address   _orderCreator,
    address   _basketAddress,
    uint      _amountBasket,
    uint      _expiration,
    uint      _nonce
  ) public payable returns (bool success) {
    uint filledOrderIndex = _fillOrder(_orderCreator, ETH_ADDRESS, msg.value, _basketAddress, _amountBasket, _expiration, _nonce);
    assert(ERC20(_basketAddress).transfer(msg.sender, _amountBasket));

    uint fee = msg.value.mul(transactionFee).div(10 ** FEE_DECIMALS);
    _orderCreator.transfer(msg.value.sub(fee));
    transactionFeeRecipient.transfer(fee);

    emit LogSellOrderFilled(filledOrderIndex, msg.sender, _orderCreator, _basketAddress, msg.value, _amountBasket);
    return true;
  }

  /// @dev Contract internal function to fill an existing order
  /// @param  _orderCreator                              Address of the original order&#39;s creator
  /// @param  _tokenGet                                  Address of token/ETH to receive in original order
  /// @param  _amountGet                                 Amount of token/ETH to receive in original order
  /// @param  _tokenGive                                 Address of token/ETH to give in original order
  /// @param  _amountGive                                Amount of token/ETH to give in original order
  /// @param  _expiration                                Unix timestamp in original order
  /// @param  _nonce                                     Random number in original order
  /// @return filledOrderIndex                           Index of filled order
  function _fillOrder(
    address   _orderCreator,
    address   _tokenGet,
    uint      _amountGet,
    address   _tokenGive,
    uint      _amountGive,
    uint      _expiration,
    uint      _nonce
  )
    internal
    returns (uint index)
  {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expiration, _nonce);
    uint filledOrderIndex = orders[_orderCreator][hash];
    require(filledOrderIndex > 0);                      // Check: "Order does not exist"
    require(filledOrders[_orderCreator][hash] != true); // Check: "Order has been filled"
    require(now <= _expiration);                        // Check: "Order has expired"

    filledOrders[_orderCreator][hash] = true;
    balances[_orderCreator][_tokenGive] = balances[_orderCreator][_tokenGive].sub(_amountGive);

    return filledOrderIndex;
  }

  /// @dev Get details of an order with its index;
  /// @param  _orderIndex                                  Order index assigned at order creation
  /// @return Order struct
  function getOrderDetails(uint _orderIndex) public view returns (
    address   orderCreator,
    address   tokenGet,
    uint      amountGet,
    address   tokenGive,
    uint      amountGive,
    uint      expiration,
    uint      nonce,
    bool      _orderExists,
    bool      _isFilled
  ) {
    Order memory o = orderMap[_orderIndex];
    bytes32 hash = sha256(this, o.tokenGet, o.amountGet, o.tokenGive, o.amountGive, o.expiration, o.nonce);
    bool orderExists = orders[o.orderCreator][hash] > 0;
    bool isFilled = filledOrders[o.orderCreator][hash];

    return (o.orderCreator, o.tokenGet, o.amountGet, o.tokenGive, o.amountGive, o.expiration, o.nonce, orderExists, isFilled);
  }

  /// @dev Change recipient of transaction fees
  /// @param  _newRecipient                        New fee recipient
  /// @return success                              Operation successful
  function changeTransactionFeeRecipient(address _newRecipient) public onlyAdmin returns (bool success) {
    address oldRecipient = transactionFeeRecipient;
    transactionFeeRecipient = _newRecipient;

    emit LogTransactionFeeRecipientChange(oldRecipient, transactionFeeRecipient);
    return true;
  }

  /// @dev Change percentage of fee charged for ETH transactions
  /// @param  _newFee                              New fee amount
  /// @return success                              Operation successful
  function changeTransactionFee(uint _newFee) public onlyAdmin returns (bool success) {
    uint oldFee = transactionFee;
    transactionFee = _newFee;

    emit LogTransactionFeeChange(oldFee, transactionFee);
    return true;
  }

  /// @dev Fallback to reject any ether sent directly to contract
  //  Check: "BasketEscrow does not accept ETH transfers"
  function () public payable { revert(); }
}