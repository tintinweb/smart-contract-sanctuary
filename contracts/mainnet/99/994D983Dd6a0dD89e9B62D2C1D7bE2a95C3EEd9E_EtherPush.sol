pragma solidity ^0.4.16;

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

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 supply) {
    return 0;
  }

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {
    _owner = _owner;
    return 0;
  }

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {
    _to = _to;
    _value = _value;
    return false;
  }

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    _from = _from;
    _to = _to;
    _value = _value;
    return false;
  }

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {
    _spender = _spender;
    _value = _value;
    return false;
  }

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    _owner = _owner;
    _spender = _spender;
    return 0;
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) returns (bool success) {
    //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
    //Replace the if with this one instead.
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    //same as above. Replace this line with the following if you want to protect against wrapping uints.
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}

contract EtherPush is SafeMath {
  struct Order {
    uint    id;
    address sell;
    uint    sellamount;
    address buy;
    uint    buyamount;
    address seller;
    address buyer;
    uint    created;
    uint    expired;
    uint    timestamp;
  }

  mapping (address => mapping (address => uint))            public tokens;
  mapping (uint => mapping (address => Order))              public orders;

  string  public constant  name = "EtherPush";
  string  public constant  version = "20170913";

  bool    public           running = true;

  uint    public           sellerfee = 0.005 ether;
  uint    public constant    sellerfeeDivide = 1 ether;

  uint    public           buyerfee = 0.005 ether;
  uint    public constant    buyerfeeDivide = 1 ether;

  uint    private          _id = 0;
  uint    private          _nonce = 0;
  address  private          owner;

  event onSell(bytes32 nonce, uint id, address sell, uint sellamount, address buy, uint buyamount, address seller, address buyer, uint created, uint expired, uint timestamp);
  event onBuy(bytes32 nonce, uint id, address sell, uint sellamount, uint balanceSellamount,
              address buy, uint buyamount, uint balanceBuyamount, address seller, address buyer,
              uint created, uint timestamp);
  event onCancel(bytes32 nonce, uint id, address seller);
  event onDeposit(address token, address user, uint amount, uint balance);
  event onWithdraw(address token, address user, uint amount, uint balance);

  modifier onlyRunning() {
    require(running);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function EtherPush() {
    owner = msg.sender;
  }

  function ownerChangeRunning(bool _running)
    public
    onlyOwner
  {
    running = _running;
  }

  function ownerChangeSellerfee(uint _fee)
    public
    onlyOwner
  {
    /*
     * between [0.1%, 2%]
     */
    require (_fee >= 0.001 ether && _fee <= 0.02 ether);

    sellerfee = _fee;
  }

  function ownerChangeBuyerfee(uint _fee)
    public
    onlyOwner
  {
    /*
     * between [0.1%, 2%]
     */
    require (_fee >= 0.001 ether && _fee <= 0.02 ether);
    buyerfee = _fee;
  }

  function ownerChangeOwner(address _owner)
    public
    onlyOwner
  {
    require (_owner > 0);
    owner = _owner;
  }

  function ownerWithdrawAccount(address account)
    public
    onlyOwner
  {
    account.transfer(this.balance);
  }

  function ownerWithdraw()
    public
    onlyOwner
  {
    owner.transfer(this.balance);
  }

  function getRunning() public constant returns (bool) {
    return running;
  }

  function getSellerfee() public constant returns (uint) {
    return sellerfee;
  }

  function getBuyerfee() public constant returns (uint) {
    return buyerfee;
  }

  function withdrawAmountETH(uint amount) {
    if (tokens[0][msg.sender] < amount) {
      revert();
    }

    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);

    msg.sender.transfer(amount);

    onWithdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function withdrawETH() {
    uint amount = tokens[0][msg.sender];
    tokens[0][msg.sender] = 0;

    msg.sender.transfer(amount);

    onWithdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function withdrawToken(address token) {
    if (token == address(0)) {
      revert();
    }

    uint amount = tokens[token][msg.sender];
    tokens[token][msg.sender] = 0;

    if (!Token(token).transfer(msg.sender, amount)) {
      revert();
    }

    onWithdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawAmountToken(address token, uint amount) {
    if (token == address(0)) {
      revert();
    }

    if (tokens[token][msg.sender] < amount) {
      revert();
    }

    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);

    if (!Token(token).transfer(msg.sender, amount)) {
      revert();
    }

    onWithdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function depositETH()
    public
    payable
  {
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    onDeposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount)
    public
  {
    if (token == address(0)) {
      revert();
    }

    if (!Token(token).transferFrom(msg.sender, this, amount)) {
      revert();
    }

    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    onDeposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user)
    public
    constant
    returns
    (uint)
  {
    return tokens[token][user];
  }

  function tobuy(uint id, address seller, uint buyamount)
    public
    onlyRunning
  {
    if (orders[id][seller].expired < block.number) {
      revert();
    }

    if (orders[id][seller].buyer > 0) {
      if (orders[id][seller].buyer != msg.sender) {
        revert();
      }
    }

    if (orders[id][seller].buyamount < buyamount) {
      revert();
    }

    address sell = orders[id][seller].sell;
    address buy = orders[id][seller].buy;
    uint    ordersellamount = orders[id][seller].sellamount;
    uint    orderbuyamount = orders[id][seller].buyamount;
    uint    sellamount = safeMul(ordersellamount, buyamount) / orderbuyamount;
    buyamount = safeMul(sellamount, orderbuyamount) / ordersellamount;

    if (ordersellamount < sellamount) {
      revert();
    }

    if (tokens[sell][seller] < sellamount) {
      revert();
    }

    if (tokens[buy][msg.sender] < buyamount) {
      revert();
    }

    uint _sellerfee = safeMul(sellamount, sellerfee) / sellerfeeDivide;
    uint _buyerfee = safeMul(buyamount, buyerfee) / buyerfeeDivide;

    /*
     * order
     */

    orders[id][seller].sellamount = safeSub(orders[id][seller].sellamount, sellamount);
    orders[id][seller].buyamount = safeSub(orders[id][seller].buyamount, buyamount);

    /*
     * balance sell token
     */

    tokens[sell][seller] = safeSub(tokens[sell][seller], sellamount);
    tokens[sell][owner] = safeAdd(tokens[sell][owner], _sellerfee);
    tokens[sell][msg.sender] = safeAdd(tokens[sell][msg.sender], safeSub(sellamount, _sellerfee));

    /*
     * balance buy token
     */

    tokens[buy][msg.sender] = safeSub(tokens[buy][msg.sender], buyamount);
    tokens[buy][owner] = safeAdd(tokens[buy][owner], _buyerfee);
    tokens[buy][seller] = safeAdd(tokens[buy][seller], safeSub(buyamount, _buyerfee));

    /*
     * call to buy function to clear stack
     */

    _tobuy(id, seller, sellamount, buyamount);
  }

  function _tobuy(uint id, address seller, uint sellamount, uint buyamount)
    private
  {
    bytes32 nonce = sha3(block.number, msg.data, _nonce++);
    onBuy(
         nonce,
         id,
         orders[id][seller].sell,
         sellamount,
         orders[id][seller].sellamount,
         orders[id][seller].buy,
         buyamount,
         orders[id][seller].buyamount,
         seller,
         msg.sender,
         block.number,
         now
         );
  }

  function tosell(address sell, uint sellamount, address buy, uint buyamount,
               address buyer, uint expire, uint broadcast)
    public
    onlyRunning
  {

    if (tokens[sell][msg.sender] < sellamount) {
      revert();
    }

    /*
     * if buyer > 0, the order only can be purchased by the specified buyer.
     * and here we do not check the token balance to imporve the poor performance
     */

    _id = _id + 1;
    orders[_id][msg.sender].id = _id;
    orders[_id][msg.sender].sell = sell;
    orders[_id][msg.sender].sellamount = sellamount;
    orders[_id][msg.sender].buy = buy;
    orders[_id][msg.sender].buyamount = buyamount;
    orders[_id][msg.sender].seller = msg.sender;
    orders[_id][msg.sender].buyer = buyer;
    orders[_id][msg.sender].created = block.number;
    orders[_id][msg.sender].expired = safeAdd(block.number, expire);

    bytes32 nonce = sha3(block.number, msg.data, _nonce++);

    onSell(nonce, _id, sell, sellamount, buy, buyamount, msg.sender, buyer, block.number, orders[_id][msg.sender].expired, now);
  }

  function tocancel(uint id)
    public
  {
    orders[id][msg.sender].sellamount = 0;

    bytes32 nonce = sha3(block.number, msg.data, _nonce++);

    onCancel(nonce, id, msg.sender);
  }

  function getOrder(uint id, address seller)
    public
    constant
    returns
    (address, uint, address, uint, address, uint)
  {
    return (orders[id][seller].sell,
      orders[id][seller].sellamount,
      orders[id][seller].buy,
      orders[id][seller].buyamount,
      orders[id][seller].buyer,
      orders[id][seller].expired
    );
  }
}