pragma solidity ^0.4.16;

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

 
contract Exchange {

  address public owner;
  mapping (address => uint256) public invalidOrder;


  mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances

  mapping (address => bool) public admins;
  mapping (address => uint256) public lastActiveTransaction;
  mapping (bytes32 => uint256) public orderFills;
  address public feeAccount;
  uint256 public inactivityReleasePeriod;
  mapping (bytes32 => bool) public traded;
  mapping (bytes32 => bool) public withdrawn;
  event Order(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Cancel(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

  function setInactivityReleasePeriod(uint256 expiry)  returns (bool success) {
    if (expiry > 1000000) throw;
    inactivityReleasePeriod = expiry;
    return true;
  }



  function Exchange(address feeAccount_) {
    owner = msg.sender;
    feeAccount = feeAccount_;
    inactivityReleasePeriod = 100000;
  }


  function assert(bool assertion) {
    if (!assertion) throw;
  }
  function safeMul(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }


  function depositToken(address token, uint256 amount) {
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    lastActiveTransaction[msg.sender] = block.number;
    if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }



  function deposit() payable {
    tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
    lastActiveTransaction[msg.sender] = block.number;
    Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }



}