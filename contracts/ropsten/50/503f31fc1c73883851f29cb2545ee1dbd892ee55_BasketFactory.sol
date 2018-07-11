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
    require(_to != address(0));               // &quot;Recipient addess is 0x0&quot;
    require(_value <= balances[msg.sender]);  // &quot;Insufficient token balance&quot;

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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
    require(_to != address(0));                       // &quot;Can not transfer to 0x0&quot;
    require(_value <= balances[_from]);               // &quot;Insufficient balance&quot;
    require(_value <= allowed[_from][msg.sender]);    // &quot;Insufficient allowance&quot;

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


/// @title Basket -- Basket contract for bundling and debundling tokens
/// @author CoinAlpha, Inc. <contact@coinalpha.com>
contract Basket is StandardToken {
  using SafeMath for uint;

  // Constants set at contract inception
  string                  public name;
  string                  public symbol;
  uint                    public decimals;
  address[]               public tokens;
  uint[]                  public weights;

  address                 public arranger;
  address                 public arrangerFeeRecipient;
  uint                    public arrangerFee;

  // mapping of token addresses to mapping of account balances
  // ADDRESS USER  || ADDRESS TOKEN || UINT BALANCE
  mapping(address => mapping(address => uint)) public outstandingBalance;

  // Modules
  IBasketRegistry         public basketRegistry;

  // Modifiers
  modifier onlyArranger {
    require(msg.sender == arranger);                // Check: &quot;Only the Arranger can call this function&quot;
    _;
  }

  // Events
  event LogDepositAndBundle(address indexed holder, uint indexed quantity);
  event LogDebundleAndWithdraw(address indexed holder, uint indexed quantity);
  event LogPartialDebundle(address indexed holder, uint indexed quantity);
  event LogWithdraw(address indexed holder, address indexed token, uint indexed quantity);
  event LogArrangerFeeRecipientChange(address indexed oldRecipient, address indexed newRecipient);
  event LogArrangerFeeChange(uint indexed oldFee, uint indexed newFee);

  /// @dev Basket constructor
  /// @param  _name                                Token name
  /// @param  _symbol                              Token symbol
  /// @param  _tokens                              Array of ERC20 token addresses
  /// @param  _weights                             Array of ERC20 token quantities
  /// @param  _basketRegistryAddress               Address of basket registry
  /// @param  _arranger                            Address of arranger
  /// @param  _arrangerFeeRecipient                Address to send arranger fees
  /// @param  _arrangerFee                         Amount of fee in ETH for every basket minted
  function Basket(
    string    _name,
    string    _symbol,
    address[] _tokens,
    uint[]    _weights,
    address   _basketRegistryAddress,
    address   _arranger,
    address   _arrangerFeeRecipient,
    uint      _arrangerFee                         // in wei, i.e. 1e18 = 1 ETH
  ) public {
    // Check: &quot;Constructor: invalid number of tokens and weights&quot;
    require(_tokens.length > 0 && _tokens.length == _weights.length);

    name = _name;
    symbol = _symbol;
    tokens = _tokens;
    weights = _weights;

    basketRegistry = IBasketRegistry(_basketRegistryAddress);

    arranger = _arranger;
    arrangerFeeRecipient = _arrangerFeeRecipient;
    arrangerFee = _arrangerFee;

    decimals = 18;
  }

  /// @dev Combined deposit of all component tokens (not yet deposited) and bundle
  /// @param  _quantity                            Quantity of basket tokens to mint
  /// @return success                              Operation successful
  function depositAndBundle(uint _quantity) public payable returns (bool success) {
    for (uint i = 0; i < tokens.length; i++) {
      address t = tokens[i];
      uint w = weights[i];
      assert(ERC20(t).transferFrom(msg.sender, this, w.mul(_quantity).div(10 ** decimals)));
    }

    // charging suppliers a fee for every new basket minted
    // skip fees if tokens are minted through swaps
    if (arrangerFee > 0) {
      // Check: &quot;Insufficient ETH for arranger fee to bundle&quot;
      require(msg.value >= arrangerFee.mul(_quantity).div(10 ** decimals));
      arrangerFeeRecipient.transfer(msg.value);
    } else {
      // prevent transfers of unnecessary ether into the contract
      require(msg.value == 0);
    }

    balances[msg.sender] = balances[msg.sender].add(_quantity);
    totalSupply_ = totalSupply_.add(_quantity);

    basketRegistry.incrementBasketsMinted(_quantity, msg.sender);
    emit LogDepositAndBundle(msg.sender, _quantity);
    return true;
  }

  /// @dev Convert basketTokens back to original tokens and transfer to requester
  /// @param  _quantity                            Quantity of basket tokens to convert back to original tokens
  /// @return success                              Operation successful
  function debundleAndWithdraw(uint _quantity) public returns (bool success) {
    assert(debundle(_quantity, msg.sender, msg.sender));
    emit LogDebundleAndWithdraw(msg.sender, _quantity);
    return true;
  }

  /// @dev Convert basketTokens back to original tokens and transfer to specified recipient
  /// @param  _quantity                            Quantity of basket tokens to swap
  /// @param  _sender                              Address of transaction sender
  /// @param  _recipient                           Address of token recipient
  /// @return success                              Operation successful
  function debundle(
    uint      _quantity,
    address   _sender,
    address   _recipient
  ) internal returns (bool success) {
    require(balances[_sender] >= _quantity);      // Check: &quot;Insufficient basket balance to debundle&quot;
    // decrease holder balance and total supply by _quantity
    balances[_sender] = balances[_sender].sub(_quantity);
    totalSupply_ = totalSupply_.sub(_quantity);

    // transfer tokens back to _recipient
    for (uint i = 0; i < tokens.length; i++) {
      address t = tokens[i];
      uint w = weights[i];
      ERC20(t).transfer(_recipient, w.mul(_quantity).div(10 ** decimals));
    }

    basketRegistry.incrementBasketsBurned(_quantity, _sender);
    return true;
  }

  /// @dev Allow holder to convert baskets to its underlying tokens and withdraw them individually
  /// @param  _quantity                            quantity of tokens to burn
  /// @return success                              Operation successful
  function burn(uint _quantity) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_quantity);
    totalSupply_ = totalSupply_.sub(_quantity);

    // increase outstanding balance of each of the tokens by their weights
    for (uint i = 0; i < tokens.length; i++) {
      address t = tokens[i];
      uint w = weights[i];
      outstandingBalance[msg.sender][t] = outstandingBalance[msg.sender][t].add(w.mul(_quantity).div(10 ** decimals));
    }

    basketRegistry.incrementBasketsBurned(_quantity, msg.sender);
    return true;
  }

  /// @dev Allow holder to withdraw outstanding balances from contract (such as previously paused tokens)
  /// @param  _token                               Address of token to withdraw
  /// @return success                              Operation successful
  function withdraw(address _token) public returns (bool success) {
    uint bal = outstandingBalance[msg.sender][_token];
    require(bal > 0);
    outstandingBalance[msg.sender][_token] = 0;
    assert(ERC20(_token).transfer(msg.sender, bal));

    emit LogWithdraw(msg.sender, _token, bal);
    return true;
  }

  /// @dev Change recipient of arranger fees
  /// @param  _newRecipient                        New fee recipient
  /// @return success                              Operation successful
  function changeArrangerFeeRecipient(address _newRecipient) public onlyArranger returns (bool success) {
    // Check: &quot;New receipient can not be 0x0 or the same as the current recipient&quot;
    require(_newRecipient != address(0) && _newRecipient != arrangerFeeRecipient);
    address oldRecipient = arrangerFeeRecipient;
    arrangerFeeRecipient = _newRecipient;

    emit LogArrangerFeeRecipientChange(oldRecipient, arrangerFeeRecipient);
    return true;
  }

  /// @dev Change amount of fee charged for every basket minted
  /// @param  _newFee                              New fee amount
  /// @return success                              Operation successful
  function changeArrangerFee(uint _newFee) public onlyArranger returns (bool success) {
    uint oldFee = arrangerFee;
    arrangerFee = _newFee;

    emit LogArrangerFeeChange(oldFee, arrangerFee);
    return true;
  }

  /// @dev Fallback to reject any ether sent to contract
  //  Check: &quot;Baskets do not accept ETH transfers&quot;
  function () public payable { revert(); }
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
    require(basketIndexFromAddress[msg.sender] > 0); // Check: &quot;Only a basket can call this function&quot;
    _;
  }
  modifier onlyBasketFactory {
    require(basketFactoryMap[msg.sender] == true);   // Check: &quot;Only a basket factory can call this function&quot;
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
    require(msg.sender == admin);                  // Check: &quot;Only an admin can call this function&quot;
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
  //  CHeck: &quot;BasketRegistry does not accept ETH transfers&quot;
  function () public payable { revert(); }
}


/**
  * @title BasketFactory -- Factory contract for creating different baskets
  * @author CoinAlpha, Inc. <contact@coinalpha.com>
  */
contract BasketFactory {
  using SafeMath for uint;

  address                       public admin;
  address                       public basketRegistryAddress;

  address                       public productionFeeRecipient;
  uint                          public productionFee;

  // Modules
  IBasketRegistry               public basketRegistry;

  // Modifiers
  modifier onlyAdmin {
    require(msg.sender == admin);                   // Check: &quot;Only the admin can call this function&quot;
    _;
  }

  // Events
  event LogBasketCreated(uint indexed basketIndex, address indexed basketAddress, address indexed arranger);
  event LogProductionFeeRecipientChange(address indexed oldRecipient, address indexed newRecipient);
  event LogProductionFeeChange(uint indexed oldFee, uint indexed newFee);

  /// @dev BasketFactory constructor
  /// @param  _basketRegistryAddress               Address of basket registry
  function BasketFactory(
    address   _basketRegistryAddress,
    address   _productionFeeRecipient,
    uint      _productionFee
  ) public {
    admin = msg.sender;

    basketRegistryAddress = _basketRegistryAddress;
    basketRegistry = IBasketRegistry(_basketRegistryAddress);

    productionFeeRecipient = _productionFeeRecipient;
    productionFee = _productionFee;
  }

  /// @dev Deploy a new basket
  /// @param  _name                                Name of new basket
  /// @param  _symbol                              Symbol of new basket
  /// @param  _tokens                              Token addresses of new basket
  /// @param  _weights                             Weight ratio addresses of new basket
  /// @param  _arrangerFeeRecipient                Address to send arranger fees
  /// @param  _arrangerFee                         Amount of arranger fee to charge per basket minted
  /// @return deployed basket
  function createBasket(
    string    _name,
    string    _symbol,
    address[] _tokens,
    uint[]    _weights,
    address   _arrangerFeeRecipient,
    uint      _arrangerFee
  )
    public
    payable
    returns (address newBasket)
  {
    // charging arrangers a fee to deploy new basket
    require(msg.value >= productionFee);           // Check: &quot;Insufficient ETH for basket creation fee&quot;
    productionFeeRecipient.transfer(msg.value);

    Basket b = new Basket(
      _name,
      _symbol,
      _tokens,
      _weights,
      basketRegistryAddress,
      msg.sender,                                  // arranger address
      _arrangerFeeRecipient,
      _arrangerFee
    );

    emit LogBasketCreated(
      basketRegistry.registerBasket(b, msg.sender, _name, _symbol, _tokens, _weights),
      b,
      msg.sender
    );
    return b;
  }

  /// @dev Change recipient of production fees
  /// @param  _newRecipient                        New fee recipient
  /// @return success                              Operation successful
  function changeProductionFeeRecipient(address _newRecipient) public onlyAdmin returns (bool success) {
    address oldRecipient = productionFeeRecipient;
    productionFeeRecipient = _newRecipient;

    emit LogProductionFeeRecipientChange(oldRecipient, productionFeeRecipient);
    return true;
  }

  /// @dev Change amount of fee charged for every basket created
  /// @param  _newFee                              New fee amount
  /// @return success                              Operation successful
  function changeProductionFee(uint _newFee) public onlyAdmin returns (bool success) {
    uint oldFee = productionFee;
    productionFee = _newFee;

    emit LogProductionFeeChange(oldFee, productionFee);
    return true;
  }

  /// @dev Fallback to reject any ether sent to contract
  //  Check: &quot;BasketFactory does not accept ETH transfers&quot;
  function () public payable { revert(); }
}