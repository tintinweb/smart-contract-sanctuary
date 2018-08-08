pragma solidity ^0.4.19;

// ERC20 token protocol, see more details at
// https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// And also https://github.com/ethereum/eips/issues/20

contract Token {

  string public name;
  string public symbol;
  uint8 public decimals;

  function totalSupply() constant returns (uint256 supply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// Safe mathematics to make the code more readable

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

// Ownable interface to simplify owner checks

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
  }
}

// Interface for trading discounts and rebates for specific accounts

contract AccountModifiersInterface {
  function accountModifiers(address _user) constant returns(uint takeFeeDiscount, uint rebatePercentage);
  function tradeModifiers(address _maker, address _taker) constant returns(uint takeFeeDiscount, uint rebatePercentage);
}

// Interface for trade tacker

contract TradeTrackerInterface {
  function tradeComplete(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, address _get, address _give, uint _takerFee, uint _makerRebate);
}

// Exchange contract

contract TokenStore is SafeMath, Ownable {

  // The account that will receive fees
  address feeAccount;

  // The account that stores fee discounts/rebates
  address accountModifiers;

  // Trade tracker account
  address tradeTracker;

  // We charge only the takers and this is the fee, percentage times 1 ether
  uint public fee;

  // Mapping of token addresses to mapping of account balances (token 0 means Ether)
  mapping (address => mapping (address => uint)) public tokens;

  // Mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)
  mapping (address => mapping (bytes32 => uint)) public orderFills;

  // Address of a next and previous versions of the contract, also status of the contract
  // can be used for user-triggered fund migrations
  address public successor;
  address public predecessor;
  bool public deprecated;
  uint16 public version;

  // Logging events
  // Note: Order creation is handled off-chain, see explanation further below
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, uint nonce);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);
  event FundsMigrated(address user);

  function TokenStore(uint _fee, address _predecessor) {
    feeAccount = owner;
    fee = _fee;
    predecessor = _predecessor;
    deprecated = false;
    if (predecessor != address(0)) {
      version = TokenStore(predecessor).version() + 1;
    } else {
      version = 1;
    }
  }

  // Throw on default handler to prevent direct transactions of Ether
  function() {
    revert();
  }

  modifier deprecable() {
    require(!deprecated);
    _;
  }

  function deprecate(bool _deprecated, address _successor) onlyOwner {
    deprecated = _deprecated;
    successor = _successor;
  }

  function changeFeeAccount(address _feeAccount) onlyOwner {
    require(_feeAccount != address(0));
    feeAccount = _feeAccount;
  }

  function changeAccountModifiers(address _accountModifiers) onlyOwner {
    accountModifiers = _accountModifiers;
  }

  function changeTradeTracker(address _tradeTracker) onlyOwner {
    tradeTracker = _tradeTracker;
  }

  // Fee can only be decreased!
  function changeFee(uint _fee) onlyOwner {
    require(_fee <= fee);
    fee = _fee;
  }

  // Allows a user to get her current discount/rebate
  function getAccountModifiers() constant returns(uint takeFeeDiscount, uint rebatePercentage) {
    if (accountModifiers != address(0)) {
      return AccountModifiersInterface(accountModifiers).accountModifiers(msg.sender);
    } else {
      return (0, 0);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  // Deposits, withdrawals, balances
  ////////////////////////////////////////////////////////////////////////////////

  function deposit() payable deprecable {
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint _amount) {
    require(tokens[0][msg.sender] >= _amount);
    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], _amount);
    if (!msg.sender.call.value(_amount)()) {
      revert();
    }
    Withdraw(0, msg.sender, _amount, tokens[0][msg.sender]);
  }

  function depositToken(address _token, uint _amount) deprecable {
    // Note that Token(_token).approve(this, _amount) needs to be called
    // first or this contract will not be able to do the transfer.
    require(_token != 0);
    if (!Token(_token).transferFrom(msg.sender, this, _amount)) {
      revert();
    }
    tokens[_token][msg.sender] = safeAdd(tokens[_token][msg.sender], _amount);
    Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }

  function withdrawToken(address _token, uint _amount) {
    require(_token != 0);
    require(tokens[_token][msg.sender] >= _amount);
    tokens[_token][msg.sender] = safeSub(tokens[_token][msg.sender], _amount);
    if (!Token(_token).transfer(msg.sender, _amount)) {
      revert();
    }
    Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }

  function balanceOf(address _token, address _user) constant returns (uint) {
    return tokens[_token][_user];
  }

  ////////////////////////////////////////////////////////////////////////////////
  // Trading
  ////////////////////////////////////////////////////////////////////////////////

  // Note: Order creation happens off-chain but the orders are signed by creators,
  // we validate the contents and the creator address in the logic below

  function trade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive,
      uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint _amount) {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    // Check order signatures and expiration, also check if not fulfilled yet
		if (ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), _v, _r, _s) != _user ||
      block.number > _expires ||
      safeAdd(orderFills[_user][hash], _amount) > _amountGet) {
      revert();
    }
    tradeBalances(_tokenGet, _amountGet, _tokenGive, _amountGive, _user, msg.sender, _amount);
    orderFills[_user][hash] = safeAdd(orderFills[_user][hash], _amount);
    Trade(_tokenGet, _amount, _tokenGive, _amountGive * _amount / _amountGet, _user, msg.sender, _nonce);
  }

  function tradeBalances(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive,
      address _user, address _caller, uint _amount) private {

    uint feeTakeValue = safeMul(_amount, fee) / (1 ether);
    uint rebateValue = 0;
    uint tokenGiveValue = safeMul(_amountGive, _amount) / _amountGet; // Proportionate to request ratio

    // Apply modifiers
    if (accountModifiers != address(0)) {
      var (feeTakeDiscount, rebatePercentage) = AccountModifiersInterface(accountModifiers).tradeModifiers(_user, _caller);
      // Check that the discounts/rebates are never higher then 100%
      if (feeTakeDiscount > 100) {
        feeTakeDiscount = 0;
      }
      if (rebatePercentage > 100) {
        rebatePercentage = 0;
      }
      feeTakeValue = safeMul(feeTakeValue, 100 - feeTakeDiscount) / 100;  // discounted fee
      rebateValue = safeMul(rebatePercentage, feeTakeValue) / 100;        // % of actual taker fee
    }

    tokens[_tokenGet][_user] = safeAdd(tokens[_tokenGet][_user], safeAdd(_amount, rebateValue));
    tokens[_tokenGet][_caller] = safeSub(tokens[_tokenGet][_caller], safeAdd(_amount, feeTakeValue));
    tokens[_tokenGive][_user] = safeSub(tokens[_tokenGive][_user], tokenGiveValue);
    tokens[_tokenGive][_caller] = safeAdd(tokens[_tokenGive][_caller], tokenGiveValue);
    tokens[_tokenGet][feeAccount] = safeAdd(tokens[_tokenGet][feeAccount], safeSub(feeTakeValue, rebateValue));

    if (tradeTracker != address(0)) {
      TradeTrackerInterface(tradeTracker).tradeComplete(_tokenGet, _amount, _tokenGive, tokenGiveValue, _user, _caller, feeTakeValue, rebateValue);
    }
  }

  function testTrade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires,
      uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint _amount, address _sender) constant returns(bool) {
    if (tokens[_tokenGet][_sender] < _amount ||
      availableVolume(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s) < _amount) {
      return false;
    }
    return true;
  }

  function availableVolume(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires,
      uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s) constant returns(uint) {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    if (ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), _v, _r, _s) != _user ||
      block.number > _expires) {
      return 0;
    }
    uint available1 = safeSub(_amountGet, orderFills[_user][hash]);
    uint available2 = safeMul(tokens[_tokenGive][_user], _amountGet) / _amountGive;
    if (available1 < available2) return available1;
    return available2;
  }

  function amountFilled(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires,
      uint _nonce, address _user) constant returns(uint) {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    return orderFills[_user][hash];
  }

  function cancelOrder(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires,
      uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) {
    bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    if (!(ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), _v, _r, _s) == msg.sender)) {
      revert();
    }
    orderFills[msg.sender][hash] = _amountGet;
    Cancel(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender, _v, _r, _s);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // Migrations
  ////////////////////////////////////////////////////////////////////////////////

  // User-triggered (!) fund migrations in case contract got updated
  // Similar to withdraw but we use a successor account instead
  // As we don&#39;t store user tokens list on chain, it has to be passed from the outside
  function migrateFunds(address[] _tokens) {

    // Get the latest successor in the chain
    require(successor != address(0));
    TokenStore newExchange = TokenStore(successor);
    for (uint16 n = 0; n < 20; n++) {  // We will look past 20 contracts in the future
      address nextSuccessor = newExchange.successor();
      if (nextSuccessor == address(this)) {  // Circular succession
        revert();
      }
      if (nextSuccessor == address(0)) { // We reached the newest, stop
        break;
      }
      newExchange = TokenStore(nextSuccessor);
    }

    // Ether
    uint etherAmount = tokens[0][msg.sender];
    if (etherAmount > 0) {
      tokens[0][msg.sender] = 0;
      newExchange.depositForUser.value(etherAmount)(msg.sender);
    }

    // Tokens
    for (n = 0; n < _tokens.length; n++) {
      address token = _tokens[n];
      require(token != address(0)); // 0 = Ether, we handle it above
      uint tokenAmount = tokens[token][msg.sender];
      if (tokenAmount == 0) {
        continue;
      }
      if (!Token(token).approve(newExchange, tokenAmount)) {
        revert();
      }
      tokens[token][msg.sender] = 0;
      newExchange.depositTokenForUser(token, tokenAmount, msg.sender);
    }

    FundsMigrated(msg.sender);
  }

  // This is used for migrations only. To be called by previous exchange only,
  // user-triggered, on behalf of the user called the migrateFunds method.
  // Note that it does exactly the same as depositToken, but as this is called
  // by a previous generation of exchange itself, we credit internally not the
  // previous exchange, but the user it was called for.
  function depositForUser(address _user) payable deprecable {
    require(_user != address(0));
    require(msg.value > 0);
    TokenStore caller = TokenStore(msg.sender);
    require(caller.version() > 0); // Make sure it&#39;s an exchange account
    tokens[0][_user] = safeAdd(tokens[0][_user], msg.value);
  }

  function depositTokenForUser(address _token, uint _amount, address _user) deprecable {
    require(_token != address(0));
    require(_user != address(0));
    require(_amount > 0);
    TokenStore caller = TokenStore(msg.sender);
    require(caller.version() > 0); // Make sure it&#39;s an exchange account
    if (!Token(_token).transferFrom(msg.sender, this, _amount)) {
      revert();
    }
    tokens[_token][_user] = safeAdd(tokens[_token][_user], _amount);
  }
}

contract InstantTrade is SafeMath, Ownable {

  // This is needed so we can withdraw funds from other smart contracts
  function() payable {
  }
  
  // End to end trading in a single call
  function instantTrade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive,
      uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint _amount, address _store) payable {
    
    // Fix max fee (0.4%) and always reserve it
    uint totalValue = safeMul(_amount, 1004) / 1000;
    
    // Paying with Ethereum or token? Deposit to the actual store
    if (_tokenGet == address(0)) {
      // Check amount of ether sent to make sure it&#39;s correct
      if (msg.value != totalValue) {
        revert();
      }
      TokenStore(_store).deposit.value(totalValue)();
    } else {
      // Assuming user already approved transfer, transfer first to this contract
      if (!Token(_tokenGet).transferFrom(msg.sender, this, totalValue)) {
        revert();
      }
      // Allow now actual store to deposit
      if (!Token(_tokenGet).approve(_store, totalValue)) {
        revert();
      }
      TokenStore(_store).depositToken(_tokenGet, totalValue);
    }
    
    // Trade
    TokenStore(_store).trade(_tokenGet, _amountGet, _tokenGive, _amountGive,
      _expires, _nonce, _user, _v, _r, _s, _amount);
    
    // Check how much did we get and how much should we send back
    totalValue = TokenStore(_store).balanceOf(_tokenGive, this);
    uint customerValue = safeMul(_amountGive, _amount) / _amountGet;
    
    // Now withdraw all the funds into this contract and then pass to the user
    if (_tokenGive == address(0)) {
      TokenStore(_store).withdraw(totalValue);
      msg.sender.transfer(customerValue);
    } else {
      TokenStore(_store).withdrawToken(_tokenGive, totalValue);
      if (!Token(_tokenGive).transfer(msg.sender, customerValue)) {
        revert();
      }
    }
  }
  
  function withdrawFees(address _token) onlyOwner {
    if (_token == address(0)) {
      msg.sender.transfer(this.balance);
    } else {
      uint amount = Token(_token).balanceOf(this);
      if (!Token(_token).transfer(msg.sender, amount)) {
        revert();
      }
    }
  }  
}