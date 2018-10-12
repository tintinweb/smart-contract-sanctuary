pragma solidity ^0.4.25;

contract IMDEX {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function transfer(address _to, uint256 _value)public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}


contract IMDEXchange is SafeMath {

  address public owner;
  mapping (address => uint256) public invalidOrder;
  event SetOwner(address indexed previousOwner, address indexed newOwner);
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function IMDEXsetOwner(address newOwner)public onlyOwner {
    emit SetOwner(owner, newOwner);
    owner = newOwner;
  }

  function IMDEXinvalidateOrdersBefore(address user, uint256 nonce) public onlyAdmin {
    require(nonce > invalidOrder[user]);
    invalidOrder[user] = nonce;
  }

  mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances
  mapping (address => bool) public admins;
  mapping (address => uint256) public lastActiveTransaction;
  address public feeAccount;
  uint256 public inactivityReleasePeriod;
  event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

  function IMDEXsetInactivityReleasePeriod(uint256 expiry) public onlyAdmin returns (bool success) {
    require(expiry < 1000000);
    inactivityReleasePeriod = expiry;
    return true;
  }

  constructor(address feeAccount_) public {
    owner = msg.sender;
    feeAccount = feeAccount_;
    inactivityReleasePeriod = 100000;
  }

  function IMDEXsetAdmin(address admin, bool isAdmin) public onlyOwner {
    admins[admin] = isAdmin;
  }

  modifier onlyAdmin {
   require(msg.sender == owner && admins[msg.sender]);
    _;
  }

  function() external {
    revert();
  }



  function IMDEXdepositToken(address token, uint256 amount) public {
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    lastActiveTransaction[msg.sender] = block.number;
    require(IMDEX(token).transferFrom(msg.sender, this, amount));
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function IMDEXdeposit() public payable {
    tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
    lastActiveTransaction[msg.sender] = block.number;
    emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }

function IMDEXwithdrawToken(address token, uint256 amount) public returns (bool) {
    require(safeSub(block.number, lastActiveTransaction[msg.sender]) > inactivityReleasePeriod);
    require(tokens[token][msg.sender] > amount);
    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      require(IMDEX(token).transfer(msg.sender, amount));
    }
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function IMDEXadminWithdraw(address token, uint256 amount, address user, uint256 feeWithdrawal) public onlyAdmin returns (bool) {
    if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;
    require(tokens[token][user] > amount);
    tokens[token][user] = safeSub(tokens[token][user], amount);
    tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
    amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
    if (token == address(0)) {
      user.transfer(amount);
    } else {
      require(IMDEX(token).transfer(user, amount));
    }
    lastActiveTransaction[user] = block.number;
    emit Withdraw(token, user, amount, tokens[token][user]);
  }

  function balanceOf(address token, address user) public constant returns (uint256) {
    return tokens[token][user];
  }

  function IMDEXtrade(uint256[8] X, address[4] Y) public onlyAdmin returns (bool) {
    /* amount is in amountBuy terms */
    /* X
       [0] amountBuy
       [1] amountSell
       [2] expires
       [3] nonce
       [4] amount
       [5] tradeNonce
       [6] feeMake
       [7] feeTake
     Y
       [0] tokenBuy
       [1] tokenSell
       [2] maker
       [3] taker
     */
    require(invalidOrder[Y[2]] < X[3]);
    if (X[6] > 100 finney) X[6] = 100 finney;
    if (X[7] > 100 finney) X[7] = 100 finney;
    require(tokens[Y[0]][Y[3]] > X[4]);
    require(tokens[Y[1]][Y[2]] > (safeMul(X[1], X[4]) / X[0]));
    tokens[Y[0]][Y[3]] = safeSub(tokens[Y[0]][Y[3]], X[4]);
    tokens[Y[0]][Y[2]] = safeAdd(tokens[Y[0]][Y[2]], safeMul(X[4], ((1 ether) - X[6])) / (1 ether));
    tokens[Y[0]][feeAccount] = safeAdd(tokens[Y[0]][feeAccount], safeMul(X[4], X[6]) / (1 ether));
    tokens[Y[1]][Y[2]] = safeSub(tokens[Y[1]][Y[2]], safeMul(X[1], X[4]) / X[0]);
    tokens[Y[1]][Y[3]] = safeAdd(tokens[Y[1]][Y[3]], safeMul(safeMul(((1 ether) - X[7]), X[1]), X[4]) / X[0] / (1 ether));
    tokens[Y[1]][feeAccount] = safeAdd(tokens[Y[1]][feeAccount], safeMul(safeMul(X[7], X[1]), X[4]) / X[0] / (1 ether));
    lastActiveTransaction[Y[2]] = block.number;
    lastActiveTransaction[Y[3]] = block.number;
  }
}