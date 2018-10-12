pragma solidity ^0.4.9;

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

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}


contract Token {
  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
}


contract Excalibur is SafeMath {

  address public admin;
  bool public tradeState;
  string public message;

  mapping (address => mapping (address => uint)) public tokens; // mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; // mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint)) public orderFills; // mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)


  event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, bytes32 hash);
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, bytes32 hash, string pair);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, bytes32 hash, string pair);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);


  function Excalibur() {
      admin = msg.sender;
      tradeState = true;
  }

  modifier onlyAdmin {
        if (msg.sender != admin) throw;
        _;
  }

  modifier tradeIsOpen {
        if (!tradeState) throw;
        _;
  }

  function checkAdmin() onlyAdmin constant returns (bool) {
    return true;
  }

  function transferOwnership(address newAdmin) onlyAdmin {
    admin = newAdmin;
  }

  function systemMessage(string msg) onlyAdmin {
    message = msg;
  }

  function changeTradeState(bool state_) onlyAdmin {
    tradeState = state_;
  }

  function deposit() payable tradeIsOpen {
    // 0x0000000000000000000000000000000000000000
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint amount) {
    if (tokens[0][msg.sender] < amount) throw;
    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
    if (!msg.sender.call.value(amount)()) throw;
    Withdraw(0x0000000000000000000000000000000000000000, msg.sender, amount, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) tradeIsOpen {
    // remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    if (token==0) throw;
    if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawToken(address token, uint amount) {
    if (token==0) throw;
    if (tokens[token][msg.sender] < amount) throw;
    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
    if (!Token(token).transfer(msg.sender, amount)) throw;
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) constant returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
    bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    orders[msg.sender][hash] = true;
    Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, hash);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, string pair) {
    // amount is in amountGet terms
    bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!( (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) && block.number <= expires && safeAdd(orderFills[user][hash], amount) <= amountGet)) throw;
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
    Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender, hash, pair);
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
    tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], amount);
    tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], amount);
    tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
    tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s, string pair) {
    bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == msg.sender)) throw;
    orderFills[msg.sender][hash] = amountGet;
    Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s, hash, pair);
  }
}