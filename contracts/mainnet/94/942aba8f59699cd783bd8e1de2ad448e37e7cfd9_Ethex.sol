pragma solidity ^0.4.11;

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
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Ethex is SafeMath {
  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees
  uint public sellFee; //percentage times (1 ether)
  uint public buyFee; //percentage times (1 ether)
  mapping (bytes32 => uint) public sellOrders; //a hash of available orders holds a number of tokens
  mapping (bytes32 => uint) public buyOrders; //a hash of available orders. holds a number of eth

  event BuyOrder(bytes32 order, address token, uint amount, uint price, address buyer);
  event SellOrder(bytes32 order,address token, uint amount, uint price, address seller);
  event CancelBuyOrder(bytes32 order, address token, uint price, address buyer);
  event CancelSellOrder(bytes32 order, address token, uint price, address seller);
  event Buy(bytes32 order, address token, uint amount, uint price, address buyer, address seller);
  event Sell(bytes32 order, address token, uint amount, uint price, address buyer, address seller);

  function Ethex(address admin_, address feeAccount_, uint buyFee_, uint sellFee_) {
    admin = admin_;
    feeAccount = feeAccount_;
    buyFee = buyFee_;
    sellFee = sellFee_;
  }

  function() {
    throw;
  }

  function changeAdmin(address admin_) {
    if (msg.sender != admin) throw;
    admin = admin_;
  }

  function changeFeeAccount(address feeAccount_) {
    if (msg.sender != admin) throw;
    feeAccount = feeAccount_;
  }

  function changeBuyFee(uint buyFee_) {
    if (msg.sender != admin) throw;
    if (buyFee_ > buyFee) throw;
    buyFee = buyFee_;
  }

  function changeSellFee(uint sellFee_) {
    if (msg.sender != admin) throw;
    if (sellFee_ > sellFee)
    sellFee = sellFee_;
  }

  function sellOrder(address token, uint tokenAmount, uint price) {
    bytes32 h = sha256(token, price, msg.sender);
    sellOrders[h] = safeAdd(sellOrders[h],tokenAmount);
    SellOrder(h, token, tokenAmount, price, msg.sender);
  }

  function buyOrder(address token, uint tokenAmount, uint price) payable {
    bytes32 h = sha256(token, price,  msg.sender);
    uint totalCost = tokenAmount*price;
    if (totalCost < msg.value) throw;
    buyOrders[h] = safeAdd(buyOrders[h],msg.value);
    BuyOrder(h, token, tokenAmount, price, msg.sender);
  }

  function cancelSellOrder(address token, uint price) {
    bytes32 h = sha256(token, price, msg.sender);
    delete sellOrders[h];
    CancelSellOrder(h,token,price,msg.sender);
  }

  function cancelBuyOrder(address token, uint price) {
    bytes32 h = sha256(token, price, msg.sender);
    uint remain = buyOrders[h];
    delete buyOrders[h];
    if (!msg.sender.call.value(remain)()) throw;
    CancelBuyOrder(h,token,price,msg.sender);
  }

  function totalBuyPrice(uint amount, uint price)  public constant returns (uint) {
    uint totalPriceNoFee = safeMul(amount, price);
    uint totalFee = safeMul(totalPriceNoFee, buyFee) / (1 ether);
    uint totalPrice = safeAdd(totalPriceNoFee,totalFee);
    return totalPrice;
  }

  function takeBuy(address token, uint amount, uint price, address buyer) payable {
    bytes32 h = sha256(token, price, buyer);
    uint totalPriceNoFee = safeMul(amount, price);
    uint totalFee = safeMul(totalPriceNoFee, buyFee) / (1 ether);
    uint totalPrice = safeAdd(totalPriceNoFee,totalFee);
    if (buyOrders[h] < amount) throw;
    if (totalPrice > msg.value) throw;
    if (Token(token).allowance(msg.sender,this) < amount) throw;
    if (Token(token).transferFrom(msg.sender,buyer,amount)) throw;
    buyOrders[h] = safeSub(buyOrders[h], amount);
    if (!feeAccount.send(totalFee)) throw;
    uint leftOver = msg.value - totalPrice;
    if (leftOver>0)
      if (!msg.sender.send(leftOver)) throw;
    Buy(h, token, amount, totalPrice, buyer, msg.sender);
  }

  function totalSellPrice(uint amount, uint price)  public constant returns (uint) {
    uint totalPriceNoFee = safeMul(amount, price);
    uint totalFee = safeMul(totalPriceNoFee, buyFee) / (1 ether);
    uint totalPrice = safeSub(totalPriceNoFee,totalFee);
    return totalPrice;
  }

  function takeSell(address token, uint amount,uint price, address seller) payable {
    bytes32 h = sha256(token, price, seller);
    uint totalPriceNoFee = safeMul(amount, price);
    uint totalFee = safeMul(totalPriceNoFee, buyFee) / (1 ether);
    uint totalPrice = safeSub(totalPriceNoFee,totalFee);
    if (sellOrders[h] < amount) throw;
    if (Token(token).allowance(seller,this) < amount) throw;
    if (!Token(token).transferFrom(seller,msg.sender,amount)) throw;
    sellOrders[h] = safeSub(sellOrders[h],amount);
    if (!seller.send(totalPrice)) throw;
    if (!feeAccount.send(totalFee)) throw;
    Sell(h, token, amount, totalPrice, msg.sender, seller);
  }
}