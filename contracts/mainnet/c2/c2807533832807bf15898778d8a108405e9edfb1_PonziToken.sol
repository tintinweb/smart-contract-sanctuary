pragma solidity ^0.4.18;

/*
 * Ponzi Trust Token Smart Contracts 
 * Code is published on https://github.com/PonziTrust/Token
 * Ponzi Trust https://ponzitrust.com/
*/


// see: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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


// see: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20 {
  function name() public view returns (string);
  function symbol() public view returns (string);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// see: https://github.com/ethereum/EIPs/issues/677
contract ERC677Token {
  function transferAndCall(address receiver, uint amount, bytes data) public returns (bool success);
  function contractFallback(address to, uint value, bytes data) internal;
  function isContract(address addr) internal view returns (bool hasCode);
  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


// see: https://github.com/ethereum/EIPs/issues/677
contract ERC677Recipient {
  function tokenFallback(address from, uint256 amount, bytes data) public returns (bool success);
}  


/**
* @dev The token implement ERC20 and ERC677 standarts(see above).
* use Withdrawal, Restricting Access, State Machine patterns.
* see: http://solidity.readthedocs.io/en/develop/common-patterns.html
* use SafeMath library, see above.
* The owner can intervene in the work of the token only before the expiration
* DURATION_TO_ACCESS_FOR_OWNER = 144 days. Contract has thee state of working:
* 1.PreSale - only owner can access to transfer tokens. 2.Sale - contract to sale
* tokens by func byToken() of fallback, contact and owner can access to transfer tokens. 
* Token price setting by owner or price setter. 3.PublicUse - anyone can transfer tokens.
*/
contract PonziToken is ERC20, ERC677Token {
  using SafeMath for uint256;

  enum State {
    PreSale,   //PRE_SALE_STR
    Sale,      //SALE_STR
    PublicUse  //PUBLIC_USE_STR
  }
  // we need returns string representation of state
  // because enums are not supported by the ABI, they are just supported by Solidity.
  // see: http://solidity.readthedocs.io/en/develop/frequently-asked-questions.html#if-i-return-an-enum-i-only-get-integer-values-in-web3-js-how-to-get-the-named-values
  string private constant PRE_SALE_STR = "PreSale";
  string private constant SALE_STR = "Sale";
  string private constant PUBLIC_USE_STR = "PublicUse";
  State private m_state;

  uint256 private constant DURATION_TO_ACCESS_FOR_OWNER = 144 days;
  
  uint256 private m_maxTokensPerAddress;
  uint256 private m_firstEntranceToSaleStateUNIX;
  address private m_owner;
  address private m_priceSetter;
  address private m_bank;
  uint256 private m_tokenPriceInWei;
  uint256 private m_totalSupply;
  uint256 private m_myDebtInWei;
  string private m_name;
  string private m_symbol;
  uint8 private m_decimals;
  bool private m_isFixedTokenPrice;
  
  mapping(address => mapping (address => uint256)) private m_allowed;
  mapping(address => uint256) private m_balances;
  mapping(address => uint256) private m_pendingWithdrawals;

////////////////
// EVENTS
//
  event StateChanged(address indexed who, State newState);
  event PriceChanged(address indexed who, uint newPrice, bool isFixed);
  event TokensSold(uint256 numberOfTokens, address indexed purchasedBy, uint256 indexed priceInWei);
  event Withdrawal(address indexed to, uint sumInWei);

////////////////
// MODIFIERS - Restricting Access and State Machine patterns
//
  modifier atState(State state) {
    require(m_state == state);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == m_owner);
    _;
  }

  modifier onlyOwnerOrAtState(State state) {
    require(msg.sender == m_owner || m_state == state); 
    _;
  }
  
  modifier checkAccess() {
    require(m_firstEntranceToSaleStateUNIX == 0 // solium-disable-line indentation, operator-whitespace
      || now.sub(m_firstEntranceToSaleStateUNIX) <= DURATION_TO_ACCESS_FOR_OWNER 
      || m_state != State.PublicUse
    ); 
    _;
    // owner has not access if duration To Access For Owner was passed 
    // and (&&) contract in PublicUse state.
  }
  
  modifier validRecipient(address recipient) {
    require(recipient != address(0) && recipient != address(this));
    _;
  }

///////////////
// CONSTRUCTOR
//  
  /**
  * @dev Constructor PonziToken.
  */
  function PonziToken() public {
    m_owner = msg.sender;
    m_bank = msg.sender;
    m_state = State.PreSale;
    m_decimals = 8;
    m_name = "Ponzi";
    m_symbol = "PT";
  }

  /**
  * do not forget about:
  * https://medium.com/codetractio/a-look-into-paritys-multisig-wallet-bug-affecting-100-million-in-ether-and-tokens-356f5ba6e90a
  * 
  * @dev Initialize the contract, only owner can call and only once.
  * @return Whether successful or not.
  */
  function initContract() 
    public 
    onlyOwner() 
    returns (bool)
  {
    require(m_maxTokensPerAddress == 0 && m_decimals > 0);
    m_maxTokensPerAddress = uint256(1000).mul(uint256(10)**uint256(m_decimals));

    m_totalSupply = uint256(100000000).mul(uint256(10)**uint256(m_decimals));
    // 70% for owner
    m_balances[msg.sender] = m_totalSupply.mul(uint256(70)).div(uint256(100));
    // 30% for sale
    m_balances[address(this)] = m_totalSupply.sub(m_balances[msg.sender]);

    // allow owner to transfer token from this  
    m_allowed[address(this)][m_owner] = m_balances[address(this)];
    return true;
  }

///////////////////
// ERC20 Methods
// get from https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token/ERC20
//
  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return m_balances[owner];
  }
  
  /**
  * @dev The name of the token.
  * @return The name of the token.
  */
  function name() public view returns (string) {
    return m_name;
  }

  /**
  * @dev The symbol of the token.
  * @return The symbol of the token.
  */
  function symbol() public view returns (string) {
    return m_symbol;
  }

  /**
  * @dev The number of decimals the token.
  * @return The number of decimals the token.
  * @notice Uses - e.g. 8, means to divide the token.
  * amount by 100000000 to get its user representation.
  */
  function decimals() public view returns (uint8) {
    return m_decimals;
  }

  /**
  * @dev Total number of tokens in existence.
  * @return Total number of tokens in existence.
  */
  function totalSupply() public view returns (uint256) {
    return m_totalSupply;
  }

  /**
  * @dev Transfer token for a specified address.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @return Whether successful or not.
  */
  function transfer(address to, uint256 value) 
    public 
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(to)
    returns (bool) 
  {
    // require(value <= m_balances[msg.sender]);
    // SafeMath.sub will already throw if this condition is not met
    m_balances[msg.sender] = m_balances[msg.sender].sub(value);
    m_balances[to] = m_balances[to].add(value);
    Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param from Address The address which you want to send tokens from.
   * @param to Address The address which you want to transfer to.
   * @param value Uint256 the amount of tokens to be transferred.
   * @return Whether successful or not.
   */
  function transferFrom(address from, address to, uint256 value) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(to)
    returns (bool) 
  {
    // require(value <= m_balances[from]);
    // require(value <= m_allowed[from][msg.sender]);
    // SafeMath.sub will already throw if this condition is not met
    m_balances[from] = m_balances[from].sub(value);
    m_balances[to] = m_balances[to].add(value);
    m_allowed[from][msg.sender] = m_allowed[from][msg.sender].sub(value);
    Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   * @return Whether successful or not.
   */
  function approve(address spender, uint256 value) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(spender)
    returns (bool) 
  {
    // To change the approve amount you first have to reduce the addresses`
    // allowance to zero by calling `approve(spender,0)` if it is not
    // already 0 to mitigate the race condition described here:
    // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((value == 0) || (m_allowed[msg.sender][spender] == 0));

    m_allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner Address The address which owns the funds.
   * @param spender Address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) 
    public 
    view
    returns (uint256) 
  {
    return m_allowed[owner][spender];
  }
  
  /**
   * approve should be called when allowed[spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol.
   *
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   * @return Whether successful or not.
   */
  function increaseApproval(address spender, uint addedValue) 
    public 
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(spender)
    returns (bool) 
  {
    m_allowed[msg.sender][spender] = m_allowed[msg.sender][spender].add(addedValue);
    Approval(msg.sender, spender, m_allowed[msg.sender][spender]);
    return true;
  }

   /**
   * Approve should be called when allowed[spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol.
   *
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   * @return Whether successful or not.
   */
  function decreaseApproval(address spender, uint subtractedValue) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(spender)
    returns (bool) 
  {
    uint oldValue = m_allowed[msg.sender][spender];
    if (subtractedValue > oldValue) {
      m_allowed[msg.sender][spender] = 0;
    } else {
      m_allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    Approval(msg.sender, spender, m_allowed[msg.sender][spender]);
    return true;
  }

///////////////////
// ERC677 Methods
//
  /**
  * @dev Transfer token to a contract address with additional data if the recipient is a contact.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @param extraData The extra data to be passed to the receiving contract.
  * @return Whether successful or not.
  */
  function transferAndCall(address to, uint256 value, bytes extraData) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(to)
    returns (bool)
  {
    // require(value <= m_balances[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    m_balances[msg.sender] = m_balances[msg.sender].sub(value);
    m_balances[to] = m_balances[to].add(value);
    Transfer(msg.sender, to, value);
    if (isContract(to)) {
      contractFallback(to, value, extraData);
      Transfer(msg.sender, to, value, extraData);
    }
    return true;
  }

  /**
  * @dev transfer token all tokens to a contract address with additional data if the recipient is a contact.
  * @param to The address to transfer all to.
  * @param extraData The extra data to be passed to the receiving contract.
  * @return Whether successful or not.
  */
  function transferAllAndCall(address to, bytes extraData) 
    external
    onlyOwnerOrAtState(State.PublicUse)
    returns (bool) 
  {
    return transferAndCall(to, m_balances[msg.sender], extraData);
  }
  
  /**
  * @dev Call ERC677 tokenFallback for ERC677Recipient contract.
  * @param to The address of ERC677Recipient.
  * @param value Amount of tokens with was sended
  * @param data Sended to ERC677Recipient.
  * @return Whether contract or not.
  */
  function contractFallback(address to, uint value, bytes data)
    internal
  {
    ERC677Recipient recipient = ERC677Recipient(to);
    recipient.tokenFallback(msg.sender, value, data);
  }

  /**
  * @dev Check addr if is contract.
  * @param addr The address that checking.
  * @return Whether contract or not.
  */
  function isContract(address addr) internal view returns (bool) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length > 0;
  }
  
  
///////////////////
// payable Methods
// use withdrawal pattern 
// see: http://solidity.readthedocs.io/en/develop/common-patterns.html#withdrawal-from-contracts
// see: https://consensys.github.io/smart-contract-best-practices/known_attacks/
//
  /**
  * Recived ETH converted to tokens amount for price. sender has max limit for tokens 
  * amount as m_maxTokensPerAddress - balanceOf(sender). if amount <= max limit
  * then transfer amount from this to sender and 95%ETH to bank, 5%ETH to owner.
  * else amount > max limit then we calc cost of max limit of tokens,
  * store this cost in m_pendingWithdrawals[sender] and m_myDebtInWei and 
  * transfer max limit of tokens from this to sender and 95% max limit cost to bank
  * 5% max limit cost to owner.
  *
  * @dev Contract receive ETH (payable) from sender and transfer some amount of tokens to him.
  */
  function byTokens() public payable atState(State.Sale) {
    // check if msg.sender can to by tokens 
    require(m_balances[msg.sender] < m_maxTokensPerAddress);

    // get actual token price and set it
    m_tokenPriceInWei = calcTokenPriceInWei();
    
    // check if msg.value has enough for by 1 token
    require(msg.value >= m_tokenPriceInWei);
    
    // calc max available tokens for sender
    uint256 maxAvailableTokens = m_maxTokensPerAddress.sub(m_balances[msg.sender]);
    
    // convert msg.value(wei) to tokens
    uint256 tokensAmount = weiToTokens(msg.value, m_tokenPriceInWei);
    
    if (tokensAmount > maxAvailableTokens) {
      // we CANT transfer all tokens amount, ONLY max available tokens 
      // calc cost in wei of max available tokens
      // subtract cost from msg.value and store it as debt for sender
      tokensAmount = maxAvailableTokens;  
      // calc cost
      uint256 tokensAmountCostInWei = tokensToWei(tokensAmount, m_tokenPriceInWei);
      // calc debt
      uint256 debt = msg.value.sub(tokensAmountCostInWei);
      // Withdrawal pattern avoid Re-Entrancy (dont use transfer to unknow address)
      // update pending withdrawals
      m_pendingWithdrawals[msg.sender] = m_pendingWithdrawals[msg.sender].add(debt);
      // update my debt
      m_myDebtInWei = m_myDebtInWei.add(debt);
    }
    // transfer tokensAmount tokens form this to sender
    // SafeMath.sub will already throw if this condition is not met
    m_balances[address(this)] = m_balances[address(this)].sub(tokensAmount);
    m_balances[msg.sender] = m_balances[msg.sender].add(tokensAmount);

    // we can transfer eth to owner and bank, because we know that they 
    // dont use Re-Entrancy and other attacks.
    // transfer 5% of eht-myDebt to owner
    // owner cant be equal address(0) because this function to be accessible
    // only in State.Sale but owner can be equal address(0), only in State.PublicUse
    // State.Sale not equal State.PublicUse!
    m_owner.transfer(this.balance.sub(m_myDebtInWei).mul(uint256(5)).div(uint256(100)));
    // transfer 95% of eht-myDebt to bank
    // bank cant be equal address(0) see setBank() and PonziToken()
    m_bank.transfer(this.balance.sub(m_myDebtInWei));
    checkValidityOfBalance(); // this.balance >= m_myDebtInWei
    Transfer(address(this), msg.sender, tokensAmount);
    TokensSold(tokensAmount, msg.sender, m_tokenPriceInWei); 
  }
  
  /**
  * @dev Sender receive his pending withdrawals(if > 0).
  */
  function withdraw() external {
    uint amount = m_pendingWithdrawals[msg.sender];
    require(amount > 0);
    // set zero the pending refund before
    // sending to prevent Re-Entrancy 
    m_pendingWithdrawals[msg.sender] = 0;
    m_myDebtInWei = m_myDebtInWei.sub(amount);
    msg.sender.transfer(amount);
    checkValidityOfBalance(); // this.balance >= m_myDebtInWei
    Withdrawal(msg.sender, amount);
  }

  /**
  * @notice http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function
  * we dont need recieve ETH always, only in State.Sale from externally accounts.
  *
  * @dev Fallback func, call byTokens().
  */
  function() public payable atState(State.Sale) {
    byTokens();
  }
    
  
////////////////////////
// external view methods
// everyone outside has access 
//
  /**
  * @dev Gets the pending withdrawals of the specified address.
  * @param owner The address to query the pending withdrawals of.
  * @return An uint256 representing the amount withdrawals owned by the passed address.
  */
  function pendingWithdrawals(address owner) external view returns (uint256) {
    return m_pendingWithdrawals[owner];
  }
  
  /**
  * @dev Get contract work state.
  * @return Contract work state via string.
  */
  function state() external view returns (string stateString) {
    if (m_state == State.PreSale) {
      stateString = PRE_SALE_STR;
    } else if (m_state == State.Sale) {
      stateString = SALE_STR;
    } else if (m_state == State.PublicUse) {
      stateString = PUBLIC_USE_STR;
    }
  }
  
  /**
  * @dev Get price of one token in wei.
  * @return Price of one token in wei.
  */
  function tokenPriceInWei() public view returns (uint256) {
    return calcTokenPriceInWei();
  }
  
  /**
  * @dev Get address of the bank.
  * @return Address of the bank. 
  */
  function bank() external view returns(address) {
    return m_bank;
  }
  
  /**
  * @dev Get timestamp of first entrance to sale state.
  * @return Timestamp of first entrance to sale state.
  */
  function firstEntranceToSaleStateUNIX() 
    external
    view 
    returns(uint256) 
  {
    return m_firstEntranceToSaleStateUNIX;
  }
  
  /**
  * @dev Get address of the price setter.
  * @return Address of the price setter.
  */
  function priceSetter() external view returns (address) {
    return m_priceSetter;
  }

////////////////////
// public methods
// only for owner
//
  /**
  * @dev Owner do disown.
  */ 
  function disown() external atState(State.PublicUse) onlyOwner() {
    delete m_owner;
  }
  
  /**
  * @dev Set state of contract working.
  * @param newState String representation of new state.
  */ 
  function setState(string newState) 
    external 
    onlyOwner()
    checkAccess()
  {
    if (keccak256(newState) == keccak256(PRE_SALE_STR)) {
      m_state = State.PreSale;
    } else if (keccak256(newState) == keccak256(SALE_STR)) {
      if (m_firstEntranceToSaleStateUNIX == 0) 
        m_firstEntranceToSaleStateUNIX = now;
        
      m_state = State.Sale;
    } else if (keccak256(newState) == keccak256(PUBLIC_USE_STR)) {
      m_state = State.PublicUse;
    } else {
      // if newState not valid string
      revert();
    }
    StateChanged(msg.sender, m_state);
  }

  /**
  * If token price not fix then actual price 
  * always will be tokenPriceInWeiForDay(day).
  *
  * @dev Set price of one token in wei and fix it.
  * @param newTokenPriceInWei Price of one token in wei.
  */ 
  function setAndFixTokenPriceInWei(uint256 newTokenPriceInWei) 
    external
    checkAccess()
  {
    require(msg.sender == m_owner || msg.sender == m_priceSetter);
    m_isFixedTokenPrice = true;
    m_tokenPriceInWei = newTokenPriceInWei;
    PriceChanged(msg.sender, m_tokenPriceInWei, m_isFixedTokenPrice);
  }
  
  /**
  * If token price is unfixed then actual will be tokenPriceInWeiForDay(day).
  * 
  * @dev Set unfix token price to true.
  */
  function unfixTokenPriceInWei() 
    external
    checkAccess()
  {
    require(msg.sender == m_owner || msg.sender == m_priceSetter);
    m_isFixedTokenPrice = false;
    PriceChanged(msg.sender, m_tokenPriceInWei, m_isFixedTokenPrice);
  }
  
  /**
  * @dev Set the PriceSetter address, which has access to set one token price in wei.
  * @param newPriceSetter The address of new PriceSetter.
  */
  function setPriceSetter(address newPriceSetter) 
    external 
    onlyOwner() 
    checkAccess()
  {
    m_priceSetter = newPriceSetter;
  }

  /**
  * @dev Set the bank, which receive 95%ETH from tokens sale.
  * @param newBank The address of new bank.
  */
  function setBank(address newBank) 
    external
    validRecipient(newBank) 
    onlyOwner()
    checkAccess()
  {
    require(newBank != address(0));
    m_bank = newBank;
  }

////////////////////////
// internal pure methods
//
  /**
  * @dev Convert token to wei.
  * @param tokensAmount Amout of tokens.
  * @param tokenPrice One token price in wei.
  * @return weiAmount Result amount of convertation. 
  */
  function tokensToWei(uint256 tokensAmount, uint256 tokenPrice) 
    internal
    pure
    returns(uint256 weiAmount)
  {
    weiAmount = tokensAmount.mul(tokenPrice); 
  }
  
  /**
  * @dev Conver wei to token.
  * @param weiAmount Wei amout.
  * @param tokenPrice One token price in wei.
  * @return tokensAmount Result amount of convertation.
  */
  function weiToTokens(uint256 weiAmount, uint256 tokenPrice) 
    internal 
    pure 
    returns(uint256 tokensAmount) 
  {
    tokensAmount = weiAmount.div(tokenPrice);
  }
 
////////////////////////
// private view methods
//
  /**
  * @dev Get actual token price.
  * @return price One token price in wei. 
  */
  function calcTokenPriceInWei() 
    private 
    view 
    returns(uint256 price) 
  {
    if (m_isFixedTokenPrice) {
      // price is fixed, return current val
      price = m_tokenPriceInWei;
    } else {
      // price not fixed, we must to calc price
      if (m_firstEntranceToSaleStateUNIX == 0) {
        // if contract dont enter to SaleState then price = 0 
        price = 0;
      } else {
        // calculate day after first Entrance To Sale State
        uint256 day = now.sub(m_firstEntranceToSaleStateUNIX).div(1 days);
        // use special formula for calcutation price
        price = tokenPriceInWeiForDay(day);
      }
    } 
  }
  
  /**
  * @dev Get token price for specific day after starting sale tokens.
  * @param day Secific day.
  * @return price One token price in wei for specific day. 
  */
  function tokenPriceInWeiForDay(uint256 day) 
    private 
    view 
    returns(uint256 price)
  {
    // day 1:   price 1*10^(decimals) TOKEN = 0.001 ETH
    //          price 1 TOKEN = 1 * 10^(-3) ETH / 10^(decimals), in ETH
    //          convert to wei:
    //          price 1 TOKEN = 1 * 10^(-3) * wei * 10^(-decimals)
    //          price 1 TOKEN = 1 * 10^(-3) * 10^(18) * 10^(-decimals)
    //          price 1 TOKEN = 1 * 10^(15) * 10^(-decimals), in WEI
    
    // day 2:   price 1*10^(decimals) TOKEN = 0.002 ETH;
    //          price 1 TOKEN = 2 * 10^(15) * 10^(-decimals), in WEI
    // ...
    // day 12:  price 1*10^(decimals) TOKEN = 0.012 ETH;
    //          price 1 TOKEN = 12 * 10^(15) * 10^(-decimals), in WEI
    
    // day >12: price 1*10^(decimals) TOKEN = 0.012 ETH;
    //          price 1 TOKEN = 12 * 10^(15) * 10^(-decimals), in WEI

    // from 0 to 11 - sum is 12 days
    if (day <= 11) 
      price = day.add(1);// because from >0h to <24h after start day will be 0, 
    else                 // but for calc price it must be 1;
      price = 12;
    // convert to WEI
    price = price.mul(uint256(10**15)).div(10**uint256(m_decimals));
  }
  
  /**
  * @notice It is always must be true, for correct withdrawals and receivers ETH.
  *
  * Check if this.balance >= m_myDebtInWei.
  */
  function checkValidityOfBalance() private view {
    // assertion is not a strict equality of the balance because the contract 
    // can be forcibly sent ether without going through the byTokens() func.
    // selfdestruct does not trigger a contract&#39;s fallback function. 
    // see: http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function
    assert(this.balance >= m_myDebtInWei);
  }
}