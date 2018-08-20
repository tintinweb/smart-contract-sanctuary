pragma solidity ^0.4.23;

/******************************************************************
 * AXNET Decentralized Exchange Smart Contract * 
 * ***************************************************************/

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint);
    function allowance(address _owner, address _spender) public constant returns (uint);
    
    function transfer(address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public name;
    string public symbol;
    uint8 public decimals;  // 18 is the most common number of decimal places
}


contract AXNETDEX is SafeMath, Owned {
  address public feeAccount; //the account that will receive fees

  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)

  mapping (address => bool) public admins;  //admins who is responsible for trading
  
  //mapping of order hash to mapping of uints (amount of order that has been filled)
  mapping (bytes32 => uint256) public orderFills;
  
  //to make sure withdraw and trade will be done only once
  mapping (bytes32 => bool) public withdrawn;
  mapping (bytes32 => bool) public traded;
  
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

 constructor() public {
    feeAccount = msg.sender;
  }

  function() public {
    revert();
  }
  
  function setAdmin(address admin, bool isAdmin) public onlyOwner {
    admins[admin] = isAdmin;
  }
  
  modifier onlyAdmin {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }

  function changeFeeAccount(address feeAccount_) public onlyOwner {
    feeAccount = feeAccount_;
  }

  function deposit() payable public {
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) public {
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    require(token!=0);
    assert(Token(token).transferFrom(msg.sender, this, amount));
    
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function adminWithdraw(address token, uint amount, address user, uint nonce, uint8 v, bytes32 r, bytes32 s, uint feeWithdrawal) public onlyAdmin {
    bytes32 hash = sha256(this, token, amount, user, nonce);
    require(!withdrawn[hash]);
    withdrawn[hash] = true;
    
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
    
    if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;

    require(tokens[token][user] >= amount);
    tokens[token][user] = safeSub(tokens[token][user], amount);
    tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
    amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;

    if (token == address(0)) {
      assert(user.send(amount));
    } else {
      assert(Token(token).transfer(user, amount));
    }
    
    emit Withdraw(token, user, amount, tokens[token][user]);
  }

  function balanceOf(address token, address user)  public view returns (uint) {
    return tokens[token][user];
  }
  
    /* uint values
         0:amountGet, 1:amountGive, 2:expires, 3:nonce, 4:amount, 5:tradeNonce, 6:feeMake, 7:feeTake
       addressses
         0:tokenGet, 1:tokenGive, 2:maker, 3:taker
     signature binary
       v[0] rs[0] rs[1] : signature for order
       v[1] rs[2] rs[3] : signature for trade
     */
  function trade(uint[8] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) public onlyAdmin {
    bytes32 orderHash = sha256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeValues[3], tradeAddresses[2]);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == tradeAddresses[2]);
    bytes32 tradeHash = sha256(orderHash, tradeValues[4], tradeAddresses[3], tradeValues[5]);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) == tradeAddresses[3]);
    
    require(!traded[tradeHash]);
    traded[tradeHash] = true;
    
    require(safeAdd(orderFills[orderHash], tradeValues[4]) <= tradeValues[0]);
    require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
    require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= (safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]));
    
    tokens[tradeAddresses[0]][tradeAddresses[3]] = safeSub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
    tokens[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(tokens[tradeAddresses[0]][tradeAddresses[2]], safeMul(tradeValues[4], ((1 ether) - tradeValues[6])) / (1 ether));
    tokens[tradeAddresses[0]][feeAccount] = safeAdd(tokens[tradeAddresses[0]][feeAccount], safeMul(tradeValues[4], tradeValues[6]) / (1 ether));
    tokens[tradeAddresses[1]][tradeAddresses[2]] = safeSub(tokens[tradeAddresses[1]][tradeAddresses[2]], safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
    tokens[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(tokens[tradeAddresses[1]][tradeAddresses[3]], safeMul(safeMul(((1 ether) - tradeValues[7]), tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
    tokens[tradeAddresses[1]][feeAccount] = safeAdd(tokens[tradeAddresses[1]][feeAccount], safeMul(safeMul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
    orderFills[orderHash] = safeAdd(orderFills[orderHash], tradeValues[4]);
  }


  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s, address user) public onlyAdmin {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, user);
    assert(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user);
    orderFills[hash] = amountGet;
    emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s);
  }
}