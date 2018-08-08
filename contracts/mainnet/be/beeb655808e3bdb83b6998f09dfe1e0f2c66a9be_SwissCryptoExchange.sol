pragma solidity ^0.4.18;

// File: contracts/AccountLevels.sol

contract AccountLevels {
  //given a user, returns an account level
  //0 = regular user (pays take fee and make fee)
  //1 = market maker silver (pays take fee, no make fee, gets rebate)
  //2 = market maker gold (pays take fee, no make fee, gets entire counterparty&#39;s take fee as rebate)
  function accountLevel(address user) public constant returns(uint);
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

// File: contracts/SwissCryptoExchange.sol

/**
 * @title SwissCryptoExchange
 */
contract SwissCryptoExchange {
  using SafeMath for uint256;

  // Storage definition.
  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees
  address public accountLevelsAddr; //the address of the AccountLevels contract
  uint256 public feeMake; //percentage times (1 ether)
  uint256 public feeTake; //percentage times (1 ether)
  uint256 public feeRebate; //percentage times (1 ether)
  mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => bool) public whitelistedTokens; //mapping of whitelisted token addresses (token=0 means Ether)
  mapping (address => bool) public whitelistedUsers; // mapping of whitelisted users that can perform trading
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint256)) public orderFills; //mapping of user accounts to mapping of order hashes to uint256s (amount of order that has been filled)

  // Events definition.
  event Order(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user);
  event Cancel(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address get, address give);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

  /**
   * @dev Create a new instance of the SwissCryptoExchange contract.
   * @param _admin             address Admin address
   * @param _feeAccount        address Fee Account address
   * @param _accountLevelsAddr address AccountLevels contract address
   * @param _feeMake           uint256 FeeMake amount
   * @param _feeTake           uint256 FeeTake amount
   * @param _feeRebate         uint256 FeeRebate amount
   */
  function SwissCryptoExchange(
    address _admin,
    address _feeAccount,
    address _accountLevelsAddr,
    uint256 _feeMake,
    uint256 _feeTake,
    uint256 _feeRebate
  )
    public
  {
    // Ensure the admin address is valid.
    require(_admin != 0x0);

    // Store the values.
    admin = _admin;
    feeAccount = _feeAccount;
    accountLevelsAddr = _accountLevelsAddr;
    feeMake = _feeMake;
    feeTake = _feeTake;
    feeRebate = _feeRebate;

    // Validate "ethereum address".
    whitelistedTokens[0x0] = true;
  }

  /**
   * @dev Ensure the function caller is the contract admin.
   */
  modifier onlyAdmin() { 
    require(msg.sender == admin);
    _; 
  }

  /**
   * @dev The fallback function is not used for receiving money. If someone sends
   *      wei directly to the contract address the transaction will fail.
   */
  function () public payable {
    revert();
  }

  /**
   * @dev Change the admin address.
   * @param _admin address The new admin address
   */
  function changeAdmin(address _admin) public onlyAdmin {
    // The provided address should be valid and different from the current one.
    require(_admin != 0x0 && admin != _admin);

    // Store the new value.
    admin = _admin;
  }

  /**
   * @dev Change the AccountLevels contract address. This address could be set to 0x0
   *      if the functionality is not needed.
   * @param _accountLevelsAddr address The new AccountLevels contract address
   */
  function changeAccountLevelsAddr(address _accountLevelsAddr) public onlyAdmin {
    // Store the new value.
    accountLevelsAddr = _accountLevelsAddr;
  }

  /**
   * @dev Change the feeAccount address.
   * @param _feeAccount address
   */
  function changeFeeAccount(address _feeAccount) public onlyAdmin {
    // The provided address should be valid.
    require(_feeAccount != 0x0);

    // Store the new value.
    feeAccount = _feeAccount;
  }

  /**
   * @dev Change the feeMake amount.
   * @param _feeMake uint256 New fee make.
   */
  function changeFeeMake(uint256 _feeMake) public onlyAdmin {
    // Store the new value.
    feeMake = _feeMake;
  }

  /**
   * @dev Change the feeTake amount.
   * @param _feeTake uint256 New fee take.
   */
  function changeFeeTake(uint256 _feeTake) public onlyAdmin {
    // The new feeTake should be greater than or equal to the feeRebate.
    require(_feeTake >= feeRebate);

    // Store the new value.
    feeTake = _feeTake;
  }

  /**
   * @dev Change the feeRebate amount.
   * @param _feeRebate uint256 New fee rebate.
   */
  function changeFeeRebate(uint256 _feeRebate) public onlyAdmin {
    // The new feeRebate should be less than or equal to the feeTake.
    require(_feeRebate <= feeTake);

    // Store the new value.
    feeRebate = _feeRebate;
  }

  /**
   * @dev Add a ERC20 token contract address to the whitelisted ones.
   * @param token address Address of the contract to be added to the whitelist.
   */
  function addWhitelistedTokenAddr(address token) public onlyAdmin {
    // Token address should not be 0x0 (ether) and it should not be already whitelisted.
    require(token != 0x0 && !whitelistedTokens[token]);

    // Change the flag for this contract address to true.
    whitelistedTokens[token] = true;
  }

  /**
   * @dev Remove a ERC20 token contract address from the whitelisted ones.
   * @param token address Address of the contract to be removed from the whitelist.
   */
  function removeWhitelistedTokenAddr(address token) public onlyAdmin {
    // Token address should not be 0x0 (ether) and it should be whitelisted.
    require(token != 0x0 && whitelistedTokens[token]);

    // Change the flag for this contract address to false.
    whitelistedTokens[token] = false;
  }

  /**
   * @dev Add an user address to the whitelisted ones.
   * @param user address Address to be added to the whitelist.
   */
  function addWhitelistedUserAddr(address user) public onlyAdmin {
    // Address provided should be valid and not already whitelisted.
    require(user != 0x0 && !whitelistedUsers[user]);

    // Change the flag for this address to false.
    whitelistedUsers[user] = true;
  }

  /**
   * @dev Remove an user address from the whitelisted ones.
   * @param user address Address to be removed from the whitelist.
   */
  function removeWhitelistedUserAddr(address user) public onlyAdmin {
    // Address provided should be valid and whitelisted.
    require(user != 0x0 && whitelistedUsers[user]);

    // Change the flag for this address to false.
    whitelistedUsers[user] = false;
  }

  /**
   * @dev Deposit wei into the exchange contract.
   */
  function deposit() public payable {
    // Only whitelisted users can make deposits.
    require(whitelistedUsers[msg.sender]);

    // Add the deposited wei amount to the user balance.
    tokens[0x0][msg.sender] = tokens[0x0][msg.sender].add(msg.value);

    // Trigger the event.
    Deposit(0x0, msg.sender, msg.value, tokens[0x0][msg.sender]);
  }

  /**
   * @dev Withdraw wei from the exchange contract back to the user. 
   * @param amount uint256 Wei amount to be withdrawn.
   */
  function withdraw(uint256 amount) public {
    // Requester should have enough balance.
    require(tokens[0x0][msg.sender] >= amount);
  
    // Substract the withdrawn wei amount from the user balance.
    tokens[0x0][msg.sender] = tokens[0x0][msg.sender].sub(amount);

    // Transfer the wei to the requester.
    msg.sender.transfer(amount);

    // Trigger the event.
    Withdraw(0x0, msg.sender, amount, tokens[0x0][msg.sender]);
  }

  /**
   * @dev Perform a new token deposit to the exchange contract.
   * @dev Remember to call ERC20(address).approve(this, amount) or this contract will not
   *      be able to do the transfer on your behalf.
   * @param token  address Address of the deposited token contract
   * @param amount uint256 Amount to be deposited
   */
  function depositToken(address token, uint256 amount)
    public
  {
    // Should not deposit wei using this function and
    // token contract address should be whitelisted.
    require(token != 0x0 && whitelistedTokens[token]);
      
    // Only whitelisted users can make deposits.
    require(whitelistedUsers[msg.sender]);

    // Add the deposited token amount to the user balance.
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    
    // Transfer tokens from caller to this contract account.
    require(ERC20(token).transferFrom(msg.sender, address(this), amount));
  
    // Trigger the event.    
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  /**
   * @dev Withdraw the given token amount from the requester balance.
   * @param token  address Address of the withdrawn token contract
   * @param amount uint256 Amount of tokens to be withdrawn
   */
  function withdrawToken(address token, uint256 amount) public {
    // Should not withdraw wei using this function.
    require(token != 0x0);

    // Requester should have enough balance.
    require(tokens[token][msg.sender] >= amount);

    // Substract the withdrawn token amount from the user balance.
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    
    // Transfer the tokens to the investor.
    require(ERC20(token).transfer(msg.sender, amount));

    // Trigger the event.
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  /**
   * @dev Check the balance of the given user in the given token.
   * @param token address Address of the token contract
   * @param user  address Address of the user whom balance will be queried
   */
  function balanceOf(address token, address user)
    public
    constant
    returns (uint256)
  {
    return tokens[token][user];
  }

  /**
   * @dev Place a new order to the this contract. 
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param expires    uint256
   * @param nonce      uint256
   */
  function order(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce
  )
    public
  {
    // Order placer address should be whitelisted.
    require(whitelistedUsers[msg.sender]);

    // Order tokens addresses should be whitelisted. 
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

    // Calculate the order hash.
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    
    // Store the order.
    orders[msg.sender][hash] = true;

    // Trigger the event.
    Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }

  /**
   * @dev Cancel an existing order.
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param expires    uint256
   * @param nonce      uint256
   * @param v          uint8
   * @param r          bytes32
   * @param s          bytes32
   */
  function cancelOrder(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
  {
    // Calculate the order hash.
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    
    // Ensure the message validity.
    require(validateOrderHash(hash, msg.sender, v, r, s));
    
    // Fill the order to the requested amount.
    orderFills[msg.sender][hash] = amountGet;

    // Trigger the event.
    Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }

  /**
   * @dev Perform a trade.
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param expires    uint256
   * @param nonce      uint256
   * @param user       address
   * @param v          uint8
   * @param r          bytes32
   * @param s          bytes32
   * @param amount     uint256 Traded amount - in amountGet terms
   */
  function trade(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 amount 
  )
    public
  {
    // Only whitelisted users can perform trades.
    require(whitelistedUsers[msg.sender]);

    // Only whitelisted tokens can be traded.
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

    // Expire block number should be greater than current block.
    require(block.number <= expires);

    // Calculate the trade hash.
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    
    // Validate the hash.
    require(validateOrderHash(hash, user, v, r, s));

    // Ensure that after the trade the ordered amount will not be excedeed.
    require(SafeMath.add(orderFills[user][hash], amount) <= amountGet); 
    
    // Add the traded amount to the order fill.
    orderFills[user][hash] = orderFills[user][hash].add(amount);

    // Trade balances.
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    
    // Trigger the event.
    Trade(tokenGet, amount, tokenGive, SafeMath.mul(amountGive, amount).div(amountGet), user, msg.sender);
  }

  /**
   * @dev Check if the trade with provided parameters will pass or not.
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param expires    uint256
   * @param nonce      uint256
   * @param user       address
   * @param v          uint8
   * @param r          bytes32
   * @param s          bytes32
   * @param amount     uint256
   * @param sender     address
   * @return bool
   */
  function testTrade(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 amount,
    address sender
  )
    public
    constant
    returns(bool)
  {
    // Traders should be whitelisted.
    require(whitelistedUsers[user] && whitelistedUsers[sender]);

    // Tokens should be whitelisted.
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

    // Sender should have at least the amount he wants to trade and 
    require(tokens[tokenGet][sender] >= amount);

    // order should have available volume to fill.
    return availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount;
  }

  /**
   * @dev Calculate the available volume for a given trade.
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param expires    uint256
   * @param nonce      uint256
   * @param user       address
   * @param v          uint8
   * @param r          bytes32
   * @param s          bytes32
   * @return uint256
   */
  function availableVolume(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    constant
    returns (uint256)
  {
    // User should be whitelisted.
    require(whitelistedUsers[user]);

    // Tokens should be whitelisted.
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

    // Calculate the hash.
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);

    // If the order is not valid or the trade is expired early exit with 0.
    if (!(validateOrderHash(hash, user, v, r, s) && block.number <= expires)) {
      return 0;
    }

    // Condition is used for ensuring the the value returned is
    //   - the maximum available balance of the user in tokenGet terms if the user can&#39;t fullfil all the order
    //     - SafeMath.sub(amountGet, orderFills[user][hash])
    //     - amountGet - amountAvailableForFill
    //   - the available balance of the the user in tokenGet terms if the user has enough to fullfil all the order 
    //     - SafeMath.mul(tokens[tokenGive][user], amountGet).div(amountGive) 
    //     - balanceGiveAvailable * amountGet / amountGive
    //     - amountGet / amountGive represents the exchange rate 
    if (SafeMath.sub(amountGet, orderFills[user][hash]) < SafeMath.mul(tokens[tokenGive][user], amountGet).div(amountGive)) {
      return SafeMath.sub(amountGet, orderFills[user][hash]);
    }

    return SafeMath.mul(tokens[tokenGive][user], amountGet).div(amountGive);
  }

  /**
   * @dev Get the amount filled for the given order.
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param expires    uint256
   * @param nonce      uint256
   * @param user       address
   * @return uint256
   */
  function amountFilled(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user
  )
    public
    constant
    returns (uint256)
  {
    // User should be whitelisted.
    require(whitelistedUsers[user]);

    // Tokens should be whitelisted.
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

    // Return the amount filled for the given order.
    return orderFills[user][keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce)];
  }

    /**
   * @dev Trade balances of given tokens amounts between two users.
   * @param tokenGet   address
   * @param amountGet  uint256
   * @param tokenGive  address
   * @param amountGive uint256
   * @param user       address
   * @param amount     uint256
   */
  function tradeBalances(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    address user,
    uint256 amount
  )
    private
  {
    // Calculate the constant taxes.
    uint256 feeMakeXfer = amount.mul(feeMake).div(1 ether);
    uint256 feeTakeXfer = amount.mul(feeTake).div(1 ether);
    uint256 feeRebateXfer = 0;
    
    // Calculate the tax according to account level.
    if (accountLevelsAddr != 0x0) {
      uint256 accountLevel = AccountLevels(accountLevelsAddr).accountLevel(user);
      if (accountLevel == 1) {
        feeRebateXfer = amount.mul(feeRebate).div(1 ether);
      } else if (accountLevel == 2) {
        feeRebateXfer = feeTakeXfer;
      }
    }

    // Update the balances for both maker and taker and add the fee to the feeAccount.
    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTakeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.add(feeRebateXfer).sub(feeMakeXfer));
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeMakeXfer.add(feeTakeXfer).sub(feeRebateXfer));
    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
  }

  /**
   * @dev Validate an order hash.
   * @param hash bytes32
   * @param user address
   * @param v    uint8
   * @param r    bytes32
   * @param s    bytes32
   * @return bool
   */
  function validateOrderHash(
    bytes32 hash,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    private
    constant
    returns (bool)
  {
    return (
      orders[user][hash] ||
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user
    );
  }
}