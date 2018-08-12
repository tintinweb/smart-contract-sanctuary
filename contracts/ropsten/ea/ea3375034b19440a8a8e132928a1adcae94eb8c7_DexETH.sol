pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  /**
   * @dev Multiplies two numbers, throws on overflow.
   * @param a The first number.
   * @param b The second number.
   * @return A uint result.
   */
  function safeMul(uint a, uint b) internal pure returns (uint c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    if (a == 0) {
      return 0;
    }
    
    c = a * b;
    assert(c / a == b);
    return c;
  }
  
  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param a The first number.
   * @param b The second number.
   * @return A uint result.
   */
  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  
  /**
   * @dev Adds two numbers, throws on overflow.
   * @param a The first number.
   * @param b The second number.
   * @return A uint result.
  */
  function safeAdd(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Token
 */
contract Token {
  // The token decimals.
  uint public decimals;
  
  // The token name.
  string public name;

  /**
   * Event for transfer logging.
   * @param _from The address which paid the tokens.
   * @param _to The address which got the tokens.
   * @param _value The amount that was transfered.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
  /**
   * Event for approval logging.
   * @param _owner The address which owns the funds.
   * @param _spender The address which can spend the funds.
   * @param _value The amount that was approved.
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  /**
   * @dev Total number of tokens in existence.
   * @return A uint256 total amount of tokens.
   */
  function totalSupply() public view returns (uint256 supply);

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public view returns (uint256 balance);

  /**
   * @dev Transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   * @return A bool indicating whether the transfer was successful or not.
   */
  function transfer(address _to, uint256 _value) public returns (bool success);

  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from.
   * @param _to address The address which you want to transfer to.
   * @param _value uint256 the amount of tokens to be transferred.
   * @return A bool indicating whether the transfer was successful or not.
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @return A bool indicating whether the approval was successful or not.
   */
  function approve(address _spender, uint256 _value) public returns (bool success);

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

/**
 * @title DexETH
 */
contract DexETH is SafeMath {
  // The account that is this contract owner.
  address public admin;
  
  // The account that will receive fees.
  address public feeAccount; 
  
  // The taker fee in percentage times (1 ether) (1000000000000000 = 0.1%).
  uint public feeTake; 
  
  // Mapping of token addresses to discount value.
  mapping (address => uint) public discounts;
  
  // Mapping of token addresses to mapping of account balances (token=0 means Ether).
  mapping (address => mapping (address => uint)) public tokens;
  
  // Mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled).
  mapping (address => mapping (bytes32 => uint)) public orderFills;
  
  // Mapping of user accounts forbiden to deposit eth and tokens.
  mapping (address => bool) public bannedAccounts;
   
  /**
   * Event for order cancel logging.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param expires The block at which the order expires.
   * @param nonce The order nonce.
   * @param user The creator of the order.
   * @param v  The recovery id.
   * @param r The first half of the ECDSA signature.
   * @param s The second half of the ECDSA signature.
   */
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  
  /**
   * Event for trade logging.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the trade.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the trade.
   * @param get The maker user.
   * @param give The taker user.
   * @param nonce The order nonce.
   */
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, uint nonce);
  
  /**
   * Event for token purchase logging.
   * @param token The token that was deposited.
   * @param user The user that deposited.
   * @param amount The amount that was deposited.
   * @param balance The new balance that the user has in this contract.
   */
  event Deposit(address token, address user, uint amount, uint balance);
  
  /**
   * Event for token purchase logging.
   * @param token The token that was withdrawn.
   * @param user The user that withdrew.
   * @param amount The amount that was withdrawn.
   * @param balance The new balance that the user has in this contract.
   */
  event Withdraw(address token, address user, uint amount, uint balance);
  
  /**
   * @dev Constructor.
   * @param _admin The account that is owner of this contract.
   * @param _feeAccount The account that will receive fees.
   */
  constructor(address _admin, address _feeAccount) public {
    admin = _admin;
    feeAccount = _feeAccount;
  }
  
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }
  
  /**
   * @dev Allows the current admin to transfer ownership of this contract to a new admin.
   * @param _admin The new account to transfer ownership to.
   */
  function changeAdmin(address _admin) onlyAdmin external {
    admin = _admin;
  }

  /**
   * @dev Allows the current admin to change the account that receives the fees.
   * @param _feeAccount The new account that will receive the fees.
   */
  function changeFeeAccount(address _feeAccount) onlyAdmin external {
    feeAccount = _feeAccount;
  }

  /**
   * @dev Allows the current admin to change the taker fee value.
   * @notice Can range between 0 and 2500000000000000 (0.25%) included.
   * @param _feeTake The new value for taker fee.
   */
  function changeFeeTake(uint _feeTake) onlyAdmin external {
    require (0 <=_feeTake && _feeTake <= 2500000000000000);
    feeTake = _feeTake;
  }

  /**
   * @dev Sets discounts in range 0 to 100 included to the user accounts.
   * @param users The user accounts to set the discount.
   * @param discount The discount value to use ranging from 0 to 100 included.
   */
  function addDiscounts(address[] users, uint discount) onlyAdmin external {
    require(0 <= discount && discount <= 100);

    for (uint i = 0; i < users.length; i++) {
      discounts[users[i]] = discount;
    }
  }
  
  /**
   * @dev Allows the current admin to add users to the ban list.
   * @param users The accounts that will be added to the ban list.
   */
  function banAccounts(address[] users) onlyAdmin external {
    for (uint i = 0; i < users.length; i++) {
      bannedAccounts[users[i]] = true;
    }
  }
  
  /**
   * @dev Allows the current admin to remove users from the ban list.
   * @param users The accounts that will be removed from the ban list.
   */
  function unbanAccounts(address[] users) onlyAdmin external {
    for (uint i = 0; i < users.length; i++) {
      bannedAccounts[users[i]] = false;
    }
  }
  
  /**
   * @dev Allows the current admin to withdraw batch of tokens and/or eth from this contract back to their owner in a single transaction.
   * @param user The account that will have it&#39;s tokens and/or eth withdrawn.
   * @param _tokens The tokens and/or eth that will be withdrawn.
   */
  function withdrawAllForAccount(address user, address[] _tokens) onlyAdmin external {
      for (uint i = 0; i < _tokens.length; i++) {
          if (tokens[_tokens[i]][user] > 0) {
              uint amount = tokens[_tokens[i]][user];
              
              if (_tokens[i] == 0) {
                user.transfer(amount);
              }
              else {
                require(Token(_tokens[i]).transfer(user, amount));
              }
              
              tokens[_tokens[i]][user] = 0;
              emit Withdraw(_tokens[i], user, amount, 0);
          }
      }
  }

  /**
   * @dev Allows the current transaction sender to deposit eth from his account to this contract.
   * @notice The value sent will be deposited.
   */
  function deposit() payable external {
    require(!bannedAccounts[msg.sender]);
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  /**
   * @dev Allows the current transaction sender to withdraw eth from this contract back to his account.
   * @param amount The amount to withdraw.
   */
  function withdraw(uint amount) external {
    require(tokens[0][msg.sender] >= amount);

    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
    msg.sender.transfer(amount);

    emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  /**
   * @dev Allows the current transaction sender to deposit tokens from his account to this contract.
   * @param token The token to deposit.
   * @param amount The amount to deposit.
   */
  function depositToken(address token, uint amount) external {
    require(!bannedAccounts[msg.sender]);
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    require(token != 0);
    require(Token(token).transferFrom(msg.sender, this, amount));

    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  /**
   * @dev Allows the current transaction sender to withdraw tokens from this contract back to his account.
   * @param token The token to withdraw.
   * @param amount The amount to withdraw.
   */
  function withdrawToken(address token, uint amount) external {
    require(token!=0);
    require(tokens[token][msg.sender] >= amount);

    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
    require(Token(token).transfer(msg.sender, amount));
    
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }
  
  /**
   * @dev Allows the current transaction sender to withdraw batch of tokens and/or eth from this contract back to his account in a single transaction.
   * @param _tokens The tokens and/or eth that will be withdrawn.
   */
  function withdrawAll(address[] _tokens) external {
      for (uint i = 0; i < _tokens.length; i++) {
          if (tokens[_tokens[i]][msg.sender] > 0) {
              uint amount = tokens[_tokens[i]][msg.sender];
              
              if (_tokens[i] == 0) {
                msg.sender.transfer(amount);
              }
              else {
                require(Token(_tokens[i]).transfer(msg.sender, amount));
              }
              
              tokens[_tokens[i]][msg.sender] = 0;
              emit Withdraw(_tokens[i], msg.sender, amount, 0);
          }
      }
  }

  /**
   * @dev Gets the balance of the specified address in this contract.
   * @param token The token to check the balance of.
   * @param user The address to query the the balance of.
   * @return An uint representing the amount owned by the passed address in this contract.
   */
  function balanceOf(address token, address user) view external returns (uint) {
    return tokens[token][user];
  }
   
  /**
   * @dev Executes a trade against an order with the current transaction sender as the taker.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param expires The block at which the order expires.
   * @param nonce The order nonce.
   * @param user The creator of the order.
   * @param v  The recovery id.
   * @param r The first half of the ECDSA signature.
   * @param s The second half of the ECDSA signature.
   * @param amount The amount to be executed.
   */
  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) external {
    //amount is in amountGet terms
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    require(
      (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
      block.number <= expires &&
      safeAdd(orderFills[user][hash], amount) <= amountGet);

    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
    emit Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender, nonce);
  }

  /**
   * @dev Swaps the balances as the result of a trade against an order with the current transaction sender as the taker.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param user The creator of the order.
   * @param amount The amount to be executed.
   */
  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
    uint feeTakeXfer = 0;
    if (feeTake != 0) {
      uint takeDiscount = discounts[msg.sender];
      if (takeDiscount < 100) {
          uint discountedFeeTake = safeMul(feeTake / 100, safeSub(100, takeDiscount));
          feeTakeXfer = safeMul(amount, discountedFeeTake) / (1 ether);
      }
    }

    tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
    tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], amount);

    tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
    tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
    
    if (feeTakeXfer != 0) { 
      tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], feeTakeXfer); 
    }
  }

  /**
   * @dev Checks if a trade against an order will be successful.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param expires The block at which the order expires.
   * @param nonce The order nonce.
   * @param user The creator of the order.
   * @param v  The recovery id.
   * @param r The first half of the ECDSA signature.
   * @param s The second half of the ECDSA signature.
   * @param amount The amount to be executed.
   * @param sender The user that will be executing the trade.
   * @return A bool indicating whether the trade would have been successful or not.
   */
  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) view external returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) {
      return false;
    }
    
    return true;
  }

  /**
   * @dev Gets the available volume of an order.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param expires The block at which the order expires.
   * @param nonce The order nonce.
   * @param user The creator of the order.
   * @param v  The recovery id.
   * @param r The first half of the ECDSA signature.
   * @param s The second half of the ECDSA signature.
   * @return An uint representing the available order volume.
   */
  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) view public returns(uint) {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user &&
      block.number <= expires
    )) {
      return 0;
    }

    uint available1 = safeSub(amountGet, orderFills[user][hash]);
    uint available2 = safeMul(tokens[tokenGive][user], amountGet) / amountGive;
    if (available1<available2) {
      return available1;
    }

    return available2;
  }

  /**
   * @dev Gets the filled volume of an order.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param expires The block at which the order expires.
   * @param nonce The order nonce.
   * @param user The creator of the order.
   * @return An uint representing the filled order volume.
   */
  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) view external returns(uint) {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

  /**
   * @dev Cancels an order by setting the filled amount to the order amount thus making the available volume 0.
   * @param tokenGet The token that is on the get side of the order.
   * @param amountGet The amount that is on the get side of the order.
   * @param tokenGive The token that is on the give side of the order.
   * @param amountGive The amount that is on the give side of the order.
   * @param expires The block at which the order expires.
   * @param nonce The order nonce.
   * @param v  The recovery id.
   * @param r The first half of the ECDSA signature.
   * @param s The second half of the ECDSA signature.
   */
  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) external {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == msg.sender);
    
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }
}