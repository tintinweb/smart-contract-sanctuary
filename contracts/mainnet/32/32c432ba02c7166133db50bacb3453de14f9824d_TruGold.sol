pragma solidity ^0.4.24;



contract MultiOwnable {
  // FIELDS ========================

  bool public isLocked;

  address public owner1;
  address public owner2;

  // the ongoing operations.
  mapping(bytes32 => PendingState) public m_pending;

  // TYPES

  // struct for the status of a pending operation.
  struct PendingState {
    bool confirmation1;
    bool confirmation2;
    uint exists; // used to know if array exists, solidity is strange
  }

  // EVENTS

  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);
  event ConfirmationNeeded(bytes32 operation, address from, uint value, address to);

  modifier onlyOwner {
    require(isOwner(msg.sender));
    _;
  }

  modifier onlyManyOwners(bytes32 _operation) {
    if (confirmAndCheck(_operation))
      _;
  }

  modifier onlyIfUnlocked {
    require(!isLocked);
    _;
  }


  // constructor is given number of sigs required to do protected "onlyManyOwners" transactions
  // as well as the selection of addresses capable of confirming them.
  constructor(address _owner1, address _owner2) public {
    require(_owner1 != address(0));
    require(_owner2 != address(0));

    owner1 = _owner1;
    owner2 = _owner2;
    isLocked = true;
  }

  function unlock() public onlyOwner {
    isLocked = false;
  }

  // Revokes a prior confirmation of the given operation
  function revoke(bytes32 _operation) external onlyOwner {
    emit Revoke(msg.sender, _operation);
    delete m_pending[_operation];
  }

  function isOwner(address _addr) public view returns (bool) {
    return _addr == owner1 || _addr == owner2;
  }

  function hasConfirmed(bytes32 _operation, address _owner)
    constant public onlyOwner
    returns (bool) {

    if (_owner == owner1) {
      return m_pending[_operation].confirmation1;
    }

    if (_owner == owner2) {
      return m_pending[_operation].confirmation2;
    }
  }

  // INTERNAL METHODS

  function confirmAndCheck(bytes32 _operation)
    internal onlyOwner
    returns (bool) {

    // Confirmation doesn&#39;t exists so create it
    if (m_pending[_operation].exists == 0) {
      if (msg.sender == owner1) { m_pending[_operation].confirmation1 = true; }
      if (msg.sender == owner2) { m_pending[_operation].confirmation2 = true; }
      m_pending[_operation].exists = 1;

      // early exit
      return false;
    }

    // already confirmed
    if (msg.sender == owner1 && m_pending[_operation].confirmation1 == true) {
      return false;
    }

    // already confirmed
    if (msg.sender == owner2 && m_pending[_operation].confirmation2 == true) {
      return false;
    }

    if (msg.sender == owner1) {
      m_pending[_operation].confirmation1 = true;
    }

    if (msg.sender == owner2) {
      m_pending[_operation].confirmation2 = true;
    }

    // final verification
    return m_pending[_operation].confirmation1 && m_pending[_operation].confirmation2;
  }
}



// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------

/* contract Goldchain is ERC20Interface, Owned { */
contract TruGold is ERC20Interface, MultiOwnable {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping (bytes32 => Transaction) public pendingTransactions; // pending transactions we have at present.

  struct Transaction {
    address from;
    address to;
    uint value;
  }


  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor(address target, address _owner1, address _owner2)
    MultiOwnable(_owner1, _owner2) public {
    symbol = "TruGold";
    name = "TruGold";
    decimals = 18;
    _totalSupply = 300000000 * 10**uint(decimals);
    balances[target] = _totalSupply;

    emit Transfer(address(0), target, _totalSupply);
  }

  // ------------------------------------------------------------------------
  // Total supply
  // ------------------------------------------------------------------------
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }

  // ------------------------------------------------------------------------
  // Get the token balance for account `tokenOwner`
  // ------------------------------------------------------------------------
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }

  // ------------------------------------------------------------------------
  // Transfer the balance from token owner&#39;s account to `to` account
  // - Owner&#39;s account must have sufficient balance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
  /* function transfer(address to, uint tokens) public onlyOwnerIfLocked returns (bool success) { */
  function transfer(address to, uint tokens)
    public
    onlyIfUnlocked
    returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function ownerTransfer(address from, address to, uint value)
    public onlyOwner
    returns (bytes32 operation) {

    operation = keccak256(abi.encodePacked(msg.data, block.number));

    if (!approveOwnerTransfer(operation) && pendingTransactions[operation].to == 0) {
      pendingTransactions[operation].from = from;
      pendingTransactions[operation].to = to;
      pendingTransactions[operation].value = value;

      emit ConfirmationNeeded(operation, from, value, to);
    }

    return operation;
  }

  function approveOwnerTransfer(bytes32 operation)
    public
    onlyManyOwners(operation)
    returns (bool success) {

    // find transaction in storage
    Transaction storage transaction = pendingTransactions[operation];

    // update balances accordingly
    balances[transaction.from] = balances[transaction.from].sub(transaction.value);
    balances[transaction.to] = balances[transaction.to].add(transaction.value);

    // delete current transaction
    delete pendingTransactions[operation];

    emit Transfer(transaction.from, transaction.to, transaction.value);

    return true;
  }

  // ------------------------------------------------------------------------
  // Token owner can approve for `spender` to transferFrom(...) `tokens`
  // from the token owner&#39;s account
  //
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
  // recommends that there are no checks for the approval double-spend attack
  // as this should be implemented in user interfaces
  // ------------------------------------------------------------------------
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  // ------------------------------------------------------------------------
  // Transfer `tokens` from the `from` account to the `to` account
  //
  // The calling account must already have sufficient tokens approve(...)-d
  // for spending from the `from` account and
  // - From account must have sufficient balance to transfer
  // - Spender must have sufficient allowance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
  function transferFrom(address from, address to, uint tokens) public onlyIfUnlocked returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    emit Transfer(from, to, tokens);

    return true;
  }

  // ------------------------------------------------------------------------
  // Returns the amount of tokens approved by the owner that can be
  // transferred to the spender&#39;s account
  // ------------------------------------------------------------------------
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }


  // ------------------------------------------------------------------------
  // Token owner can approve for `spender` to transferFrom(...) `tokens`
  // from the token owner&#39;s account. The `spender` contract function
  // `receiveApproval(...)` is then executed
  // ------------------------------------------------------------------------
  function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);

    return true;
  }


  // ------------------------------------------------------------------------
  // Don&#39;t accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner1, tokens);
  }
}